// lib/data/bluetooth/ble_packet.dart

/// Representa una muestra IMU compacta.
/// Los valores llegan multiplicados x100 desde el ESP32.
class ImuSample {
  final int ax; // accel X * 100
  final int ay; // accel Y * 100
  final int az; // accel Z * 100
  final int gx; // gyro X * 100
  final int gy; // gyro Y * 100
  final int gz; // gyro Z * 100

  ImuSample({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  /// Devuelve aceleraciones reales (m/s²)
  double get axReal => ax / 100.0;
  double get ayReal => ay / 100.0;
  double get azReal => az / 100.0;

  /// Devuelve giros reales (°/s)
  double get gxReal => gx / 100.0;
  double get gyReal => gy / 100.0;
  double get gzReal => gz / 100.0;

  @override
  String toString() =>
      'IMU(ax:$ax ay:$ay az:$az  gx:$gx gy:$gy gz:$gz)';
}

/// Representa un paquete BLE compacto enviado por el ESP32.
class BlePacket {
  final int flags;      // Bits que indican IMU/Pulse
  final int timestamp;  // ms (uint64 truncado a int en Flutter)
  final int imuCount;
  final int pulseCount;

  final List<ImuSample> imu;
  final List<int> pulses; // Pulsos (uint16)

  BlePacket({
    required this.flags,
    required this.timestamp,
    required this.imuCount,
    required this.pulseCount,
    required this.imu,
    required this.pulses,
  });

  /// Hay datos IMU en este paquete
  bool get hasImu => imuCount > 0 && imu.isNotEmpty;

  /// Hay datos de pulso
  bool get hasPulse => pulseCount > 0 && pulses.isNotEmpty;

  /// Primer valor de pulso (útil para widgets)
  int? get firstPulse => hasPulse ? pulses.first : null;

  /// Primera muestra IMU
  ImuSample? get firstImu => hasImu ? imu.first : null;

  @override
  String toString() {
    return 'BlePacket('
        'flags:0x${flags.toRadixString(16)}, '
        'ts:$timestamp, '
        'imuCount:$imuCount, '
        'pulseCount:$pulseCount, '
        'imu:$imu, '
        'pulses:$pulses'
        ')';
  }
}
