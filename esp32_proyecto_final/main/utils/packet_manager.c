#include "packet_manager.h"
#include "network/bluetooth.h"   // tu bluetooth.c / bluetooth.h con send_notification_binary(...)
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include <string.h>

static const char *TAG = "PACKET_MGR";

/* Queues & task */
#define PM_PULSE_Q_LEN 64
#define PM_IMU_COMPACT_Q_LEN 32
#define PM_TASK_STACK 4096
#define PM_TASK_PRIO 5

typedef struct {
  uint16_t value;
  uint32_t ts32;
} pm_pulse_item_t;

typedef struct {
  int16_t ax;
  int16_t ay;
  int16_t az;
  int16_t gx;
  int16_t gy;
  int16_t gz;
  uint64_t ts;
} pm_imu_compact_t;

static QueueHandle_t s_pulse_q = NULL;
static QueueHandle_t s_imu_compact_q = NULL;
static TaskHandle_t s_task = NULL;

/* Helper: build compact packet into out buffer */
int packet_manager_build_compact(uint8_t *out, uint8_t max_len,
                                 uint8_t flags, uint64_t timestamp,
                                 const int16_t *imu_flat, uint8_t imu_count,
                                 const uint16_t *pulses, uint8_t pulse_count)
{
  int needed = 1 + 8 + 1 + 1; // flags + timestamp(8) + countImu + countPulse
  needed += imu_count * 12;   // 6 * int16
  needed += pulse_count * 2;  // 2 bytes per pulse

  if (needed > max_len) {
    ESP_LOGE(TAG, "Packet too large: need %d / buffer %d", needed, max_len);
    return -1;
  }

  int offset = 0;

  out[offset++] = flags;

  /* timestamp little-endian (uint64) */
  memcpy(out + offset, &timestamp, 8);
  offset += 8;

  out[offset++] = imu_count;
  out[offset++] = pulse_count;

  /* IMU flattened array: [ax0,ay0,az0,gx0,gy0,gz0, ax1,...] as int16 */
  if (imu_flat != NULL && imu_count > 0) {
    /* each sample 6 * int16 = 12 bytes */
    const int16_t *p = imu_flat;
    for (int i = 0; i < imu_count; i++) {
      /* copy 6 int16 (little-endian memory copy is fine) */
      memcpy(out + offset, p, 12);
      offset += 12;
      p += 6;
    }
  }

  /* pulses */
  if (pulses != NULL && pulse_count > 0) {
    for (int i = 0; i < pulse_count; i++) {
      uint16_t v = pulses[i];
      memcpy(out + offset, &v, 2);
      offset += 2;
    }
  }

  return offset;
}

/* Send via bluetooth using your NimBLE helper */
void packet_manager_send_compact(uint8_t flags, uint64_t timestamp,
                                 const int16_t *imu_flat, uint8_t imu_count,
                                 const uint16_t *pulses, uint8_t pulse_count)
{
  uint8_t buffer[128];
  int len = packet_manager_build_compact(buffer, sizeof(buffer),
                                         flags, timestamp,
                                         imu_flat, imu_count,
                                         pulses, pulse_count);
  if (len < 0) {
    ESP_LOGE(TAG, "Failed to build packet");
    return;
  }

  /* send with your bluetooth wrapper (nimble) */
  send_notification_binary(buffer, (uint16_t)len);
  ESP_LOGD(TAG, "packet_manager_send_compact: sent %d bytes (flags=0x%02x imu=%u pulse=%u)",
           len, flags, imu_count, pulse_count);
}

/* ============================
   Task that consumes queues and sends packets
   ============================ */

static inline uint64_t now_ms64(void) {
  return (uint64_t)(esp_timer_get_time() / 1000ULL);
}

