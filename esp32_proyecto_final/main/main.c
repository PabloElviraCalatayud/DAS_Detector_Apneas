#include "bluetooth.h"
#include "utils/packet_manager.h"

#include "sensors/simulador_imu.h"
#include "sensors/simulador_pulso.h"

#include <math.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

static const char *TAG = "MAIN";

void app_main(void) {
  ESP_LOGI(TAG, "==============================");
  ESP_LOGI(TAG, "  🚀 SIMULATION MODE ACTIVADO");
  ESP_LOGI(TAG, "==============================");

  /* Silenciar logs muy verbosos de BLE (opcional) */
  esp_log_level_set("NimBLE", ESP_LOG_NONE);
  esp_log_level_set("bt_hci", ESP_LOG_NONE);
  esp_log_level_set("ble_hs", ESP_LOG_NONE);

  ESP_LOGI(TAG, "➡ Inicializando Bluetooth...");
  bluetooth_init();

  ESP_LOGI(TAG, "➡ Inicializando Packet Manager (pm_init)...");
  if (pm_init() != ESP_OK) {
    ESP_LOGE(TAG, "pm_init() failed");
    // seguimos de todos modos para poder ver simuladores en acción
  }

  ESP_LOGI(TAG, "➡ Iniciando simulador de pulso...");
  pulse_sensor_sim_start();

  ESP_LOGI(TAG, "➡ Iniciando IMU simulada...");
  //mpu6050_sim_start();

  //mpu6050_sim_calibrate(50);

  while (1) {
    /* --------------------------------------------------
       Nota: los simuladores (simulador_imu / simulador_pulso)
       ya encolan muestras en el "packet manager" (pm_feed_*).
       Aquí sólo las mostramos por log (y evitamos volver a
       encolarlas para no duplicar).
       Si quieres que sea este main el que encole, reemplaza
       los comentarios para llamar a pm_feed_imu/pm_feed_pulse.
       -------------------------------------------------- */

    mpu6050_data_t imu;
    if (mpu6050_sim_get_latest(&imu, pdMS_TO_TICKS(20)) == ESP_OK) {
      ESP_LOGI(TAG, "IMU_SIM → Ax=%.2f Ay=%.2f Az=%.2f | Gx=%.2f Gy=%.2f Gz=%.2f",
               imu.accel_x, imu.accel_y, imu.accel_z,
               imu.gyro_x, imu.gyro_y, imu.gyro_z);

      /* Ejemplo: si quisieras encolar desde aquí en vez del simulador,
         descomenta y calcula la magnitud y timestamp:

      float mag = sqrtf(
        imu.accel_x * imu.accel_x +
        imu.accel_y * imu.accel_y +
        imu.accel_z * imu.accel_z);
      int32_t mg = (int32_t)roundf((mag / 9.80665f) * 1000.0f);
      if (mg < 0) mg = 0;
      if (mg > 65535) mg = 65535;
      uint16_t mag_u16 = (uint16_t)mg;
      uint64_t ts = esp_timer_get_time() / 1000ULL;
      pm_feed_imu(mag_u16, ts);
      */
    }

    uint16_t pulse = pulse_sensor_sim_get_latest();
    ESP_LOGI(TAG, "PULSE_SIM → %u (simulator)", (unsigned)pulse);

    /* Si quieres encolar pulso desde aquí en lugar del simulador:
       pm_feed_pulse(pulse);
    */

    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

