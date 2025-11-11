#include "bluetooth.h"
#include "sensors/pulse_sensor.h"
#include "sensors/mpu6050.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

static const char *TAG = "MAIN";

void app_main(void) {
  ESP_LOGI(TAG, "✅ Inicializando Bluetooth...");
  bluetooth_init();

  ESP_LOGI(TAG, "✅ Iniciando sensor de pulso...");
  pulse_sensor_start();

  ESP_LOGI(TAG, "✅ Iniciando MPU6050...");
  if (mpu6050_start(I2C_NUM_0, 21, 22, 100000, 200, 4096, 5) == ESP_OK) {
    mpu6050_calibrate(200);
  } else {
    ESP_LOGE(TAG, "Fallo al iniciar MPU6050");
  }

  while (1) {
    mpu6050_data_t data;
    if (mpu6050_get_latest(&data, pdMS_TO_TICKS(50)) == ESP_OK) {
      ESP_LOGI(TAG, "Accel: X=%.2f Y=%.2f Z=%.2f | Gyro: X=%.2f Y=%.2f Z=%.2f",
               data.accel_x, data.accel_y, data.accel_z,
               data.gyro_x, data.gyro_y, data.gyro_z);
    }
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

