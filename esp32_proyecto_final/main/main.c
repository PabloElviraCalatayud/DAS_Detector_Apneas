#include "bluetooth.h"
#include "utils/packet_manager.h"

#include "sensors/simulador_imu.h"
#include "sensors/simulador_pulso.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_timer.h"

#include <math.h>

static const char *TAG = "MAIN";

#define IMU_PERIOD_MS 50

void imu_reader_task(void *arg) {
  (void)arg;
  mpu6050_data_t imu;

  while (1) {
    if (mpu6050_sim_get_latest(&imu, pdMS_TO_TICKS(20)) == ESP_OK) {
      int16_t ax_i = (int16_t)lrintf(imu.accel_x * 100.0f);
      int16_t ay_i = (int16_t)lrintf(imu.accel_y * 100.0f);
      int16_t az_i = (int16_t)lrintf(imu.accel_z * 100.0f);

      int16_t gx_i = (int16_t)lrintf(imu.gyro_x * 100.0f);
      int16_t gy_i = (int16_t)lrintf(imu.gyro_y * 100.0f);
      int16_t gz_i = (int16_t)lrintf(imu.gyro_z * 100.0f);

      uint64_t ts = esp_timer_get_time() / 1000ULL;

      pm_feed_imu_compact(ax_i, ay_i, az_i, gx_i, gy_i, gz_i, ts);

      ESP_LOGD(TAG,
        "IMU SIM → ax:%d ay:%d az:%d | gx:%d gy:%d gz:%d ts:%llu",
        ax_i, ay_i, az_i, gx_i, gy_i, gz_i, (unsigned long long)ts
      );
    }

    vTaskDelay(pdMS_TO_TICKS(IMU_PERIOD_MS));
  }
}

void app_main(void) {
  ESP_LOGI(TAG, "==============================");
  ESP_LOGI(TAG, "    🧪 MODO SENSORES SIMULADOS");
  ESP_LOGI(TAG, "==============================");

  esp_log_level_set("NimBLE", ESP_LOG_NONE);
  esp_log_level_set("bt_hci", ESP_LOG_NONE);
  esp_log_level_set("ble_hs", ESP_LOG_NONE);

  ESP_LOGI(TAG, "➡ Inicializando Bluetooth...");
  bluetooth_init();

  ESP_LOGI(TAG, "➡ Inicializando Packet Manager...");
  if (pm_init() != ESP_OK) {
    ESP_LOGE(TAG, "pm_init() failed");
  }

  ESP_LOGI(TAG, "➡ Inicializando IMU simulada...");
  if (mpu6050_sim_start() == ESP_OK) {
    ESP_LOGI(TAG, "IMU simulada OK");
    mpu6050_sim_calibrate(200);
    xTaskCreate(imu_reader_task, "imu_reader_task", 4096, NULL, 5, NULL);
  } else {
    ESP_LOGE(TAG, "Error iniciando IMU simulada");
  }

  ESP_LOGI(TAG, "➡ Inicializando sensor de pulso simulado...");
  if (pulse_sensor_sim_start() != ESP_OK) {
    ESP_LOGE(TAG, "Error iniciando pulso simulado");
  }

  while (1) {
    ESP_LOGI(TAG, "Sistema funcionando (simulado)...");
    vTaskDelay(pdMS_TO_TICKS(3000));
  }
}

