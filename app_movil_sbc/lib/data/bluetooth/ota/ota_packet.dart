class OtaPacket {
  final int sequence;
  final List<int> data;

  OtaPacket({
    required this.sequence,
    required this.data,
  });
}
