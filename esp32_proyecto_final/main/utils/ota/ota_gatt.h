#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Registra el servicio GATT que implementa OTA por BLE.
 *
 * Debe llamarse DESPUÉS de ble_svc_gap_init() y ble_svc_gatt_init()
 * (por ejemplo desde bluetooth_init()).
 */
void ota_gatt_init(void);

#ifdef __cplusplus
}
#endif

