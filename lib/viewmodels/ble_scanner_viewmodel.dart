import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ble_device.dart';

enum BleState { idle, scanning, error, noPermission, bluetoothOff }

class BleScannerViewModel extends ChangeNotifier {
  final List<BleDevice> _devices = [];
  BleState _state = BleState.idle;
  String _errorMessage = '';
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  // Getters
  List<BleDevice> get devices => _devices;
  BleState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isScanning => _isScanning;

  // Get only Nordic devices
  // List<BleDevice> get nordicDevices =>
  //     _devices.where((device) => device.isNordic).toList();

  // Get only Evolv28 devices
  List<BleDevice> get evolv28Devices => _devices
      .where((device) => device.name.toLowerCase().contains('evolv28'))
      .toList();

  // List<BleDevice> get nordicDevices => _devices.toList();

  BleScannerViewModel() {
    _initializeBluetooth();
  }

  void _initializeBluetooth() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _setState(BleState.idle);
      } else {
        _setState(BleState.bluetoothOff);
      }
    });
  }

  Future<void> requestPermissions() async {
    try {
      // Request location permission (required for BLE scanning on Android)
      final locationStatus = await Permission.location.request();

      if (locationStatus.isGranted) {
        _setState(BleState.idle);
      } else {
        _setState(BleState.noPermission);
        _errorMessage = 'Required permissions not granted';
      }
    } catch (e) {
      _setState(BleState.error);
      _errorMessage = 'Error requesting permissions: $e';
    }
  }

  Future<void> startScan({bool clearDevices = true}) async {
    if (_isScanning) return;

    try {
      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        _setState(BleState.bluetoothOff);
        _errorMessage = 'Bluetooth is turned off';
        return;
      }

      // Check permissions
      if (!await _hasRequiredPermissions()) {
        await requestPermissions();
        return;
      }

      _setState(BleState.scanning);
      _isScanning = true;

      // Only clear devices if explicitly requested
      if (clearDevices) {
        _devices.clear();
      }

      notifyListeners();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      // Stop scanning after timeout
      Timer(const Duration(seconds: 10), () {
        stopScan();
      });
    } catch (e) {
      _setState(BleState.error);
      _errorMessage = 'Error starting scan: $e';
      _isScanning = false;
    }
  }

  /// Refresh scan without clearing existing devices
  Future<void> refreshScan() async {
    if (_isScanning) {
      stopScan();
    }
    await startScan(clearDevices: false);
  }

  void stopScan() {
    if (!_isScanning) return;

    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    _isScanning = false;

    if (_devices.isNotEmpty) {
      _setState(BleState.idle);
    } else {
      _setState(BleState.idle);
    }
  }

  void _processScanResults(List<ScanResult> results) {
    for (final result in results) {
      final bleDevice = BleDevice.fromScanResult(result);

      // Check if device already exists
      final existingIndex = _devices.indexWhere((d) => d.id == bleDevice.id);

      if (existingIndex >= 0) {
        // Update existing device with new scan result
        final existingDevice = _devices[existingIndex];
        final updatedScanResults = [...existingDevice.scanResults, result];
        _devices[existingIndex] = existingDevice.copyWith(
          rssi: result.rssi,
          scanResults: updatedScanResults,
        );
      } else {
        // Add new device
        _devices.add(bleDevice);
      }
    }

    // Sort devices by RSSI (strongest signal first)
    _devices.sort((a, b) => b.rssi.compareTo(a.rssi));

    notifyListeners();
  }

  Future<bool> _hasRequiredPermissions() async {
    return await Permission.location.isGranted;
  }

  void _setState(BleState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_state == BleState.error) {
      _setState(BleState.idle);
    }
  }

  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    super.dispose();
  }
}
