#include "simulador_pulso.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include <math.h>
#include <stdlib.h>
#include "utils/packet_manager.h"

static const char *TAG = "PULSE_SIM";
static uint16_t latest_value = 0;

static void pulse_sim_task(void *arg) {
  (void)arg;
  ESP_LOGW(TAG, "Pulse simulator started");
  float t = 0.0f;
  const float bpm = 72.0f;
  const float hz = bpm / 60.0f;
  const float sample_period_ms = 20.0f; // 50 Hz
  const float base = 600.0f;
  const float amp = 300.0f;
  const float noise_amp = 20.0f;

  while (1) {
    float phase = 2.0f * M_PI * hz * t;
    float sig = amp * (sinf(phase) * sinf(phase));
    sig += ((float)(rand() % 1000) / 1000.0f - 0.5f) * noise_amp;
    if (sig < 0.0f) sig *= 0.15f;
    float valf = base + sig;
    if (valf < 0.0f) valf = 0.0f;
    if (valf > 65535.0f) valf = 65535.0f;
    latest_value = (uint16_t)valf;

    /* Enviar al packet manager (API nueva) */
    if (pm_feed_pulse(latest_value) != 0) {
      ESP_LOGD(TAG, "pm_feed_pulse: queue full, drop %u", latest_value);
    } else {
      ESP_LOGD(TAG, "pm_feed_pulse: enqueued %u", latest_value);
    }

    t += (sample_period_ms / 1000.0f);
    vTaskDelay(pdMS_TO_TICKS((int)sample_period_ms));
  }
}

esp_err_t pulse_sensor_sim_start(void) {
  BaseType_t ok = xTaskCreate(pulse_sim_task, "pulse_sim", 2048, NULL, 6, NULL);
  return ok == pdPASS ? ESP_OK : ESP_FAIL;
}

uint16_t pulse_sensor_sim_get_latest(void) {
  return latest_value;
}

