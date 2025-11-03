idf_component_register(
  SRCS 
    "main.c"
    "network/bluetooth.c"
    "drivers/adc_driver.c"
    "sensors/pulse_sensor.c"
  INCLUDE_DIRS
    "."
    "network"
    "drivers"
    "sensors"
  REQUIRES 
    bt 
    nvs_flash
    esp_adc
)

