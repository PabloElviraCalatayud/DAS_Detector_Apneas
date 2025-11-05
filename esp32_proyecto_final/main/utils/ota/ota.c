#include "ota.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <string.h>
#include <stdbool.h>
static const char *TAG = "BLE_OTA";

static bool ota_in_progress = false;
static const esp_partition_t *update_partition = NULL;
static esp_ota_handle_t update_handle = 0;
static size_t total_written = 0;

void ota_init(void) {
  ota_in_progress = false;
  total_written = 0;
  update_partition = NULL;
  ESP_LOGI(TAG, "OTA BLE inicializada.");
}

bool ota_is_in_progress(void) {
  return ota_in_progress;
}

void ota_process_chunk(const uint8_t *data, size_t len) {
  if (len == 0 || data == NULL) return;

  // Detectar comandos de control
  if (strncmp((const char *)data, "OTA_BEGIN", len) == 0) {
    if (ota_in_progress) {
      ESP_LOGW(TAG, "Ya hay una OTA en curso.");
      return;
    }

    update_partition = esp_ota_get_next_update_partition(NULL);
    if (!update_partition) {
      ESP_LOGE(TAG, "No se encontró partición OTA válida.");
      return;
    }

    if (esp_ota_begin(update_partition, OTA_SIZE_UNKNOWN, &update_handle) != ESP_OK) {
      ESP_LOGE(TAG, "Error iniciando OTA.");
      return;
    }

    ota_in_progress = true;
    total_written = 0;
    ESP_LOGI(TAG, "OTA iniciada en partición '%s'.", update_partition->label);
    return;
  }

  if (strncmp((const char *)data, "OTA_END", len) == 0) {
    if (!ota_in_progress) {
      ESP_LOGW(TAG, "No hay OTA activa para finalizar.");
      return;
    }

    if (esp_ota_end(update_handle) != ESP_OK) {
      ESP_LOGE(TAG, "Error finalizando OTA.");
      return;
    }

    if (esp_ota_set_boot_partition(update_partition) != ESP_OK) {
      ESP_LOGE(TAG, "Error activando nueva partición.");
      return;
    }

    ESP_LOGI(TAG, "OTA completada (%d bytes). Reiniciando...", total_written);
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    return;
  }

  // Si estamos en modo OTA, escribir los datos binarios
  if (ota_in_progress) {
    esp_err_t err = esp_ota_write(update_handle, data, len);
    if (err != ESP_OK) {
      ESP_LOGE(TAG, "Error escribiendo bloque OTA: %s", esp_err_to_name(err));
    } else {
      total_written += len;
    }
    return;
  }

  // Si no estamos en OTA y no es comando, ignorar
  ESP_LOGI(TAG, "Dato recibido fuera de sesión OTA (%d bytes)", len);
}

