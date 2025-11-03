#include "pulse_sensor.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "../drivers/adc_driver.h"
#include "../network/bluetooth.h"

static const char *TAG = "PULSE_SENSOR";

static adc_continuous_handle_t adc_handle;

#define SEND_FILTERED 1  // 1 = filtrado, 0 = raw

static uint16_t smooth_value(uint16_t new_val) {
  static float filtered = 0;
  const float alpha = 0.1f;
  filtered = (alpha * new_val) + ((1.0f - alpha) * filtered);
  return (uint16_t)filtered;
}

void pulse_sensor_task(void *arg) {
  adc_channel_result_t result = {
    .channel = 0,
    .average = 0
  };

  while (1) {
    adc_driver_read_multi(adc_handle, &result, 1);

    uint16_t raw = result.average;
    uint16_t filtered = smooth_value(raw);

    // Selección del valor a enviar
    uint16_t value_to_send = SEND_FILTERED ? filtered : raw;

    char msg[32];
    snprintf(msg, sizeof(msg), "HR_RAW:%u", value_to_send);

    send_notification_to_connected(msg);
    ESP_LOGI(TAG, "💓 PulseSensor valor%s: %u",
             SEND_FILTERED ? " (filtrado)" : " (raw)",
             value_to_send);

    vTaskDelay(pdMS_TO_TICKS(1000)); // 1 Hz
  }
}

void pulse_sensor_start() {
  ESP_ERROR_CHECK(adc_driver_init(&adc_handle));
  xTaskCreate(pulse_sensor_task, "pulse_task", 4096, NULL, 5, NULL);
}

