#include "simulador_imu.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include <math.h>
#include "utils/packet_manager.h"
#include "esp_timer.h"

static const char *TAG = "IMU_SIM";

/* Última muestra simulada */
static mpu6050_data_t latest = {0};

/* ----------- TAREA DE SIMULACIÓN IMU ----------- */
static void imu_sim_task(void *arg) {
  (void)arg;
  ESP_LOGW(TAG, "IMU simulator task started");

  float t = 0.0f;

  while (1) {
    /* Generar datos simulados */
    latest.accel_x = 0.05f * sinf(t * 2.0f);
    latest.accel_y = 0.04f * sinf(t * 1.3f);
    latest.accel_z = 9.81f + 0.02f * sinf(t * 0.7f);

    latest.gyro_x = 1.0f * sinf(t * 1.1f);
    latest.gyro_y = 0.5f * sinf(t * 0.9f);
    latest.gyro_z = 0.3f * sinf(t * 1.7f);

    /* Convertir valores a formato compacto int16 (x100) */
    int16_t ax_i = (int16_t)lrintf(latest.accel_x * 100.0f);
    int16_t ay_i = (int16_t)lrintf(latest.accel_y * 100.0f);
    int16_t az_i = (int16_t)lrintf(latest.accel_z * 100.0f);

    int16_t gx_i = (int16_t)lrintf(latest.gyro_x * 100.0f);
    int16_t gy_i = (int16_t)lrintf(latest.gyro_y * 100.0f);
    int16_t gz_i = (int16_t)lrintf(latest.gyro_z * 100.0f);

    uint64_t ts = esp_timer_get_time() / 1000ULL;

    /* Encolar compact IMU */
    pm_feed_imu_compact(ax_i, ay_i, az_i, gx_i, gy_i, gz_i, ts);

    ESP_LOGD(TAG, "pm_feed_imu_compact enqueued ax=%d ay=%d az=%d gx=%d gy=%d gz=%d ts=%llu",
             ax_i, ay_i, az_i, gx_i, gy_i, gz_i, (unsigned long long)ts);

    t += 0.05f;
    vTaskDelay(pdMS_TO_TICKS(20));  // 50 Hz
  }
}

/* ----------- API PÚBLICA ----------- */
esp_err_t mpu6050_sim_start(void) {
  ESP_LOGW(TAG, "Starting IMU simulator...");

  BaseType_t ok = xTaskCreate(
    imu_sim_task,
    "imu_sim_task",
    4096,
    NULL,
    6,
    NULL
  );

  return ok == pdPASS ? ESP_OK : ESP_FAIL;
}

esp_err_t mpu6050_sim_get_latest(mpu6050_data_t *out, TickType_t timeout) {
  (void)timeout;
  if (!out) return ESP_ERR_INVALID_ARG;
  *out = latest;
  return ESP_OK;
}

esp_err_t mpu6050_sim_calibrate(size_t samples) {
  ESP_LOGW(TAG, "Simulated IMU calibration: %u samples", (unsigned)samples);
  return ESP_OK;
}

