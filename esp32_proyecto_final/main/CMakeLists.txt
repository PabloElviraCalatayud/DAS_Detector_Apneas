idf_component_register(
  SRCS 
    "main.c"
    "network/bluetooth.c"
  INCLUDE_DIRS
    "."
    "network"
  REQUIRES 
    bt 
    nvs_flash
)

