#pragma once
#include <stdint.h>
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * API minimalista del Packet Manager (Opción A).
 *
 * Formato compacto (Option A):
 *  byte0: flags (uint8)
 *  bytes1..8: timestamp (uint64 LE)
 *  byte9: count_imu (uint8)
 *  byte10: count_pulse (uint8)
 *  following: for each imu sample -> ax,ay,az,gx,gy,gz (int16 LE each)
 *             for each pulse sample -> uint16 LE
 */

/* Inicializa colas y tarea del packet manager. */
esp_err_t pm_init(void);

/* Encolar muestra de pulso (no bloqueante). Devuelve 0=ok, -1=drop */
int pm_feed_pulse(uint16_t value);

/* Encolar muestra compacta de IMU (6 int16 escalados x100) */
int pm_feed_imu_compact(int16_t ax, int16_t ay, int16_t az,
                        int16_t gx, int16_t gy, int16_t gz,
                        uint64_t timestamp_ms);

/* Función para construir paquete compacto en buffer (devuelve longitud o -1) */
int packet_manager_build_compact(uint8_t *out, uint8_t max_len,
                                 uint8_t flags, uint64_t timestamp,
                                 const int16_t *imu_flat /* ptr to 6*imu_count int16 */,
                                 uint8_t imu_count,
                                 const uint16_t *pulses,
                                 uint8_t pulse_count);

/* Enviar paquete compacto directamente (usa bluetooth send_notification_binary) */
void packet_manager_send_compact(uint8_t flags, uint64_t timestamp,
                                 const int16_t *imu_flat, uint8_t imu_count,
                                 const uint16_t *pulses, uint8_t pulse_count);

#ifdef __cplusplus
}
#endif

