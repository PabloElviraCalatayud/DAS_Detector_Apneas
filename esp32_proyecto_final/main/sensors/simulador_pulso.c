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

  float bpm = 80.0f;

  while (1) {
    float variation = ((rand() % 1001) / 1000.0f - 0.5f) * 20.0f;

    bpm += variation;

    if (bpm < 40) bpm = 40;
    if (bpm > 180) bpm = 180;

    latest_bpm = (uint16_t)bpm;

    ESP_LOGI(TAG, "Sim BPM = %u", latest_bpm);

    pm_feed_pulse(latest_bpm);

    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

esp_err_t pulse_sensor_sim_start(void) {
  BaseType_t ok = xTaskCreate(pulse_sim_task, "pulse_sim", 2048, NULL, 6, NULL);
  return ok == pdPASS ? ESP_OK : ESP_FAIL;
}

uint16_t pulse_sensor_sim_get_latest(void) {
  return latest_bpm;
}

