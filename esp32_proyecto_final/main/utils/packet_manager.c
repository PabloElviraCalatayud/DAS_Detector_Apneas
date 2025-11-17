#include "packet_manager.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "esp_log.h"
#include "network/bluetooth.h"
#include "esp_timer.h"
#include <string.h>

static const char *TAG = "PM_NEW";

#define PM_PULSE_Q_LEN 64
#define PM_IMU_Q_LEN   16
#define PM_IMU_COMPACT_Q_LEN 32
#define PM_TASK_STACK  4096
#define PM_TASK_PRIO   5

typedef struct {
  uint16_t value;
  uint32_t ts32;
} pm_imu_item_t;

typedef struct {
  uint16_t value;
  uint32_t ts32;
} pm_pulse_item_t;

/* compact IMU sample (six int16 scaled x100) */
typedef struct {
  int16_t ax;
  int16_t ay;
  int16_t az;
  int16_t gx;
  int16_t gy;
  int16_t gz;
  uint64_t ts;
} imu_compact_t;

static QueueHandle_t s_pulse_q = NULL;
static QueueHandle_t s_imu_q = NULL;
static QueueHandle_t s_imu_compact_q = NULL;
static TaskHandle_t s_task = NULL;

static inline uint64_t now_ms64(void) {
  return (uint64_t)(esp_timer_get_time() / 1000ULL);
}

/* Construye y envía un paquete compacto via BLE
 * Format:
 *  byte0: flags
 *  bytes1..8: timestamp uint64 LE
 *  byte9: count_imu
 *  byte10: count_pulse
 *  payload: for each imu -> ax(int16 LE), ay, az, gx, gy, gz (12 bytes)
 *           for each pulse -> uint16 LE
 */
static void pm_send_packet_compact(uint8_t flags, uint64_t ts64, const uint8_t *payload, size_t payload_len) {
  uint8_t buf[256];
  size_t pos = 0;

  buf[pos++] = flags;

  /* timestamp 64 bits little-endian */
  buf[pos++] = (uint8_t)(ts64 & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 8) & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 16) & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 24) & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 32) & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 40) & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 48) & 0xFF);
  buf[pos++] = (uint8_t)((ts64 >> 56) & 0xFF);

  if (payload && payload_len) {
    memcpy(&buf[pos], payload, payload_len);
    pos += payload_len;
  }

  ESP_LOGD(TAG, "pm_send_packet_compact flags=0x%02x len=%u ts=%llu", flags, (unsigned)pos, (unsigned long long)ts64);
  send_notification_binary(buf, pos);
}

/* Tarea de empaquetado: consume colas y combina muestras compactas y pulso */
static void pm_task(void *arg) {
  (void)arg;
  ESP_LOGI(TAG, "pm_task started");

  for (;;) {
    imu_compact_t imu_sample;
    pm_pulse_item_t pulse_sample;

    BaseType_t has_imu = xQueueReceive(s_imu_compact_q, &imu_sample, pdMS_TO_TICKS(50));
    BaseType_t has_pulse = xQueueReceive(s_pulse_q, &pulse_sample, 0);

    if (has_imu == pdFALSE) {
      /* si no vino imu, intentar leer pulso con pequeño timeout */
      has_pulse = xQueueReceive(s_pulse_q, &pulse_sample, pdMS_TO_TICKS(50));
    }

    if (has_imu == pdFALSE && has_pulse == pdFALSE) {
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }

    /* Construir paquete compacto: preferimos enviar ambos si ambos disponibles */
    uint8_t payload[128];
    size_t pos = 0;
    uint8_t count_imu = 0;
    uint8_t count_pulse = 0;
    uint64_t ts_to_use = now_ms64();

    if (has_imu && has_pulse) {
      /* send both in same packet */
      count_imu = 1;
      count_pulse = 1;
      ts_to_use = imu_sample.ts; /* align to imu timestamp (or choose policy) */

      /* IMU compact (6 * int16) */
      memcpy(&payload[pos], &imu_sample.ax, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.ay, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.az, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.gx, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.gy, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.gz, 2); pos += 2;

      /* pulse */
      memcpy(&payload[pos], &pulse_sample.value, 2); pos += 2;

      /* header: flags: use 0x3 for both in top bits */
      uint8_t flags = (0x3 << 6);
      /* After flags we must include counts: we'll build header+ts+counts in pm_send_packet_compact by prepending payload.
         But to keep compatibility with the described layout we will prepend counts ourselves as first bytes of payload area:
         We'll send counts as first two bytes of payload (count_imu, count_pulse) so pm_send_packet_compact can remain general.
      */
      /* We'll create a small combined buffer: [count_imu][count_pulse][payload...] and pass it to pm_send_packet_compact */
      uint8_t combo[128];
      combo[0] = count_imu;
      combo[1] = count_pulse;
      memcpy(&combo[2], payload, pos);
      pm_send_packet_compact(flags, ts_to_use, combo, pos + 2);
    } else if (has_imu) {
      count_imu = 1;
      ts_to_use = imu_sample.ts;

      memcpy(&payload[pos], &imu_sample.ax, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.ay, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.az, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.gx, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.gy, 2); pos += 2;
      memcpy(&payload[pos], &imu_sample.gz, 2); pos += 2;

      uint8_t combo[128];
      combo[0] = count_imu;
      combo[1] = 0; /* no pulse */
      memcpy(&combo[2], payload, pos);
      uint8_t flags = (0x2 << 6);
      pm_send_packet_compact(flags, ts_to_use, combo, pos + 2);
    } else if (has_pulse) {
      count_pulse = 1;
      ts_to_use = (uint64_t)pulse_sample.ts32; /* already ms truncated */

      uint8_t combo[4];
      combo[0] = 0; /* no imu */
      combo[1] = count_pulse;
      memcpy(&combo[2], &pulse_sample.value, 2);

      uint8_t flags = (0x1 << 6);
      pm_send_packet_compact(flags, ts_to_use, combo, 4);
    }

    /* small backoff */
    vTaskDelay(pdMS_TO_TICKS(5));
  }
}

/* Public API */
esp_err_t pm_init(void) {
  if (s_pulse_q || s_imu_q || s_imu_compact_q || s_task) return ESP_OK;
  s_pulse_q = xQueueCreate(PM_PULSE_Q_LEN, sizeof(pm_pulse_item_t));
  s_imu_q = xQueueCreate(PM_IMU_Q_LEN, sizeof(pm_imu_item_t));
  s_imu_compact_q = xQueueCreate(PM_IMU_COMPACT_Q_LEN, sizeof(imu_compact_t));
  if (!s_pulse_q || !s_imu_q || !s_imu_compact_q) {
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

int pm_feed_imu(uint16_t value, uint64_t ts_ms) {
  if (!s_imu_q) return -1;
  pm_imu_item_t it;
  it.value = value;
  it.ts32 = (uint32_t)(ts_ms & 0xFFFFFFFFU);
  if (xQueueSend(s_imu_q, &it, 0) == pdTRUE) return 0;
  return -1;
}

/* Nueva API compacta */
void pm_feed_imu_compact(int16_t ax, int16_t ay, int16_t az,
                         int16_t gx, int16_t gy, int16_t gz,
                         uint64_t timestamp)
{
  if (!s_imu_compact_q) return;
  imu_compact_t it;
  it.ax = ax; it.ay = ay; it.az = az;
  it.gx = gx; it.gy = gy; it.gz = gz;
  it.ts = timestamp;
  xQueueSend(s_imu_compact_q, &it, 0);
}

