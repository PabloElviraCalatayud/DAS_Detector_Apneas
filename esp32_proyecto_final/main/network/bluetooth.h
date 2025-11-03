#ifndef BLUETOOTH_H
#define BLUETOOTH_H

#include "esp_err.h"
#include "host/ble_hs.h"

/**
 * @brief Inicializa el stack Bluetooth NimBLE y los servicios GATT.
 */
void bluetooth_init(void);

/**
 * @brief Envía una notificación BLE al cliente conectado.
 * 
 * @param conn_handle Handle de conexión BLE.
 * @param msg Mensaje a enviar como notificación.
 */
void send_notification(uint16_t conn_handle, const char *msg);
/**
 * @brief Envía una notificación al cliente conectado (si existe).
 */
void send_notification_to_connected(const char *msg);

/**
 * @brief Tarea principal del host BLE. No debe llamarse directamente.
 */
void ble_host_task(void *param);

#endif // BLUETOOTH_H

