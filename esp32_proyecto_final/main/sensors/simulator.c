#include "simulator.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "../network/bluetooth.h"

static const char *TAG = "SIMULATOR";

void simulator_task(void *arg) {
  int value = 60; // pulso inicial simulado

  while (1) {
    char msg[32];
    value = value < 100 ? value + 1 : 60; // variación sencilla
    snprintf(msg, sizeof(msg), "HR:%d", value);

    send_notification_to_connected(msg);
    ESP_LOGI(TAG, "💓 Simulación enviada: %s", msg);

    vTaskDelay(pdMS_TO_TICKS(2000)); // cada 2 segundos
  }
}

void simulator_start() {
  xTaskCreate(simulator_task, "sim_task", 4096, NULL, 5, NULL);
}

