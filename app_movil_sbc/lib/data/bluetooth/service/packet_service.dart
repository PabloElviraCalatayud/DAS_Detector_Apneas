import 'dart:async';
import '../codec/ble_packet.dart';
import '../manager/ble_manager.dart';
import '../../models/sensor_data_model.dart';

class PacketService {
  PacketService._internal();
  static final PacketService instance = PacketService._internal();

  StreamSubscription<BlePacket>? _sub;

  void start() {
    stop();
    _sub = BleManager.instance.packetStream.listen(_onPacket);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onPacket(BlePacket pkt) {
    SensorDataModel.instance.process(pkt);
  }
}
