// mpu6050.c
#include "mpu6050.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include <math.h>
#include "esp_timer.h"

#include "utils/packet_manager.h"   // ⭐ IMPORTANTE

#define MPU6050_ADDR             0x68
#define MPU6050_REG_PWR_MGMT1    0x6B
#define MPU6050_REG_ACCEL_XOUT_H 0x3B

#define ACCEL_SCALE 16384.0f
#define GYRO_SCALE  131.0f
#define G_TO_MS2    9.80665f

static const char *TAG = "MPU6050";

static i2c_port_t s_i2c_port;
static TaskHandle_t s_task = NULL;
static SemaphoreHandle_t s_mutex = NULL;

static mpu6050_data_t s_last = {0};

static int16_t s_offset_ax = 0, s_offset_ay = 0, s_offset_az = 0;
static int16_t s_offset_gx = 0, s_offset_gy = 0, s_offset_gz = 0;

static uint32_t s_period_ms = 200;

// =======================
// I2C BASICO
// =======================
static esp_err_t i2c_write(uint8_t reg, uint8_t data) {
    uint8_t buf[2] = {reg, data};
    return i2c_master_write_to_device(
        s_i2c_port, MPU6050_ADDR,
        buf, sizeof(buf),
        pdMS_TO_TICKS(100)
    );
}

static esp_err_t i2c_read(uint8_t reg, uint8_t *out, size_t len) {
    return i2c_master_write_read_device(
        s_i2c_port, MPU6050_ADDR,
        &reg, 1,
        out, len,
        pdMS_TO_TICKS(100)
    );
}

// =======================
// TAREA MPU6050
// =======================
static void mpu_task(void *arg) {
    (void)arg;
    uint8_t raw[14];

    while (1) {
        if (i2c_read(MPU6050_REG_ACCEL_XOUT_H, raw, sizeof(raw)) == ESP_OK) {

            int16_t ax = (raw[0] << 8) | raw[1];
            int16_t ay = (raw[2] << 8) | raw[3];
            int16_t az = (raw[4] << 8) | raw[5];
            int16_t gx = (raw[8] << 8) | raw[9];
            int16_t gy = (raw[10] << 8) | raw[11];
            int16_t gz = (raw[12] << 8) | raw[13];

            // Aplicar offset + conversión
            float ax_f = ((float)(ax - s_offset_ax) / ACCEL_SCALE) * G_TO_MS2;
            float ay_f = ((float)(ay - s_offset_ay) / ACCEL_SCALE) * G_TO_MS2;
            float az_f = ((float)(az - s_offset_az) / ACCEL_SCALE) * G_TO_MS2;

            float gx_f = (float)(gx - s_offset_gx) / GYRO_SCALE;
            float gy_f = (float)(gy - s_offset_gy) / GYRO_SCALE;
            float gz_f = (float)(gz - s_offset_gz) / GYRO_SCALE;

            // Corrección de ejes (si aplicaba en tu diseño original)
            float ax_corr = ay_f;
            float ay_corr = ax_f;
            float az_corr = az_f;

            float gx_corr = gy_f;
            float gy_corr = gx_f;
            float gz_corr = gz_f;

            // Guardar datos crudos/convertidos
            if (xSemaphoreTake(s_mutex, pdMS_TO_TICKS(10)) == pdTRUE) {
                s_last.accel_x = ax_corr;
                s_last.accel_y = ay_corr;
                s_last.accel_z = az_corr;

                s_last.gyro_x = gx_corr;
                s_last.gyro_y = gy_corr;
                s_last.gyro_z = gz_corr;

                xSemaphoreGive(s_mutex);
            }

            // ============================
            //   ENVIAR A PACKET MANAGER
            // ============================
            int16_t ax_i = (int16_t)lrintf(ax_corr * 100.0f);
            int16_t ay_i = (int16_t)lrintf(ay_corr * 100.0f);
            int16_t az_i = (int16_t)lrintf(az_corr * 100.0f);

            int16_t gx_i = (int16_t)lrintf(gx_corr * 100.0f);
            int16_t gy_i = (int16_t)lrintf(gy_corr * 100.0f);
            int16_t gz_i = (int16_t)lrintf(gz_corr * 100.0f);

            uint64_t ts = esp_timer_get_time() / 1000ULL;

            pm_feed_imu_compact(
                ax_i, ay_i, az_i,
                gx_i, gy_i, gz_i,
                ts
            );
        }
        else {
            ESP_LOGW(TAG, "Lectura MPU6050 fallida");
        }

        vTaskDelay(pdMS_TO_TICKS(s_period_ms));
    }
}

