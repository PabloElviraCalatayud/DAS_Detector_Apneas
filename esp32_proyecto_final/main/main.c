#include "bluetooth.h"
#include "sensors/pulse_sensor.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void app_main(void) {
  bluetooth_init();
  pulse_sensor_start();

}

