#pragma once
#include "esp_err.h"
#include "sensors/mpu6050.h" /* si tienes la estructura mpu6050_data_t */
#ifdef __cplusplus
extern "C" {
#endif

esp_err_t mpu6050_sim_start(void);
esp_err_t mpu6050_sim_get_latest(mpu6050_data_t *out, TickType_t timeout_ticks);
esp_err_t mpu6050_sim_calibrate(size_t samples);

#ifdef __cplusplus
}
#endif