// =======================
// API PUBLICA
// =======================
esp_err_t mpu6050_start(i2c_port_t i2c_port, gpio_num_t sda, gpio_num_t scl,
                        uint32_t clk_hz, uint32_t period_ms,
                        uint32_t stack_size, UBaseType_t task_prio) {
    
    s_i2c_port = i2c_port;

    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = sda,
        .scl_io_num = scl,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = clk_hz,
    };

    esp_err_t err = i2c_param_config(s_i2c_port, &conf);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "i2c_param_config failed: %s", esp_err_to_name(err));
        return err;
    }

    err = i2c_driver_install(s_i2c_port, I2C_MODE_MASTER, 0, 0, 0);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "i2c_driver_install failed: %s", esp_err_to_name(err));
        return err;
    }

    // Wake MPU6050 (no usar ESP_ERROR_CHECK aquí para evitar abortar si no está presente)
    err = i2c_write(MPU6050_REG_PWR_MGMT1, 0x00);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "Advertencia: no se pudo wakear MPU6050 (i2c write): %s", esp_err_to_name(err));
        // Limpieza parcial: desinstalamos driver para dejar I2C como estaba
        i2c_driver_delete(s_i2c_port);
        return err;
    }

    s_mutex = xSemaphoreCreateMutex();
    s_period_ms = period_ms ? period_ms : 200;

    BaseType_t ok = xTaskCreate(
        mpu_task, "mpu6050_task",
        stack_size ? stack_size : 4096,
        NULL,
        task_prio ? task_prio : 5,
        &s_task
    );

    if (ok != pdPASS) {
        ESP_LOGE(TAG, "No se pudo crear tarea MPU6050");
        // si hubo fallo, limpiar driver y mutex
        if (s_mutex) { vSemaphoreDelete(s_mutex); s_mutex = NULL; }
        i2c_driver_delete(s_i2c_port);
        return ESP_FAIL;
    }

    ESP_LOGI(TAG, "MPU6050 inicializado en I2C%d  (SDA=%d, SCL=%d)",
             s_i2c_port, sda, scl);

    return ESP_OK;
}

esp_err_t mpu6050_stop(void) {
    if (s_task) { vTaskDelete(s_task); s_task = NULL; }
    if (s_mutex) { vSemaphoreDelete(s_mutex); s_mutex = NULL; }
    i2c_driver_delete(s_i2c_port);
    return ESP_OK;
}

esp_err_t mpu6050_get_latest(mpu6050_data_t *out, TickType_t timeout_ticks) {
    if (!out) return ESP_ERR_INVALID_ARG;
    if (!s_mutex) return ESP_ERR_INVALID_STATE;

    if (xSemaphoreTake(s_mutex, timeout_ticks) != pdTRUE)
        return ESP_ERR_TIMEOUT;

    *out = s_last;
    xSemaphoreGive(s_mutex);

    return ESP_OK;
}

esp_err_t mpu6050_calibrate(size_t samples) {
    if (samples == 0) samples = 200;

    uint8_t raw[14];
    int64_t sum_ax = 0, sum_ay = 0, sum_az = 0;
    int64_t sum_gx = 0, sum_gy = 0, sum_gz = 0;

    for (size_t i = 0; i < samples; i++) {
        if (i2c_read(MPU6050_REG_ACCEL_XOUT_H, raw, sizeof(raw)) == ESP_OK) {

            int16_t ax = (raw[0] << 8) | raw[1];
            int16_t ay = (raw[2] << 8) | raw[3];
            int16_t az = (raw[4] << 8) | raw[5];

            int16_t gx = (raw[8] << 8) | raw[9];
            int16_t gy = (raw[10] << 8) | raw[11];
            int16_t gz = (raw[12] << 8) | raw[13];

            sum_ax += ax;
            sum_ay += ay;
            sum_az += az;

            sum_gx += gx;
            sum_gy += gy;
            sum_gz += gz;
        }

        vTaskDelay(pdMS_TO_TICKS(5));
    }

    s_offset_ax = sum_ax / samples;
    s_offset_ay = sum_ay / samples;
    s_offset_az = sum_az / samples - (int16_t)ACCEL_SCALE; // quitar gravedad

    s_offset_gx = sum_gx / samples;
    s_offset_gy = sum_gy / samples;
    s_offset_gz = sum_gz / samples;

    ESP_LOGI(TAG,
        "Calibrado: ax=%d ay=%d az=%d gx=%d gy=%d gz=%d",
        s_offset_ax, s_offset_ay, s_offset_az,
        s_offset_gx, s_offset_gy, s_offset_gz
    );

    return ESP_OK;
}

