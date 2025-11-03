#include "pulse_sensor.h"
#include "bluetooth.h"
#include "adc_driver.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define TAG "PULSE_SENSOR"
#define ADC_CHANNEL ADC_CHANNEL_0

#define FILTER_WINDOW 8
#define SAMPLE_DELAY_MS 5

static adc_continuous_handle_t adc_handle;

/* Variables detección de pulso */
static uint16_t buffer[FILTER_WINDOW];
static int buf_idx = 0;
static int buf_count = 0;

static uint32_t last_peak_time = 0;
static int bpm = 0;

/* Dynamic threshold */
static uint16_t threshold = 2000;
static uint16_t max_val = 0;

static uint16_t moving_average(uint16_t new_sample) {
  buffer[buf_idx] = new_sample;
  buf_idx = (buf_idx + 1) % FILTER_WINDOW;

  if (buf_count < FILTER_WINDOW) {
    buf_count++;
  }

  uint32_t sum = 0;
  for (int i = 0; i < buf_count; i++) {
    sum += buffer[i];
  }

  return sum / buf_count;
}

static void pulse_task(void *arg) {
  adc_channel_result_t result = {
    .channel = ADC_CHANNEL,
    .average = 0
  };

  while (1) {
    int s = adc_driver_read_multi(adc_handle, &result, 1);
    if (s > 0) {
      uint16_t filtered = moving_average(result.average);

      /* Guardamos máximo para autocalibrar umbral */
      if (filtered > max_val) {
        max_val = filtered;
      }

      /* Umbral dinámico */
      threshold = max_val * 0.65;

      uint32_t now = xTaskGetTickCount() * portTICK_PERIOD_MS;

      /* Detección de pico */
      if (filtered > threshold && (now - last_peak_time) > 250) { // 250ms evita doble disparo
        uint32_t dt = now - last_peak_time;
        last_peak_time = now;

        if (dt > 0) {
          bpm = (int)(60000 / dt);

          char msg[32];
          snprintf(msg, sizeof(msg), "%d", bpm);
          send_notification_to_connected(msg);

          ESP_LOGI(TAG, "❤️ Pulse detected! BPM=%d", bpm);
        }

        /* Reset peak value */
        max_val = 0;
      }

      ESP_LOGD(TAG, "raw=%u filtered=%u thr=%u bpm=%d", result.average, filtered, threshold, bpm);
    }

    vTaskDelay(pdMS_TO_TICKS(SAMPLE_DELAY_MS));
  }
}

void pulse_sensor_init(void) {
  ESP_ERROR_CHECK(adc_driver_init(&adc_handle));
  xTaskCreate(pulse_task, "pulse_sensor_task", 4096, NULL, 5, NULL);
  ESP_LOGI(TAG, "PulseSensor inicializado");
}

