idf_component_register(
  SRCS 
    "main.c"
    "network/bluetooth.c"
    "sensors/simulator.c"
  INCLUDE_DIRS
    "."
    "network"
    "sensors"
  REQUIRES 
    bt 
    nvs_flash
)

