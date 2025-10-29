#include <stdio.h>
#include <string.h>
#include "esp_log.h"
#include "nvs_flash.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"

static const char *TAG = "BLE_MINIMAL";

/* Variables globales necesarias en varios callbacks */
static uint8_t own_addr_type;
static struct ble_gap_adv_params adv_params;

/* Mensaje que se envía al leer la característica */
static const char *device_message = "Hola desde ESP32 NimBLE!";

/* ------------------------------------------------------ */
/* Callback de lectura GATT                               */
/* ------------------------------------------------------ */
static int gatt_char_access_cb(uint16_t conn_handle, uint16_t attr_handle,
                               struct ble_gatt_access_ctxt *ctxt, void *arg) {
  if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR) {
    os_mbuf_append(ctxt->om, device_message, strlen(device_message));
  }
  return 0;
}

/* ------------------------------------------------------ */
/* Definición del servicio GATT                           */
/* ------------------------------------------------------ */
static const struct ble_gatt_svc_def gatt_svr_defs[] = {
  {
    .type = BLE_GATT_SVC_TYPE_PRIMARY,
    .uuid = BLE_UUID16_DECLARE(0x180A), // Servicio de información del dispositivo
    .characteristics = (struct ble_gatt_chr_def[]) {
      {
        .uuid = BLE_UUID16_DECLARE(0x2A29), // Característica "Fabricante"
        .access_cb = gatt_char_access_cb,
        .flags = BLE_GATT_CHR_F_READ,
      },
      {0}
    },
  },
  {0}
};

/* ------------------------------------------------------ */
/* Evento GAP: conexión/desconexión                       */
/* ------------------------------------------------------ */
static int ble_gap_event(struct ble_gap_event *event, void *arg) {
  switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
      if (event->connect.status == 0) {
        ESP_LOGI(TAG, "Conectado a un cliente BLE.");
      } else {
        ESP_LOGI(TAG, "Fallo de conexión, reiniciando advertising...");
        ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER, &adv_params,
                          ble_gap_event, NULL);
      }
      break;

    case BLE_GAP_EVENT_DISCONNECT:
      ESP_LOGI(TAG, "Desconectado, reiniciando advertising...");
      ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER, &adv_params,
                        ble_gap_event, NULL);
      break;

    default:
      break;
  }
  return 0;
}

/* ------------------------------------------------------ */
/* Callback cuando BLE está sincronizado y listo          */
/* ------------------------------------------------------ */
static void ble_on_sync(void) {
  int rc;
  ble_hs_id_infer_auto(0, &own_addr_type);

  uint8_t addr_val[6] = {0};
  ble_hs_id_copy_addr(own_addr_type, addr_val, NULL);
  ESP_LOGI(TAG, "Dirección BLE: %02X:%02X:%02X:%02X:%02X:%02X",
           addr_val[5], addr_val[4], addr_val[3],
           addr_val[2], addr_val[1], addr_val[0]);

  /* Configurar información de advertising */
  struct ble_hs_adv_fields fields;
  memset(&fields, 0, sizeof(fields));
  fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
  fields.name = (uint8_t *)"ESP32 NimBLE";
  fields.name_len = strlen((char *)fields.name);
  fields.name_is_complete = 1;

  rc = ble_gap_adv_set_fields(&fields);
  if (rc != 0) {
    ESP_LOGE(TAG, "Error configurando advertising: %d", rc);
    return;
  }

  memset(&adv_params, 0, sizeof(adv_params));
  adv_params.conn_mode = BLE_GAP_CONN_MODE_UND;
  adv_params.disc_mode = BLE_GAP_DISC_MODE_GEN;

  rc = ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER, &adv_params,
                         ble_gap_event, NULL);
  if (rc != 0) {
    ESP_LOGE(TAG, "Error iniciando advertising: %d", rc);
  } else {
    ESP_LOGI(TAG, "Advertising iniciado...");
  }
}

/* ------------------------------------------------------ */
/* Tarea principal NimBLE                                 */
/* ------------------------------------------------------ */
void ble_host_task(void *param) {
  nimble_port_run();
  nimble_port_freertos_deinit();
}

/* ------------------------------------------------------ */
/* app_main: punto de entrada principal                   */
/* ------------------------------------------------------ */
void app_main(void) {
  esp_err_t ret;

  /* Inicializar NVS (requerido por BLE/WiFi) */
  ret = nvs_flash_init();
  if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
    ESP_ERROR_CHECK(nvs_flash_erase());
    ret = nvs_flash_init();
  }
  ESP_ERROR_CHECK(ret);

  /* Inicializar NimBLE */
  ESP_ERROR_CHECK(nimble_port_init());

  /* Configuración de seguridad: sin emparejamiento */
  ble_hs_cfg.sm_io_cap = BLE_HS_IO_NO_INPUT_OUTPUT;
  ble_hs_cfg.sm_bonding = 0;
  ble_hs_cfg.sm_mitm = 0;
  ble_hs_cfg.sm_sc = 0;
  ble_hs_cfg.sm_our_key_dist = 0;
  ble_hs_cfg.sm_their_key_dist = 0;

  /* Inicializar servicios GAP y GATT */
  ble_svc_gap_init();
  ble_svc_gatt_init();

  /* Registrar servicio personalizado */
  ble_gatts_count_cfg(gatt_svr_defs);
  ble_gatts_add_svcs(gatt_svr_defs);

  /* Callback de sincronización BLE */
  ble_hs_cfg.sync_cb = ble_on_sync;

  /* Iniciar tarea del host BLE */
  nimble_port_freertos_init(ble_host_task);
}

