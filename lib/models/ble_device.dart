import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDevice {
  final BluetoothDevice device;
  final String name;
  final String id;
  final int rssi;
  final bool isEvolv28;
  final List<ScanResult> scanResults;
  final DateTime discoveredAt;

  BleDevice({
    required this.device,
    required this.name,
    required this.id,
    required this.rssi,
    required this.isEvolv28,
    required this.scanResults,
    required this.discoveredAt,
  });

  factory BleDevice.fromScanResult(ScanResult result) {
    final device = result.device;
    final name = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.toString();

    // Check if it's a Nordic device based on name patterns and manufacturer data
    bool isEvolv28 = _isNordicDevice(name, result.advertisementData);

    return BleDevice(
      device: device,
      name: name,
      id: device.remoteId.toString(),
      rssi: result.rssi,
      isEvolv28: isEvolv28,
      scanResults: [result],
      discoveredAt: DateTime.now(),
    );
  }

  static bool _isNordicDevice(
    String name,
    AdvertisementData advertisementData,
  ) {
    // Nordic devices often have names starting with specific patterns
    final nordicNamePatterns = ['evolv28'];

    // Check name patterns
    for (final pattern in nordicNamePatterns) {
      if (name.toUpperCase().contains(pattern.toUpperCase())) {
        return true;
      }
    }

    // Check manufacturer data for Nordic's company identifier (0x0059)
    if (advertisementData.manufacturerData.isNotEmpty) {
      // Nordic's company identifier is 0x0059 (89 in decimal)
      if (advertisementData.manufacturerData.keys.contains(89)) {
        return true;
      }
    }

    return false;
  }

  BleDevice copyWith({
    BluetoothDevice? device,
    String? name,
    String? id,
    int? rssi,
    bool? isEvolv28,
    List<ScanResult>? scanResults,
    DateTime? discoveredAt,
  }) {
    return BleDevice(
      device: device ?? this.device,
      name: name ?? this.name,
      id: id ?? this.id,
      rssi: rssi ?? this.rssi,
      isEvolv28: isEvolv28 ?? this.isEvolv28,
      scanResults: scanResults ?? this.scanResults,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BleDevice(name: $name, id: $id, rssi: $rssi, isEvolv28: $isEvolv28)';
  }
}
