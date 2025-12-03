#include "ota_gatt.h"

#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "esp_system.h"

#include "host/ble_hs.h"
#include "os/os_mbuf.h"
#include <string.h>

static const char *TAG = "OTA_GATT";

/* OTA commands */
#define OTA_CMD_BEGIN   0x01
#define OTA_CMD_END     0x02
#define OTA_CMD_ABORT   0x03

static esp_ota_handle_t s_ota_handle = 0;
static const esp_partition_t *s_ota_partition = NULL;
static bool s_ota_in_progress = false;

/* UUIDs OTA (elige tus propios UUIDs si quieres) */
#define OTA_SERVICE_UUID     BLE_UUID128_DECLARE(0xAA,0x01,0x00,0x00,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA)
#define OTA_CTRL_UUID        BLE_UUID128_DECLARE(0xAA,0x02,0x00,0x00,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA)
#define OTA_DATA_UUID        BLE_UUID128_DECLARE(0xAA,0x03,0x00,0x00,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA,0xAA)

/* Forward */
static int ota_ctrl_cb(uint16_t conn_handle, uint16_t attr_handle,
                       struct ble_gatt_access_ctxt *ctxt, void *arg);
static int ota_data_cb(uint16_t conn_handle, uint16_t attr_handle,
                       struct ble_gatt_access_ctxt *ctxt, void *arg);

/* Service definition */
static const struct ble_gatt_svc_def ota_svc[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = OTA_SERVICE_UUID,
        .characteristics = (struct ble_gatt_chr_def[]) {
            {   // control (write with response)
                .uuid = OTA_CTRL_UUID,
                .access_cb = ota_ctrl_cb,
                .flags = BLE_GATT_CHR_F_WRITE,
            },
            {   // data (write without response allowed)
                .uuid = OTA_DATA_UUID,
                .access_cb = ota_data_cb,
                .flags = BLE_GATT_CHR_F_WRITE | BLE_GATT_CHR_F_WRITE_NO_RSP,
            },
            { 0 }
        }
    },
    { 0 }
};

static int ota_ctrl_cb(uint16_t conn_handle, uint16_t attr_handle,
                       struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    int len = OS_MBUF_PKTLEN(ctxt->om);
    if (len <= 0) return 0;

    uint8_t cmd = 0;
    os_mbuf_copydata(ctxt->om, 0, 1, &cmd);

    switch (cmd) {
        case OTA_CMD_BEGIN:
            ESP_LOGI(TAG, "OTA_CMD_BEGIN received");
            if (s_ota_in_progress) {
                ESP_LOGW(TAG, "OTA already in progress; aborting previous");
                esp_ota_abort(s_ota_handle);
                s_ota_in_progress = false;
                s_ota_handle = 0;
            }
            s_ota_partition = esp_ota_get_next_update_partition(NULL);
            if (!s_ota_partition) {
                ESP_LOGE(TAG, "No OTA partition found");
                return BLE_ATT_ERR_UNLIKELY;
            }
            esp_err_t err = esp_ota_begin(s_ota_partition, OTA_SIZE_UNKNOWN, &s_ota_handle);
            if (err != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_begin failed: %s", esp_err_to_name(err));
                return BLE_ATT_ERR_UNLIKELY;
            }
            s_ota_in_progress = true;
            ESP_LOGI(TAG, "OTA begin ok; writing to partition %s", s_ota_partition->label);
            break;

        case OTA_CMD_END:
            ESP_LOGI(TAG, "OTA_CMD_END received");
            if (!s_ota_in_progress) {
                ESP_LOGW(TAG, "No OTA in progress");
                return BLE_ATT_ERR_UNLIKELY;
            }
            if (esp_ota_end(s_ota_handle) != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_end failed");
                s_ota_in_progress = false;
                s_ota_handle = 0;
                return BLE_ATT_ERR_UNLIKELY;
            }
            if (esp_ota_set_boot_partition(s_ota_partition) != ESP_OK) {
                ESP_LOGE(TAG, "esp_ota_set_boot_partition failed");
                return BLE_ATT_ERR_UNLIKELY;
            }
            ESP_LOGI(TAG, "OTA image set as boot partition; rebooting...");
            esp_restart();
            break;

        case OTA_CMD_ABORT:
            ESP_LOGW(TAG, "OTA_CMD_ABORT received");
            if (s_ota_in_progress) {
                esp_ota_abort(s_ota_handle);
                s_ota_in_progress = false;
                s_ota_handle = 0;
            }
            break;

        default:
            ESP_LOGW(TAG, "Unknown OTA command: 0x%02x", cmd);
            break;
    }

    return 0;
}

static int ota_data_cb(uint16_t conn_handle, uint16_t attr_handle,
                       struct ble_gatt_access_ctxt *ctxt, void *arg)
{
    if (!s_ota_in_progress) {
        ESP_LOGW(TAG, "OTA data received but no OTA in progress");
        return BLE_ATT_ERR_UNLIKELY;
    }

    int len = OS_MBUF_PKTLEN(ctxt->om);
    if (len <= 0) return 0;

    /* Limitar copia a buffer temporal razonable */
    uint8_t tmp[512];
    if (len > (int)sizeof(tmp)) len = sizeof(tmp);

    os_mbuf_copydata(ctxt->om, 0, len, tmp);

    esp_err_t err = esp_ota_write(s_ota_handle, tmp, len);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_ota_write failed: %s", esp_err_to_name(err));
        return BLE_ATT_ERR_UNLIKELY;
    }

    return 0;
}

void ota_gatt_init(void) {
    ESP_LOGI(TAG, "Registering OTA GATT service...");
    ble_gatts_count_cfg(ota_svc);
    ble_gatts_add_svcs(ota_svc);
}

