#include "pulse_sensor.h"
#include "../drivers/adc_driver.h"
#include "../network/bluetooth.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_timer.h"
#include <math.h>
#include <string.h>

#define REPORT_PERIOD_MS 500
#define TAG "PULSE_SENSOR"

static adc_continuous_handle_t adc_handle;
static float last_bpm = 0.0f;

void pulse_sensor_task(void *pvParameters) {
  adc_channel_result_t results[] = {
    {.channel = ADC_CHANNEL_0, .average = 0},
  };

  float bpm = 0.0f;
  float threshold = 2000.0f;
  bool pulse_detected = false;
  int64_t last_pulse_time = 0;
  int64_t last_report_time = 0;

  ESP_LOGI(TAG, "💓 Iniciando lectura continua del ADC...");

  while (1) {
    int samples = adc_driver_read_multi(adc_handle, results, 1);
    if (samples <= 0) {
      vTaskDelay(pdMS_TO_TICKS(10));
      continue;
    }

    int raw = results[0].average;
    int64_t now = esp_timer_get_time();

    // Seguimiento dinámico del nivel base
    threshold = 0.95f * threshold + 0.05f * raw;

    // Detección de cruce de umbral (subida)
    if (!pulse_detected && raw > threshold + 250) {
      pulse_detected = true;

      if (last_pulse_time > 0) {
        float interval_s = (now - last_pulse_time) / 1000000.0f;
        float new_bpm = 60.0f / interval_s;

        // Filtro suave para estabilizar BPM
        bpm = 0.8f * last_bpm + 0.2f * new_bpm;
        last_bpm = bpm;
      }

      last_pulse_time = now;
    }

    // Reinicia el flag cuando la señal baja
    if (pulse_detected && raw < threshold) {
      pulse_detected = false;
    }

    // Enviar datos cada 0.5 segundos
    if ((now - last_report_time) > (REPORT_PERIOD_MS * 1000)) {
      last_report_time = now;
      char msg[64];
      snprintf(msg, sizeof(msg), "BPM:%.1f", bpm);
      send_notification_to_connected(msg);
      ESP_LOGI(TAG, "💓 BPM:%.1f", raw, bpm);
    }

    vTaskDelay(pdMS_TO_TICKS(10)); // pequeño retardo (10 ms)
  }
}

void pulse_sensor_start() {
  ESP_LOGI(TAG, "Configurando ADC continuo...");
  adc_driver_init(&adc_handle);

  xTaskCreate(pulse_sensor_task, "pulse_sensor_task", 4096, NULL, 5, NULL);
}

