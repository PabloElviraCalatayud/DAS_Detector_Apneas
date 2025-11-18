// main.c
#include "bluetooth.h"
#include "utils/packet_manager.h"

#include "sensors/mpu6050.h"
#include "sensors/pulse_sensor.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_timer.h"

#include <math.h>

static const char *TAG = "MAIN";

// ===========================================
// CONFIGURACIÓN I2C (puedes cambiarlo libremente)
// ===========================================
#define I2C_PORT            I2C_NUM_1
#define I2C_SDA_PIN         21
#define I2C_SCL_PIN         22
#define I2C_CLOCK_HZ        400000   // 400 kHz modo FAST

// Frecuencia de lectura IMU
#define IMU_PERIOD_MS       50       // 20 Hz reales

void imu_reader_task(void *arg) {
    mpu6050_data_t imu;

    while (1) {
        if (mpu6050_get_latest(&imu, pdMS_TO_TICKS(20)) == ESP_OK) {

            // Escalar a formato compacto x100 (Opción A)
            int16_t ax_i = (int16_t)lrintf(imu.accel_x * 100.0f);
            int16_t ay_i = (int16_t)lrintf(imu.accel_y * 100.0f);
            int16_t az_i = (int16_t)lrintf(imu.accel_z * 100.0f);

            int16_t gx_i = (int16_t)lrintf(imu.gyro_x * 100.0f);
            int16_t gy_i = (int16_t)lrintf(imu.gyro_y * 100.0f);
            int16_t gz_i = (int16_t)lrintf(imu.gyro_z * 100.0f);

            uint64_t ts = esp_timer_get_time() / 1000ULL;

            pm_feed_imu_compact(ax_i, ay_i, az_i, gx_i, gy_i, gz_i, ts);

            ESP_LOGD(TAG,
                     "IMU REAL → ax:%d ay:%d az:%d | gx:%d gy:%d gz:%d ts:%llu",
                     ax_i, ay_i, az_i, gx_i, gy_i, gz_i,
                     (unsigned long long)ts);
        }

        vTaskDelay(pdMS_TO_TICKS(IMU_PERIOD_MS));
    }
}


void app_main(void) {
    ESP_LOGI(TAG, "==============================");
    ESP_LOGI(TAG, "    🚀 MODO SENSORES REALES");
    ESP_LOGI(TAG, "==============================");

    // Reducir ruido BLE
    esp_log_level_set("NimBLE", ESP_LOG_NONE);
    esp_log_level_set("bt_hci", ESP_LOG_NONE);
    esp_log_level_set("ble_hs", ESP_LOG_NONE);

    ESP_LOGI(TAG, "➡ Inicializando Bluetooth...");
    bluetooth_init();

    ESP_LOGI(TAG, "➡ Inicializando Packet Manager...");
    if (pm_init() != ESP_OK) {
        ESP_LOGE(TAG, "pm_init() failed");
    }

    // ===========================================
    //  INICIALIZAR IMU REAL (I2C1)
    // ===========================================
    ESP_LOGI(TAG, "➡ Inicializando IMU real MPU6050...");

    esp_err_t imu_err = mpu6050_start(
            I2C_PORT,
            I2C_SDA_PIN,
            I2C_SCL_PIN,
            I2C_CLOCK_HZ,
            IMU_PERIOD_MS,
            4096,
            6);

    if (imu_err == ESP_OK) {
        ESP_LOGI(TAG, "MPU6050 inicializada OK");
        ESP_LOGI(TAG, "Calibrando IMU...");
        if (mpu6050_calibrate(200) != ESP_OK) {
            ESP_LOGW(TAG, "Calibrado IMU fallido (pero seguimos)");
        }
        xTaskCreate(imu_reader_task, "imu_reader_task", 4096, NULL, 5, NULL);
    } else {
        ESP_LOGW(TAG, "IMU no disponible (error %s). Seguimos solo con pulso.",
                 esp_err_to_name(imu_err));
    }

    // ===========================================
    //   INICIALIZAR SENSOR REAL DE PULSO (ADC)
    // ===========================================
    ESP_LOGI(TAG, "➡ Inicializando sensor de pulso real...");
    pulse_sensor_start();  // <-- Usa el código real que ya tienes

    // ===========================================
    //  MAIN LOOP (solo debug)
    // ===========================================
    while (1) {
        ESP_LOGI(TAG, "Sistema funcionando (sensores reales)...");
        vTaskDelay(pdMS_TO_TICKS(3000));
    }
}

