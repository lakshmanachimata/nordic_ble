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
  List<CommandResponse> _playCommandResponses = [];
  CommunicationState _state = CommunicationState.idle;
  String _errorMessage = '';
  bool _isConnected = false;

  // Add tracking for 5th command responses
  List<String> _fifthCommandResponses = [];
  bool _isWaitingForFifthCommand = false;

  // Add tracking for play commands
  bool _isSendingPlayCommands = false;
  String _selectedBcuFile = 'Uplift_Mood.bcu'; // Default file
  List<String> _availableBcuFiles = [];
  
  // Callback for when files are ready to be selected
  Function()? onFilesReady;

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
    '#ESP32DIS!',
    '#BSV!',
    '#GM!',
    '7#GFL,5!',
    '5#SPL!',
  ];

  static const playCommands = [
    '#BSV!',
    '5#STP!',
    '5#CPS!',
    '#PS,1,Uplift_Mood.bcu,48,5.0,4,10!',
    '#ST,20250901125237!',
    '#GAIN,27!',
    '24#PL,3341,20250901125238,!',
    '5#SPL!',
  ];

  BluetoothService? _uartService;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;

  // Getters
  List<CommandResponse> get commandResponses => _commandResponses;
  List<CommandResponse> get playCommandResponses => _playCommandResponses;
  CommunicationState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  bool get hasCompletedAllCommands =>
      _commandResponses.length == commands.length;
  bool get isSendingPlayCommands => _isSendingPlayCommands;
  List<String> get availableBcuFiles => _availableBcuFiles;
  String get selectedBcuFile => _selectedBcuFile;

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
      _playCommandResponses.clear();
      _fifthCommandResponses.clear(); // Clear previous 5th command responses
      _setState(CommunicationState.sending);
      notifyListeners();

      for (int i = 0; i < commands.length; i++) {
        final command = commands[i];

        // Update state to show which command is being sent
        _setState(CommunicationState.sending);
        notifyListeners();

        // Set flag for 5th command
        if (i == 4) {
          _isWaitingForFifthCommand = true;
          _fifthCommandResponses.clear();
        } else {
          _isWaitingForFifthCommand = false;
        }

        // Send command
        await writeCommand(command);

        // Wait for response
        _setState(CommunicationState.waiting);
        notifyListeners();

        // Wait for response with timeout, pass command index for special handling
        final response = await _waitForResponse(
          timeout: const Duration(seconds: 10),
          commandIndex: i,
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

        // Clear flag after processing
        _isWaitingForFifthCommand = false;

        notifyListeners();

        // Small delay between commands
        await Future.delayed(const Duration(milliseconds: 500));

        // Special delay for 9th command (5 seconds)
        if (i == 8) {
          print('Waiting 5 seconds before sending 9th command...');
          await Future.delayed(const Duration(seconds: 5));
        }
      }

      _setState(CommunicationState.completed);
      
      // Parse the 7#GFL,5! response to extract .bcu files
      await _parseBcuFilesFromResponse();
      
      // Wait 5 seconds before sending play commands
      print('Waiting 5 seconds before sending play commands...');
      await Future.delayed(const Duration(seconds: 5));
      
      // Send play commands
      await _sendPlayCommands();
    } catch (e) {
      _handleError('Command sequence error: $e');
    }
  }

  Future<void> _parseBcuFilesFromResponse() async {
    try {
      // Find the 7#GFL,5! command response (5th command, index 4)
      if (_commandResponses.length > 4) {
        final gflResponse = _commandResponses[4].response;
        print('=== PARSING GFL RESPONSE ===');
        print('Full response: $gflResponse');
        print('Response length: ${gflResponse.length}');
        
        // Extract .bcu files from the response
        final lines = gflResponse.split('\n');
        _availableBcuFiles.clear();
        
        print('Split into ${lines.length} lines:');
        for (int i = 0; i < lines.length; i++) {
          print('Line $i: "${lines[i]}"');
        }
        
        // Strategy 0: Handle common file listing formats
        // Look for patterns like:
        // - "file1.bcu file2.bcu file3.bcu"
        // - "file1.bcu,file2.bcu,file3.bcu"
        // - "file1.bcu\nfile2.bcu\nfile3.bcu"
        // - "Files: file1.bcu file2.bcu file3.bcu"
        // - "Available files: file1.bcu, file2.bcu, file3.bcu"
        
        // First, try to find a line that contains multiple .bcu files
        String? multiFileLine;
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.toLowerCase().contains('.bcu')) {
            // Count how many .bcu files are in this line
            final bcuCount = '.bcu'.allMatches(trimmedLine.toLowerCase()).length;
            if (bcuCount > 1) {
              multiFileLine = trimmedLine;
              print('Found multi-file line: $multiFileLine');
              break;
            }
          }
        }
        
        if (multiFileLine != null) {
          // Extract all .bcu files from this line
          RegExp multiFilePattern = RegExp(r'([a-zA-Z0-9_\-\.]+\.bcu)', caseSensitive: false);
          final matches = multiFilePattern.allMatches(multiFileLine);
          for (final match in matches) {
            String filename = match.group(1) ?? '';
            if (filename.isNotEmpty) {
              _availableBcuFiles.add(filename);
              print('Multi-file strategy - Found filename: $filename');
            }
          }
        }
        
        // Simplified and more robust parsing approach
        for (final line in lines) {
          final trimmedLine = line.trim();
          print('Checking line: "$trimmedLine"');
          
          if (trimmedLine.toLowerCase().contains('.bcu')) {
            print('Found .bcu in line: $trimmedLine');
            
            // Use a comprehensive regex to find all .bcu filenames
            RegExp bcuPattern = RegExp(r'([a-zA-Z0-9_\-\.]+\.bcu)', caseSensitive: false);
            final matches = bcuPattern.allMatches(trimmedLine);
            
            for (final match in matches) {
              String filename = match.group(1) ?? '';
              if (filename.isNotEmpty && filename.length > 4) {
                // Clean up any trailing punctuation
                filename = filename.replaceAll(RegExp(r'[,;:\s]+$'), '');
                if (filename.toLowerCase().endsWith('.bcu')) {
                  _availableBcuFiles.add(filename);
                  print('Found and added filename: $filename');
                }
              }
            }
          }
        }
        
        // Strategy 5: If we still haven't found files, try a more aggressive approach
        if (_availableBcuFiles.isEmpty) {
          print('No files found with previous strategies, trying aggressive parsing...');
          
          // Look for any string that ends with .bcu anywhere in the response
          RegExp aggressivePattern = RegExp(r'([a-zA-Z0-9_\-\.]+\.bcu)', caseSensitive: false);
          final allMatches = aggressivePattern.allMatches(gflResponse);
          for (final match in allMatches) {
            String filename = match.group(1) ?? '';
            if (filename.isNotEmpty && filename.length > 4) {
              _availableBcuFiles.add(filename);
              print('Aggressive strategy - Found filename: $filename');
            }
          }
        }
        
        // Remove duplicates and sort
        _availableBcuFiles = _availableBcuFiles.toSet().toList()..sort();
        
        print('=== FINAL RESULT ===');
        print('Found ${_availableBcuFiles.length} .bcu files: $_availableBcuFiles');
        
        // If we found files, use the first one as default
        if (_availableBcuFiles.isNotEmpty) {
          _selectedBcuFile = _availableBcuFiles.first;
          print('Selected file: $_selectedBcuFile');
          // Trigger callback to show file selection popup
          print('Triggering onFilesReady callback...');
          onFilesReady?.call();
        } else {
          print('No .bcu files found, using default: $_selectedBcuFile');
          // Don't show popup if no files are found
        }
        
        notifyListeners();
      } else {
        print('Not enough command responses yet (${_commandResponses.length})');
      }
    } catch (e) {
      print('Error parsing BCU files: $e');
      // Keep default file if parsing fails
    }
  }

  void selectBcuFile(String filename) {
    _selectedBcuFile = filename;
    notifyListeners();
  }

  Future<void> _sendPlayCommands() async {
    try {
      _isSendingPlayCommands = true;
      _setState(CommunicationState.sending);
      notifyListeners();

      // Generate current timestamp for #ST command
      final now = DateTime.now();
      final timestamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      // Generate timestamp for 24#PL command (1 second later)
      final plTimestamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${(now.second + 1).toString().padLeft(2, '0')}';

      // Create dynamic play commands
      final dynamicPlayCommands = [
        '#BSV!',
        '5#STP!',
        '5#CPS!',
        '#PS,1,$_selectedBcuFile,48,5.0,4,10!',
        '#ST,$timestamp!',
        '#GAIN,27!',
        '24#PL,3341,$plTimestamp,!',
        '5#SPL!',
      ];

      for (int i = 0; i < dynamicPlayCommands.length; i++) {
        final command = dynamicPlayCommands[i];

        // Update state to show which play command is being sent
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
          commandIndex: null, // No special handling for play commands
        );

        // Add command response
        _playCommandResponses.add(
          CommandResponse(
            command: command,
            response: response,
            timestamp: DateTime.now(),
            isSuccess: response.isNotEmpty,
          ),
        );

        notifyListeners();

        // Special delay for #ST command - wait 1 second before sending 24#PL
        if (command.startsWith('#ST,')) {
          print('Waiting 1 second before sending 24#PL command...');
          await Future.delayed(const Duration(seconds: 1));
        } else {
          // Small delay between other commands
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _isSendingPlayCommands = false;
      _setState(CommunicationState.completed);
    } catch (e) {
      _isSendingPlayCommands = false;
      _handleError('Play commands error: $e');
    }
  }

  Future<String> _waitForResponse({
    required Duration timeout,
    int? commandIndex,
  }) async {
    final completer = Completer<String>();
    Timer? timeoutTimer;
    String? lastResponse;

    // Special handling for 5th command (7#GFL,5!) - accumulate all responses
    if (commandIndex == 4) {
      // 5th command (0-indexed)

      // Set timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          final fullResponse = _fifthCommandResponses.join('\n');
          completer.complete(
            fullResponse.isNotEmpty
                ? fullResponse
                : 'Timeout - No response received',
          );
        }
      });

      // For the 5th command, wait for the completion signal
      // The responses are being accumulated in _handleNotification
      while (!completer.isCompleted && _fifthCommandResponses.isNotEmpty) {
        // Check if we have received the completion signal
        if (_fifthCommandResponses.any(
          (response) => response.contains('#Completed!'),
        )) {
          // Wait a bit more to ensure all responses are collected
          await Future.delayed(const Duration(milliseconds: 500));
          final fullResponse = _fifthCommandResponses.join('\n');
          print(
            '5th command - Final response with ${_fifthCommandResponses.length} parts',
          );
          completer.complete(fullResponse);
          break;
        }

        // Wait a bit before checking again
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // If we haven't completed yet, use what we have
      if (!completer.isCompleted) {
        final fullResponse = _fifthCommandResponses.join('\n');
        completer.complete(
          fullResponse.isNotEmpty ? fullResponse : 'No responses received',
        );
      }
    } else {
      // Original behavior for other commands
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

    // Cancel timeout timer if it's still active
    timeoutTimer.cancel();

    return await completer.future;
  }

  void _handleNotification(List<int> value) {
    // This will be handled by the specific waitForResponse calls
    final stringValue = String.fromCharCodes(value);
    print('=== NOTIFICATION RECEIVED ===');
    print('Raw bytes: $value');
    print('As string: "$stringValue"');
    print('Length: ${value.length}');
    print('=============================');

    // If we're waiting for the 5th command, accumulate the response
    if (_isWaitingForFifthCommand) {
      _fifthCommandResponses.add(stringValue);
      print(
        '5th command - Accumulated response: "$stringValue" (Total: ${_fifthCommandResponses.length})',
      );
    }
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
    _playCommandResponses.clear();
    _availableBcuFiles.clear();
    _selectedBcuFile = 'Uplift_Mood.bcu'; // Reset to default
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
