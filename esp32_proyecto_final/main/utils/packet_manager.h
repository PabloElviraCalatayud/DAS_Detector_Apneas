#pragma once
#include <stdint.h>
#include "esp_err.h"

/**
 * Packet manager - versión nueva y minimalista.
 *
 * API:
 *   pm_init()                     - inicializa colas y tarea
 *   pm_feed_pulse(uint16_t v)     - encola valor de pulso (por ejemplo ADC o BPM)
 *   pm_feed_imu(uint16_t v, uint64_t ts) - encola un valor reducido de IMU + timestamp
 *
 * Nueva API compacta:
 *   pm_feed_imu_compact(int16_t ax, int16_t ay, int16_t az,
 *                       int16_t gx, int16_t gy, int16_t gz,
 *                       uint64_t timestamp);
 *
 * Formato compacto (Opción A):
 *   byte0: flags (uint8)
 *   bytes1..8: timestamp (uint64 little-endian)
 *   byte9: count_imu (uint8)
 *   byte10: count_pulse (uint8)
 *   following: for each imu sample -> ax,ay,az,gx,gy,gz (int16 LE each)
 *              for each pulse sample -> uint16 LE
 */

#ifdef __cplusplus
extern "C" {
#endif

esp_err_t pm_init(void);

/* Encolar muestra de pulso (no bloqueante). Devuelve 0=ok, -1=drop */
int pm_feed_pulse(uint16_t value);

/* Encolar muestra reducida de IMU (p. ej. accel magnitude escalada) con timestamp ms.
 * value: uint16_t
 * ts_ms: timestamp en ms (uint64_t) - internamente truncado a 32 bits para paquete (antigua API).
 *
 * Devuelve 0=ok, -1=drop
 */
int pm_feed_imu(uint16_t value, uint64_t ts_ms);

/* Nueva: Encolar IMU compacta (6 valores int16 escalados ×100) */
void pm_feed_imu_compact(int16_t ax, int16_t ay, int16_t az,
                         int16_t gx, int16_t gy, int16_t gz,
                         uint64_t timestamp);

#ifdef __cplusplus
}
#endif

