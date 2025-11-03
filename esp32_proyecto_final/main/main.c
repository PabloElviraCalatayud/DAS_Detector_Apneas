#include "bluetooth.h"
#include "sensors/pulse_sensor.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

static const char *TAG = "MAIN";

void app_main(void) {
  ESP_LOGI(TAG, "✅ Inicializando Bluetooth...");
  bluetooth_init();

  ESP_LOGI(TAG, "✅ Iniciando sensor de pulso...");
  pulse_sensor_start();

  // Mantener app_main activa (aunque FreeRTOS sigue corriendo)
  while (1) {
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

