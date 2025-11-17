#pragma once
#include "esp_err.h"
#ifdef __cplusplus
extern "C" {
#endif

esp_err_t pulse_sensor_sim_start(void);
uint16_t pulse_sensor_sim_get_latest(void);

#ifdef __cplusplus
}
#endif

