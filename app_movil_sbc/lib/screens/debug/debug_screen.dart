import 'package:flutter/material.dart';

import '../../data/bluetooth/codec/ble_packet.dart';
import '../../data/bluetooth/service/packet_service.dart';
import '../../data/models/sensor_data_model.dart';
import '../../common/widgets/Apnea/ApneaDetector.dart';

class DebugScreen extends StatefulWidget {
  final Stream<BlePacket> packetStream;

  const DebugScreen({
    super.key,
    required this.packetStream,
  });

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  ImuSample? lastImu;
  List<int> lastPulses = [];

  final ApneaDetector _detector = ApneaDetector.instance;

  @override
  void initState() {
    super.initState();

    PacketService.instance.start();
    _detector.initialize();

    widget.packetStream.listen((packet) {
      if (!mounted) return;

      setState(() {
        if (packet.imuSamples.isNotEmpty) {
          lastImu = packet.imuSamples.first;
        }
        lastPulses = packet.pulses;
      });
    });

    // 🔄 refresco cuando cambian cálculos internos
    _detector.apneaEventsStream.listen((_) {
      if (mounted) setState(() {});
    });

    SensorDataModel.instance.dataStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  // --------------------------------------------------
  // UI HELPERS
  // --------------------------------------------------
  Widget _buildCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
            color: scheme.onSurface.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final model = SensorDataModel.instance;
    final snap = model.lastData;
    final imu = lastImu;

    final movementIndex = snap?.movementIndex ?? 0.0;
    final heartRate = snap?.heartRate ?? 0;

    final eventsTotal = _detector.totalEvents;
    final eventsPerHour = _detector.eventsPerHour();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Debug Sensores',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --------------------------------------------------
            // BLE RAW
            // --------------------------------------------------
            _buildCard(
              context: context,
              title: "Pulsos BLE (Brutos del paquete)",
              children: [
                _buildDataRow(
                  context,
                  "Último pulso",
                  lastPulses.isNotEmpty ? lastPulses.last.toString() : "—",
                ),
                _buildDataRow(
                  context,
                  "Pulsos en paquete",
                  lastPulses.length.toString(),
                ),
                Text(
                  lastPulses.isNotEmpty ? lastPulses.join(", ") : "—",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            // --------------------------------------------------
            // IMU
            // --------------------------------------------------
            if (imu != null)
              _buildCard(
                context: context,
                title: "IMU (Acelerómetro)",
                children: [
                  _buildDataRow(context, "ax", imu.ax.toStringAsFixed(3)),
                  _buildDataRow(context, "ay", imu.ay.toStringAsFixed(3)),
                  _buildDataRow(context, "az", imu.az.toStringAsFixed(3)),
                ],
              ),

            if (imu != null)
              _buildCard(
                context: context,
                title: "IMU (Giroscopio)",
                children: [
                  _buildDataRow(context, "gx", imu.gx.toStringAsFixed(3)),
                  _buildDataRow(context, "gy", imu.gy.toStringAsFixed(3)),
                  _buildDataRow(context, "gz", imu.gz.toStringAsFixed(3)),
                ],
              ),

            // --------------------------------------------------
            // SENSOR DATA MODEL (PROCESADO)
            // --------------------------------------------------
            _buildCard(
              context: context,
              title: "SensorDataModel (Procesado)",
              children: [
                _buildDataRow(
                  context,
                  "Timestamp",
                  snap?.timestamp.toString() ?? "—",
                ),
                _buildDataRow(
                  context,
                  "HeartRate",
                  heartRate.toString(),
                ),
                const SizedBox(height: 12),
                _buildDataRow(
                  context,
                  "movementIndex",
                  movementIndex.toStringAsFixed(3),
                ),
              ],
            ),

            // --------------------------------------------------
            // APNEA
            // --------------------------------------------------
            _buildCard(
              context: context,
              title: "Apneas",
              children: [
                _buildDataRow(
                  context,
                  "Eventos totales",
                  eventsTotal.toString(),
                ),
                _buildDataRow(
                  context,
                  "Eventos por hora (AHI)",
                  eventsPerHour.toStringAsFixed(2),
                ),
              ],
            ),

            // --------------------------------------------------
            // HISTÓRICO POR HORAS
            // --------------------------------------------------
            _buildCard(
              context: context,
              title: "Actividad por horas",
              children: model.hourlyHistory.isEmpty
                  ? [
                const Text("Sin datos aún"),
              ]
                  : model.hourlyHistory.map((h) {
                final hour = DateTime
                    .fromMillisecondsSinceEpoch(h.hourTimestamp)
                    .hour;
                return _buildDataRow(
                  context,
                  "Hora $hour",
                  h.average.toStringAsFixed(3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
