import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum CommunicationState { idle, sending, waiting, completed, error }

class CommandResponse {
  final String command;
  final String response;
  final DateTime timestamp;
  final bool isSuccess;

  CommandResponse({
    required this.command,
    required this.response,
    required this.timestamp,
    required this.isSuccess,
  });
}

class ConnectedDeviceViewModel extends ChangeNotifier {
  final BluetoothDevice device;
  final String deviceName;

  List<CommandResponse> _commandResponses = [];
  CommunicationState _state = CommunicationState.idle;
  String _errorMessage = '';
  bool _isConnected = false;

  // Nordic UART Service UUIDs
  static const String nordicUartServiceUUID =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartWriteCharacteristicUUID =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String nordicUartNotifyCharacteristicUUID =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // Commands to send
  static const List<String> commands = [
    '#GET_MAC_ID!',
    '#BSV!',
    '#GM!',
    '7#GFL,5!',
    '5#SPL!',
  ];

  BluetoothService? _uartService;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;

  // Getters
  List<CommandResponse> get commandResponses => _commandResponses;
  CommunicationState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  bool get hasCompletedAllCommands =>
      _commandResponses.length == commands.length;

  ConnectedDeviceViewModel({required this.device, required this.deviceName}) {
    _initializeConnection();
  }

  Future<void> _initializeConnection() async {
    try {
      _setState(CommunicationState.idle);

      // Check if device is connected
      if (!device.isConnected) {
        await device.connect(timeout: const Duration(seconds: 10));
      }

      _isConnected = true;
      notifyListeners();

      // Discover services
      final services = await device.discoverServices();

      // Find Nordic UART service
      _uartService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() ==
            nordicUartServiceUUID.toLowerCase(),
        orElse: () => throw Exception('Nordic UART service not found'),
      );

      // Find write and notify characteristics
      _writeCharacteristic = _uartService!.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            nordicUartWriteCharacteristicUUID.toLowerCase(),
        orElse: () => throw Exception('Write characteristic not found'),
      );

      _notifyCharacteristic = _uartService!.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toLowerCase() ==
            nordicUartNotifyCharacteristicUUID.toLowerCase(),
        orElse: () => throw Exception('Notify characteristic not found'),
      );

      // Enable notifications
      await _notifyCharacteristic!.setNotifyValue(true);

      // Listen to notifications
      _notificationSubscription = _notifyCharacteristic!.lastValueStream.listen(
        (value) => _handleNotification(value),
        onError: (error) => _handleError('Notification error: $error'),
      );

      _setState(CommunicationState.idle);
    } catch (e) {
      _handleError('Connection error: $e');
    }
  }

  Future<void> writeCommand(String command) async {
    try {
      final commandData = command.codeUnits;
      return await _writeCharacteristic!.write(
        commandData,
        withoutResponse: false,
        allowLongWrite: true,
      );
    } catch (e) {
      _handleError('Write characteristic error: $e');
      return;
    }
  }

  Future<void> startCommandSequence() async {
    if (_state != CommunicationState.idle || !_isConnected) {
      return;
    }

    try {
      _commandResponses.clear();
      _setState(CommunicationState.sending);
      notifyListeners();

      for (int i = 0; i < commands.length; i++) {
        final command = commands[i];

        // Update state to show which command is being sent
        _setState(CommunicationState.sending);
        notifyListeners();

        // Send command
        await writeCommand(command);

        // Wait for response
        _setState(CommunicationState.waiting);
        notifyListeners();

        // Wait for response with timeout
        final response = await _waitForResponse(
          timeout: const Duration(seconds: 10),
        );

        // Add command response
        _commandResponses.add(
          CommandResponse(
            command: command,
            response: response,
            timestamp: DateTime.now(),
            isSuccess: response.isNotEmpty,
          ),
        );

        notifyListeners();

        // Small delay between commands
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _setState(CommunicationState.completed);
    } catch (e) {
      _handleError('Command sequence error: $e');
    }
  }

  Future<String> _waitForResponse({required Duration timeout}) async {
    final completer = Completer<String>();
    Timer? timeoutTimer;
    String? lastResponse;

    // Set timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(lastResponse ?? 'Timeout - No response received');
      }
    });

    // Listen for next notification
    if (_notifyCharacteristic != null) {
      final subscription = _notifyCharacteristic!.lastValueStream.listen(
        (value) {
          if (!completer.isCompleted) {
            lastResponse = String.fromCharCodes(value);
            completer.complete(lastResponse!);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete('Error: $error');
          }
        },
      );

      final response = await completer.future;
      timeoutTimer.cancel();
      subscription.cancel();

      return response;
    } else {
      timeoutTimer.cancel();
      return 'Error: Notify characteristic not available';
    }
  }

  void _handleNotification(List<int> value) {
    // This will be handled by the specific waitForResponse calls
    final stringValue = String.fromCharCodes(value);
    print('=== NOTIFICATION RECEIVED ===');
    print('Raw bytes: $value');
    print('As string: "$stringValue"');
    print('Length: ${value.length}');
    print('=============================');
  }

  void _handleError(String error) {
    _errorMessage = error;
    _setState(CommunicationState.error);
  }

  void _setState(CommunicationState newState) {
    _state = newState;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    if (_state == CommunicationState.error) {
      _setState(CommunicationState.idle);
    }
  }

  void resetCommandSequence() {
    _commandResponses.clear();
    _setState(CommunicationState.idle);
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      _notificationSubscription?.cancel();
      if (device.isConnected) {
        await device.disconnect();
      }
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      _handleError('Disconnect error: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
