#include "simulador_pulso.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include <stdlib.h>
#include "utils/packet_manager.h"

static const char *TAG = "PULSE_SIM";
static uint16_t latest_bpm = 60;

static void pulse_sim_task(void *arg) {
  (void)arg;
  ESP_LOGW(TAG, "Pulse simulator started");

  float bpm = 70.0f;              // valor inicial
  float drift = 0.0f;

  while (1) {

    // --- Variación suave de BPM ---
    float random_step = ((rand() % 2001) / 1000.0f - 1.0f) * 0.5f; // -0.5 a +0.5
    drift += random_step;

    // Limitar deriva
    if (drift > 5) drift = 5;
    if (drift < -5) drift = -5;

    bpm = 70.0f + drift;

    // Limitar BPM a rango humano
    if (bpm < 55) bpm = 55;
    if (bpm > 95) bpm = 95;

    latest_bpm = (uint16_t)bpm;

    // Enviar
    if (pm_feed_pulse(latest_bpm) != 0) {
      ESP_LOGD(TAG, "pm_feed_pulse: queue full, drop %u", latest_bpm);
    } else {
      ESP_LOGD(TAG, "pm_feed_pulse: enqueued BPM = %u", latest_bpm);
    }

    vTaskDelay(pdMS_TO_TICKS(1000));   // 1 Hz → 1 BPM por segundo
  }
}

esp_err_t pulse_sensor_sim_start(void) {
  BaseType_t ok = xTaskCreate(pulse_sim_task, "pulse_sim", 2048, NULL, 6, NULL);
  return ok == pdPASS ? ESP_OK : ESP_FAIL;
}

uint16_t pulse_sensor_sim_get_latest(void) {
  return latest_bpm;
}

