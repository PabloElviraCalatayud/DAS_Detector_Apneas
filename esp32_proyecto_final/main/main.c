#include "bluetooth.h"
#include "sensors/simulator.h"

void app_main(void) {
  bluetooth_init();
  simulator_start();  // <-- arrancamos la simulación
}

