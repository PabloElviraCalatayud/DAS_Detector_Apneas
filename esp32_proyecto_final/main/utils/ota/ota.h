#ifndef OTA_H
#define OTA_H

#include "esp_err.h"
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
/**
 * @brief Inicializa el módulo OTA (si fuera necesario).
 */
void ota_init(void);

/**
 * @brief Procesa un comando o fragmento recibido vía BLE.
 * 
 * @param data Puntero al buffer recibido.
 * @param len Longitud del buffer.
 */
void ota_process_chunk(const uint8_t *data, size_t len);

/**
 * @brief Retorna si la OTA está en curso.
 */
bool ota_is_in_progress(void);

#endif // OTA_H