static void pm_task(void *arg) {
  (void)arg;
  ESP_LOGI(TAG, "pm_task started");

  for (;;) {
    pm_imu_compact_t imu_item;
    pm_pulse_item_t pulse_item;

    BaseType_t has_imu = xQueueReceive(s_imu_compact_q, &imu_item, pdMS_TO_TICKS(50));
    BaseType_t has_pulse = xQueueReceive(s_pulse_q, &pulse_item, 0);

    if (has_imu == pdFALSE) {
      has_pulse = xQueueReceive(s_pulse_q, &pulse_item, pdMS_TO_TICKS(50));
    }

    if (has_imu == pdFALSE && has_pulse == pdFALSE) {
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }

    /* Build payload: prefer to send both if available */
    int16_t imu_flat[6];
    uint16_t pulses[4]; // small stack buffer; typical pulse_count==1
    uint8_t imu_count = 0;
    uint8_t pulse_count = 0;
    uint64_t ts_use = now_ms64();

    if (has_imu && has_pulse) {
      imu_flat[0] = imu_item.ax;
      imu_flat[1] = imu_item.ay;
      imu_flat[2] = imu_item.az;
      imu_flat[3] = imu_item.gx;
      imu_flat[4] = imu_item.gy;
      imu_flat[5] = imu_item.gz;
      imu_count = 1;

      pulses[0] = pulse_item.value;
      pulse_count = 1;

      ts_use = imu_item.ts;
    } else if (has_imu) {
      imu_flat[0] = imu_item.ax;
      imu_flat[1] = imu_item.ay;
      imu_flat[2] = imu_item.az;
      imu_flat[3] = imu_item.gx;
      imu_flat[4] = imu_item.gy;
      imu_flat[5] = imu_item.gz;
      imu_count = 1;
      pulse_count = 0;
      ts_use = imu_item.ts;
    } else if (has_pulse) {
      pulse_count = 1;
      pulses[0] = pulse_item.value;
      imu_count = 0;
      ts_use = (uint64_t)pulse_item.ts32;
    }

    /* flags: keep as 0.. (caller policy) - let's set bits as before (1=pulse,2=imu,3=both) */
    uint8_t flags = 0;
    if (imu_count && pulse_count) flags = (0x3 << 6);
    else if (imu_count) flags = (0x2 << 6);
    else if (pulse_count) flags = (0x1 << 6);

    packet_manager_send_compact(flags, ts_use,
                                imu_count ? imu_flat : NULL, imu_count,
                                pulse_count ? pulses : NULL, pulse_count);

    vTaskDelay(pdMS_TO_TICKS(5));
  }
}

/* ============================
   Public API: init + feed functions
   ============================ */

esp_err_t pm_init(void) {
  if (s_pulse_q || s_imu_compact_q || s_task) return ESP_OK;

  s_pulse_q = xQueueCreate(PM_PULSE_Q_LEN, sizeof(pm_pulse_item_t));
  s_imu_compact_q = xQueueCreate(PM_IMU_COMPACT_Q_LEN, sizeof(pm_imu_compact_t));
  if (!s_pulse_q || !s_imu_compact_q) {
    ESP_LOGE(TAG, "Failed to create queues");
    return ESP_ERR_NO_MEM;
  }

  BaseType_t ok = xTaskCreate(pm_task, "pm_task", PM_TASK_STACK, NULL, PM_TASK_PRIO, &s_task);
  if (ok != pdPASS) {
    ESP_LOGE(TAG, "Failed to create pm task");
    return ESP_FAIL;
  }

  ESP_LOGI(TAG, "pm_init done");
  return ESP_OK;
}

int pm_feed_pulse(uint16_t value) {
  if (!s_pulse_q) return -1;
  pm_pulse_item_t it;
  it.value = value;
  it.ts32 = (uint32_t)now_ms64();
  if (xQueueSend(s_pulse_q, &it, 0) == pdTRUE) return 0;
  return -1;
}

void pm_feed_imu_compact_sink(const pm_imu_compact_t *it) {
  /* helper to enqueue if queue exists */
  if (!s_imu_compact_q) return;
  xQueueSend(s_imu_compact_q, it, 0);
}

int pm_feed_imu_compact(int16_t ax, int16_t ay, int16_t az,
                        int16_t gx, int16_t gy, int16_t gz,
                        uint64_t timestamp_ms)
{
  if (!s_imu_compact_q) return -1;
  pm_imu_compact_t it;
  it.ax = ax; it.ay = ay; it.az = az;
  it.gx = gx; it.gy = gy; it.gz = gz;
  it.ts = timestamp_ms;
  if (xQueueSend(s_imu_compact_q, &it, 0) == pdTRUE) return 0;
  return -1;
}

