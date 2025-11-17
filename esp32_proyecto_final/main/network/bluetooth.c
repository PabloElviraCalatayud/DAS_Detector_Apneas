#include "../utils/ota/ota.h"
#include "bluetooth.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"
#include <string.h>

static const char *TAG = "BLE_BIDIRECTIONAL";

static uint8_t own_addr_type;
static struct ble_gap_adv_params adv_params;

/* Buffers */
static char device_message[64] = "Hola desde ESP32 NimBLE!";
static char received_message[64] = "";

/* Handle de la característica de notificación */
static uint16_t notify_handle;

/* Guardamos el handle de conexión actual para usar en notificaciones */
static int16_t g_conn_handle = -1;

/* UUIDs personalizados (128-bit) */
#define SERVICE_UUID       BLE_UUID128_DECLARE(0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF)
#define CHAR_WRITE_UUID    BLE_UUID128_DECLARE(0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xE1)
#define CHAR_NOTIFY_UUID   BLE_UUID128_DECLARE(0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xEF,0x12,0x34,0x56,0x78,0x90,0xAB,0xCD,0xE2)

/* ------------------------------------------------------ */
/* Callback de lectura/escritura                          */
/* ------------------------------------------------------ */
static int gatt_char_access_cb(uint16_t conn_handle, uint16_t attr_handle,
                               struct ble_gatt_access_ctxt *ctxt, void *arg) {
  /* Si es lectura: devolvemos device_message */
  if (ctxt->op == BLE_GATT_ACCESS_OP_READ_CHR) {
    os_mbuf_append(ctxt->om, device_message, strlen(device_message));
    ESP_LOGI(TAG, "Cliente leyó mensaje: %s", device_message);
  }
  /* Si es escritura: copiamos en received_message */
  else if (ctxt->op == BLE_GATT_ACCESS_OP_WRITE_CHR) {
    int len = OS_MBUF_PKTLEN(ctxt->om);
    if (len > sizeof(received_message) - 1) len = sizeof(received_message) - 1;
    os_mbuf_copydata(ctxt->om, 0, len, received_message);
    received_message[len] = '\0';
    ESP_LOGI(TAG, "📩 Mensaje recibido del cliente: %s", received_message);

  ota_process_chunk((uint8_t *)received_message, len);

  }
  return 0;
}

/* ------------------------------------------------------ */
/* Servicio GATT personalizado                            */
/* ------------------------------------------------------ */
static const struct ble_gatt_svc_def gatt_svr_defs[] = {
  {
    .type = BLE_GATT_SVC_TYPE_PRIMARY,
    .uuid = SERVICE_UUID,
    .characteristics = (struct ble_gatt_chr_def[]) {
      {
        /* Característica de escritura (cliente -> servidor) */
        .uuid = CHAR_WRITE_UUID,
        .access_cb = gatt_char_access_cb,
        .flags = BLE_GATT_CHR_F_WRITE, /* admitimos write with response */
      },
      {
        /* Característica de notificación (servidor -> cliente) */
        .uuid = CHAR_NOTIFY_UUID,
        .access_cb = gatt_char_access_cb,
        .val_handle = &notify_handle,
        .flags = BLE_GATT_CHR_F_NOTIFY,
      },
      {0}
    },
  },
  {0}
};

/* ------------------------------------------------------ */
/* GAP event handler                                      */
/* ------------------------------------------------------ */
static int ble_gap_event(struct ble_gap_event *event, void *arg) {
  switch (event->type) {
    case BLE_GAP_EVENT_CONNECT:
      if (event->connect.status == 0) {
        /* Guardamos el handle de la conexión para usarlo en notificaciones */
        g_conn_handle = event->connect.conn_handle;
        ESP_LOGI(TAG, "✅ Cliente conectado (handle=%d).", g_conn_handle);
      } else {
        ESP_LOGI(TAG, "❌ Fallo de conexión, reiniciando advertising...");
        g_conn_handle = -1;
        ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER, &adv_params,
                          ble_gap_event, NULL);
      }
      break;

    case BLE_GAP_EVENT_DISCONNECT:
      ESP_LOGI(TAG, "🔌 Cliente desconectado. Reiniciando advertising...");
      /* limpiar handle */
      g_conn_handle = -1;
      ble_gap_adv_start(own_addr_type, NULL, BLE_HS_FOREVER, &adv_params,
                        ble_gap_event, NULL);
      break;

    default:
      break;
  }
  return 0;
}

