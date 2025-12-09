import 'dart:async';

import '../data/bluetooth/ble_manager.dart';
import '../data/bluetooth/codec/ble_packet.dart';
import '../data/models/sensor_data_model.dart';


class PacketService {
  PacketService._internal();
  static final PacketService instance = PacketService._internal();

  StreamSubscription<BlePacket>? _pktSub;

  void start() {
    stop();
    _pktSub = BleManager.instance.packetStream.listen(_onPacket);
  }

  void stop() {
    _pktSub?.cancel();
    _pktSub = null;
  }

  void _onPacket(BlePacket pkt) {
    final model = SensorDataModel.instance;
    model.process(pkt);
  }
}
