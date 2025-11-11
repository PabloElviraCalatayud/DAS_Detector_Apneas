#include "mpu6050.h"
#include "esp_log.h"
#include <math.h>

#define MPU6050_ADDR              0x68
#define MPU6050_REG_PWR_MGMT1     0x6B
#define MPU6050_REG_ACCEL_XOUT_H  0x3B

#define ACCEL_SCALE 16384.0  // ±2g
#define GYRO_SCALE  131.0    // ±250°/s

static const char *TAG = "MPU6050";
static i2c_master_dev_handle_t mpu_handle = NULL;

esp_err_t mpu6050_init(i2c_master_bus_handle_t bus_handle) {
  if (bus_handle == NULL) {
    ESP_LOGE(TAG, "Bus I2C no inicializado");
    return ESP_FAIL;
  }

  i2c_device_config_t dev_cfg = {
    .device_address = MPU6050_ADDR,
    .scl_speed_hz = 100000,
  };

  ESP_ERROR_CHECK(i2c_master_bus_add_device(bus_handle, &dev_cfg, &mpu_handle));

  uint8_t data = 0;
  esp_err_t err = i2c_master_transmit(
    mpu_handle,
    (uint8_t[]){MPU6050_REG_PWR_MGMT1, data},
    2,
    -1
  );

  if (err != ESP_OK) {
    ESP_LOGE(TAG, "No se pudo inicializar el MPU6050");
    return err;
  }

  ESP_LOGI(TAG, "MPU6050 inicializado correctamente");
  return ESP_OK;
}

esp_err_t mpu6050_read(mpu6050_data_t *data) {
  if (mpu_handle == NULL) return ESP_FAIL;

  uint8_t raw[14];
  esp_err_t err = i2c_master_transmit_receive(
    mpu_handle,
    (uint8_t[]){MPU6050_REG_ACCEL_XOUT_H},
    1,
    raw,
    sizeof(raw),
    -1
  );

  if (err != ESP_OK) return err;

  int16_t ax = (raw[0] << 8) | raw[1];
  int16_t ay = (raw[2] << 8) | raw[3];
  int16_t az = (raw[4] << 8) | raw[5];
  int16_t gx = (raw[8] << 8) | raw[9];
  int16_t gy = (raw[10] << 8) | raw[11];
  int16_t gz = (raw[12] << 8) | raw[13];

  // Intercambiamos X <-> Y para coincidir con la serigrafía del GY-521
  float ax_corr = (float)ay / ACCEL_SCALE * 9.80665;
  float ay_corr = (float)ax / ACCEL_SCALE * 9.80665;
  float az_corr = (float)az / ACCEL_SCALE * 9.80665;

  float gx_corr = (float)gy / GYRO_SCALE;
  float gy_corr = (float)gx / GYRO_SCALE;
  float gz_corr = (float)gz / GYRO_SCALE;

  data->accel_x = ax_corr;
  data->accel_y = ay_corr;
  data->accel_z = az_corr;
  data->gyro_x = gx_corr;
  data->gyro_y = gy_corr;
  data->gyro_z = gz_corr;

  return ESP_OK;
}