/* ------------------------------------------------------ */
/* Sincronización BLE                                     */
/* ------------------------------------------------------ */
static void ble_on_sync(void) {
  int rc;
  ble_hs_id_infer_auto(0, &own_addr_type);

  uint8_t addr_val[6] = {0};
  ble_hs_id_copy_addr(own_addr_type, addr_val, NULL);
  ESP_LOGI(TAG, "Dirección BLE: %02X:%02X:%02X:%02X:%02X:%02X",
           addr_val[5], addr_val[4], addr_val[3],
           addr_val[2], addr_val[1], addr_val[0]);

  struct ble_hs_adv_fields fields;
  memset(&fields, 0, sizeof(fields));
  fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
  fields.name = (uint8_t *)"ESP32_NimBLE";
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
    ESP_LOGI(TAG, "📢 Advertising iniciado...");
  }
}

/* ------------------------------------------------------ */
/* Función pública: enviar notificación (usando conn handle guardado) */
/* ------------------------------------------------------ */
void send_notification(uint16_t conn_handle, const char *msg) {
  if (notify_handle == 0) {
    ESP_LOGW(TAG, "Intentando notificar pero notify_handle == 0. ¿Característica inicializada?");
    return;
  }
  struct os_mbuf *om = ble_hs_mbuf_from_flat(msg, strlen(msg));
  ble_gattc_notify_custom(conn_handle, notify_handle, om);
  ESP_LOGI(TAG, "📤 Notificación enviada (handle %u): %s", conn_handle, msg);
}

/* Conveniencia: notificar al cliente conectado (si existe) */
void send_notification_to_connected(const char *msg) {
  if (g_conn_handle < 0) {
    ESP_LOGW(TAG, "No hay cliente conectado para notificar.");
    return;
  }
  send_notification((uint16_t)g_conn_handle, msg);
}

/* ------------------------------------------------------ */
/* Tarea del host BLE                                     */
/* ------------------------------------------------------ */
void ble_host_task(void *param) {
  nimble_port_run();
  nimble_port_freertos_deinit();
}

/* ------------------------------------------------------ */
/* Inicialización principal BLE                           */
/* ------------------------------------------------------ */
void bluetooth_init(void) {
  esp_err_t ret = nvs_flash_init();
  if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
    ESP_ERROR_CHECK(nvs_flash_erase());
    ret = nvs_flash_init();
  }
  ESP_ERROR_CHECK(ret);

  ESP_ERROR_CHECK(nimble_port_init());

  ble_hs_cfg.sm_io_cap = BLE_HS_IO_NO_INPUT_OUTPUT;
  ble_hs_cfg.sync_cb = ble_on_sync;

  ble_svc_gap_init();
  ble_svc_gatt_init();

  /* Registrar servicios GATT definidos */
  ble_gatts_count_cfg(gatt_svr_defs);
  ble_gatts_add_svcs(gatt_svr_defs);

  nimble_port_freertos_init(ble_host_task);
}
void send_notification_binary(const uint8_t *data, uint16_t len) {
  if (g_conn_handle < 0) {
    ESP_LOGW(TAG, "No hay cliente conectado para notificar binario.");
    return;
  }

  if (notify_handle == 0) {
    ESP_LOGW(TAG, "notify_handle == 0. ¿Se inicializó la característica?");
    return;
  }

  struct os_mbuf *om = ble_hs_mbuf_from_flat(data, len);
  if (!om) {
    ESP_LOGE(TAG, "Fallo creando mbuf para notificación binaria");
    return;
  }

  int rc = ble_gattc_notify_custom(g_conn_handle, notify_handle, om);
  if (rc != 0) {
    ESP_LOGE(TAG, "Error enviando notificación binaria rc=%d", rc);
  }
}

