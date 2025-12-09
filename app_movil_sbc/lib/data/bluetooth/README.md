# 📡 Bluetooth Module – Architecture Brief

Este documento describe la arquitectura del módulo Bluetooth en la aplicación, 
organizado por capas y responsabilidades para garantizar modularidad, testabilidad y mantenimiento a largo plazo.

---

## api/

### **`ble_client.dart`**
Fachada de alto nivel usada por el resto de la app.

Responsabilidades:
- Exponer una API simple: escaneo, conexión, desconexión y envío de datos.
- Proveer streams ya procesados: paquetes decodificados, estado de conexión, etc.
- Aislar a la UI y a los servicios de los detalles internos del módulo BLE.

### **`ble_exceptions.dart`**
Errores específicos del módulo BLE:

- Fallos de conexión
- Problemas de permisos
- Errores de escritura/lectura
- Errores de formato de paquete

---

## connection/

### **`ble_connection.dart`**
Capa de bajo nivel que interactúa directamente con `flutter_reactive_ble`.

Responsabilidades:
- Conectar y desconectar dispositivos.
- Gestionar notificaciones BLE.
- Solicitar y configurar MTU.
- Enviar datos (texto o binario).
- Emitir un stream de fragmentos reconstruidos mediante el *reassembler*.

Limitaciones:
- **No** decodifica paquetes.
- **No** interpreta datos de sensores.

### **`ble_packet_reassembler.dart`**
Reconstruye paquetes completos a partir de fragmentos BLE.

Responsabilidades:
- Recibir fragmentos BLE (por ejemplo, notificaciones parciales).
- Ensamblar paquetes completos y válidos (`Uint8List`).
- Verificar tamaños y límites.
- Emitir paquetes reconstruidos listos para decodificar.

Características:
- Totalmente independiente.
- Altamente testeable.
- No interpreta contenido del paquete.

---

## codec/

### **`ble_packet.dart`**
Modelos de datos del protocolo BLE.

Incluye:
- `ImuSample`
- `BlePacket` con `fromBytes`
- Funciones para leer enteros little-endian.
- Conversión de escalas a valores físicos.

Independencia:
- No depende de BLE ni de la capa de conexión.

### **`ble_decoder.dart`**
Convierte datos binarios (`Uint8List`) en modelos `BlePacket`.

Responsabilidades:
- Manejar errores de formato.
- Abstraer variaciones en versiones del protocolo.
- Separar completamente la lógica de parseo del resto del sistema.

---

## manager/

### **`ble_manager.dart`**
Capa intermedia que coordina todo el flujo BLE.

Responsabilidades:
- Orquestar escaneo, conexión y desconexión.
- Conectarse internamente a `BleConnection`.
- Escuchar paquetes crudos reconstruidos.
- Decodificar paquetes mediante `BleDecoder`.
- Emitir un stream de `BlePacket` ya interpretados.
- Exponer un estado de conexión simple para la UI.

Limitaciones:
- No procesa lógica de negocio.
- No altera modelos de dominio de sensores.

### **`ble_permissions.dart`**
Gestiona permisos requeridos para BLE:

- Bluetooth
- Ubicación (Android)
- Escaneo y conexión

---

## service/

### **`packet_service.dart`**
Capa de negocio que consume `BlePacket`.

Responsabilidades:
- Transformar paquetes BLE en modelos de dominio (ej. `SensorDataModel`).
- Interpretar contexto de sensores: IMU, FSR, pulso, eventos, etc.
- Aislar la lógica de la app del protocolo BLE.

---

## utilidades

### **`ble_constants.dart`**
Constantes BLE del proyecto:

- UUID de servicios
- UUID de características
- Versiones del protocolo
- Nombres y valores por defecto

---

