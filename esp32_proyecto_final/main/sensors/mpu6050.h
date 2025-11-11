#ifndef MPU6050_H
#define MPU6050_H

#include "esp_err.h"
#include "driver/i2c.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  float accel_x; // m/s^2
  float accel_y;
  float accel_z;
  float gyro_x;  // deg/s
  float gyro_y;
  float gyro_z;
} mpu6050_data_t;

// Inicializa el bus y lanza la tarea del MPU6050.
// Usa el bus físico indicado (I2C_NUM_0 o I2C_NUM_1), pines y frecuencia.
esp_err_t mpu6050_start(i2c_port_t i2c_port, gpio_num_t sda, gpio_num_t scl, uint32_t clk_hz,
                        uint32_t period_ms, uint32_t stack_size, UBaseType_t task_prio);

// Detiene la tarea y libera recursos.
esp_err_t mpu6050_stop(void);

// Obtiene la última muestra de forma thread-safe.
esp_err_t mpu6050_get_latest(mpu6050_data_t *out, TickType_t timeout_ticks);

// Calibración simple: promedia N lecturas en reposo.
esp_err_t mpu6050_calibrate(size_t samples);

#ifdef __cplusplus
}
#endif

#endif

