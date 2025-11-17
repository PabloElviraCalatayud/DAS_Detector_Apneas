class BlePacket {
  final int flags;
  final int timestamp;

  final List<int> imuAx;
  final List<int> imuAy;
  final List<int> imuAz;
  final List<int> imuGx;
  final List<int> imuGy;
  final List<int> imuGz;

  final List<int> pulses;

  BlePacket({
    required this.flags,
    required this.timestamp,
    required this.imuAx,
    required this.imuAy,
    required this.imuAz,
    required this.imuGx,
    required this.imuGy,
    required this.imuGz,
    required this.pulses,
  });
}
