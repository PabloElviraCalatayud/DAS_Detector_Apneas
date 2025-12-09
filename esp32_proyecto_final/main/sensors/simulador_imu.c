#include "simulador_imu.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include <math.h>
#include <stdlib.h>
#include "utils/packet_manager.h"
#include "esp_timer.h"

static const char *TAG = "IMU_SIM";

static mpu6050_data_t latest = {0};

static void imu_sim_task(void *arg) {
  (void)arg;
  ESP_LOGW(TAG, "IMU simulator task started");

  float t = 0.0f;
  float lateral_phase = 0.0f;
  float lateral_strength = 0.0f;
  int lateral_timer = 0;

  while (1) {
    float breath = 9.81f + 0.15f * sinf(t * 0.25f);
    float micro_jitter_x = ((rand() % 2001) / 1000.0f - 1.0f) * 0.01f;
    float micro_jitter_y = ((rand() % 2001) / 1000.0f - 1.0f) * 0.01f;

    if (lateral_timer <= 0 && (rand() % 200) < 2) {
      lateral_timer = 50 + (rand() % 75);
      lateral_strength = ((rand() % 2001) / 1000.0f - 1.0f) * 0.25f;
      lateral_phase = 0.0f;
    }

    float lateral_motion_x = 0.0f;
    float lateral_motion_y = 0.0f;

    if (lateral_timer > 0) {
      lateral_motion_x = lateral_strength * sinf(lateral_phase * 0.15f);
      lateral_motion_y = lateral_strength * cosf(lateral_phase * 0.15f);
      lateral_phase += 1.0f;
      lateral_timer--;
    }

    latest.accel_x = micro_jitter_x + lateral_motion_x;
    latest.accel_y = micro_jitter_y + lateral_motion_y;
    latest.accel_z = breath;

    latest.gyro_x = micro_jitter_x * 10.0f + lateral_motion_x * 3.0f;
    latest.gyro_y = micro_jitter_y * 10.0f + lateral_motion_y * 3.0f;
    latest.gyro_z = 0.2f * sinf(t * 0.7f);

    int16_t ax_i = (int16_t)lrintf(latest.accel_x * 100.0f);
    int16_t ay_i = (int16_t)lrintf(latest.accel_y * 100.0f);
    int16_t az_i = (int16_t)lrintf(latest.accel_z * 100.0f);

    int16_t gx_i = (int16_t)lrintf(latest.gyro_x * 100.0f);
    int16_t gy_i = (int16_t)lrintf(latest.gyro_y * 100.0f);
    int16_t gz_i = (int16_t)lrintf(latest.gyro_z * 100.0f);

    uint64_t ts = esp_timer_get_time() / 1000ULL;

    pm_feed_imu_compact(ax_i, ay_i, az_i, gx_i, gy_i, gz_i, ts);

    ESP_LOGI(TAG, "IMU ax=%d ay=%d az=%d gx=%d gy=%d gz=%d ts=%llu",
             ax_i, ay_i, az_i, gx_i, gy_i, gz_i, (unsigned long long)ts);


    t += 0.05f;
    vTaskDelay(pdMS_TO_TICKS(20));
  }
}

esp_err_t mpu6050_sim_start(void) {
  ESP_LOGW(TAG, "Starting IMU simulator...");
  BaseType_t ok = xTaskCreate(imu_sim_task, "imu_sim_task", 4096, NULL, 6, NULL);
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

