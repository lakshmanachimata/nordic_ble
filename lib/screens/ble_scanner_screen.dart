import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/ble_device.dart';
import '../theme/app_theme.dart';
import '../viewmodels/ble_scanner_viewmodel.dart';
import '../widgets/device_list_item.dart';
import 'connected_device_screen.dart';

// Nordic UART Service UUIDs
const String nordicUartServiceUUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String nordicUartWriteCharacteristicUUID =
    '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
const String nordicUartNotifyCharacteristicUUID =
    '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

class BleScannerScreen extends StatefulWidget {
  const BleScannerScreen({super.key});

  @override
  State<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends State<BleScannerScreen> {
  @override
  void initState() {
    super.initState();
    // Request permissions and start scanning automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndStartScan();
    });
  }

  Future<void> _requestPermissionsAndStartScan() async {
    try {
      // Get the view model first
      final viewModel = context.read<BleScannerViewModel>();
      
      // Request permissions first
      await viewModel.requestPermissions();
      
      // Start scanning after permissions are granted
      await viewModel.startScan();
    } catch (e) {
      print('Error in init: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBlue,
      appBar: AppBar(
        title: const Text('Evolv28'),
        backgroundColor: AppTheme.purpleHighlight,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: Consumer<BleScannerViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              const SizedBox(height: 8),
              // Nordic devices count
              if (viewModel.evolv28Devices.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.purpleLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.purpleHighlight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bluetooth_searching,
                        color: AppTheme.purpleHighlight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${viewModel.evolv28Devices.length} Evolv28 device${viewModel.evolv28Devices.length == 1 ? '' : 's'} found',
                        style: TextStyle(
                          color: AppTheme.purpleHighlight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Devices list
              Expanded(child: _buildDevicesList(viewModel)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDevicesList(BleScannerViewModel viewModel) {
    // Show error state if there's an error
    if (viewModel.state == BleState.error) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.evolv28Devices.isEmpty &&
        viewModel.state == BleState.scanning) {
      return _buildScanningShimmer();
    }

    // Always wrap with RefreshIndicator for iOS compatibility
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh scan without clearing existing devices
        await viewModel.refreshScan();
        // Wait a bit to show the refresh animation
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.purpleHighlight,
      backgroundColor: AppTheme.white,
      child: viewModel.evolv28Devices.isEmpty
          ? _buildEmptyStateWithRefresh()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: viewModel.evolv28Devices.length,
              itemBuilder: (context, index) {
                final device = viewModel.evolv28Devices[index];
                return DeviceListItem(
                  device: device,
                  onTap: () => _connectAndDiscoverServices(device),
                );
              },
            ),
    );
  }

  Widget _buildErrorState(BleScannerViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.refreshScan();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error occurred',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.startScan();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purpleHighlight,
                      foregroundColor: AppTheme.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningShimmer() {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh scan when pulling to refresh during scanning
        final viewModel = context.read<BleScannerViewModel>();
        await viewModel.refreshScan();
      },
      color: AppTheme.purpleHighlight,
      backgroundColor: AppTheme.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppTheme.lightBlue,
            highlightColor: AppTheme.white,
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.lightBlue,
                  child: Icon(Icons.bluetooth, color: AppTheme.blueAccent),
                ),
                title: Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                subtitle: Container(
                  height: 12,
                  width: 100,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoEvolv28DevicesMessage(BleScannerViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: AppTheme.lightText),
          const SizedBox(height: 16),
          Text(
            'No Evovle28 devices found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.lightText),
          ),
          const SizedBox(height: 8),
          Text(
            '${viewModel.devices.length} other BLE devices were found',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightText),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => viewModel.startScan(),
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: AppTheme.lightText),
          const SizedBox(height: 16),
          Text(
            'Scanning for Evolv28 devices...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.lightText),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we search for nearby Evolv28 BLE devices',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Pull down to refresh and scan again',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.lightText,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithRefresh() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6, // Ensure enough space for pull-to-refresh
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth_searching, size: 64, color: AppTheme.lightText),
                const SizedBox(height: 16),
                Text(
                  'Scanning for Evolv28 devices...',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.lightText),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we search for nearby Evolv28 BLE devices',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh and scan again',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightText,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Add a manual refresh button for better iOS compatibility
                ElevatedButton.icon(
                  onPressed: () {
                    final viewModel = context.read<BleScannerViewModel>();
                    viewModel.refreshScan();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Manual Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purpleHighlight,
                    foregroundColor: AppTheme.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _connectAndDiscoverServices(BleDevice device) async {
    // Store context before async operations
    final currentContext = context;

    try {
      // Show loading dialog
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.purpleHighlight),
                const SizedBox(height: 16),
                Text(
                  'Connecting to ${device.name}...',
                  style: Theme.of(currentContext).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we connect and discover services',
                  style: Theme.of(
                    currentContext,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      // Connect to the device
      await device.device.connect(timeout: const Duration(seconds: 10));

      if (device.device.isConnected) {
        // Navigate to connected screen
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop(); // Close loading dialog
          
          Navigator.push(
            currentContext,
            MaterialPageRoute(
              builder: (context) => ConnectedDeviceScreen(
                device: device.device,
                deviceName: device.name,
                onDisconnect: () async {
                  await device.device.disconnect();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          );
        }
      } else {}

      // Discover all services
      // final services = await device.device.discoverServices();
      //
      // // Close loading dialog
      // if (currentContext.mounted) {
      //   Navigator.of(currentContext).pop();
      //
      //   // Show services in a new screen or dialog
      //   _showServicesList(device, services);
      // }
    } catch (e) {
      // Close loading dialog if it's still open
      if (currentContext.mounted && Navigator.of(currentContext).canPop()) {
        Navigator.of(currentContext).pop();
      }

      // Show error dialog
      if (currentContext.mounted) {
        showDialog(
          context: currentContext,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Text('Connection Failed'),
                ],
              ),
              content: Text(
                'Failed to connect to ${device.name}: ${e.toString()}',
                style: Theme.of(currentContext).textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(currentContext).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(color: AppTheme.purpleHighlight),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _showServicesList(BleDevice device, List<BluetoothService> services) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_connected,
                      color: AppTheme.purpleHighlight,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Services for ${device.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                      color: AppTheme.lightText,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nordic UART Service Summary
                if (services.any(
                  (service) =>
                      service.uuid.toString().toLowerCase() ==
                      nordicUartServiceUUID.toLowerCase(),
                ))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.purpleHighlight,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bluetooth_connected,
                              color: AppTheme.purpleHighlight,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nordic UART Service Found!',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.purpleHighlight,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This device supports Nordic UART communication with:',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.purpleHighlight),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.greenAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Write: 6e400002...',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.blueAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Notify: 6e400003...',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                Expanded(
                  child: services.isEmpty
                      ? Center(
                          child: Text(
                            'No services found',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.lightText),
                          ),
                        )
                      : ListView.builder(
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            final isNordicUartService =
                                service.uuid.toString().toLowerCase() ==
                                nordicUartServiceUUID.toLowerCase();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isNordicUartService
                                  ? AppTheme.purpleLight
                                  : AppTheme.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: isNordicUartService
                                    ? BorderSide(
                                        color: AppTheme.purpleHighlight,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: ExpansionTile(
                                leading: isNordicUartService
                                    ? Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.purpleHighlight,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.bluetooth_connected,
                                          color: AppTheme.white,
                                          size: 16,
                                        ),
                                      )
                                    : null,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isNordicUartService
                                            ? 'Nordic UART Service'
                                            : 'Service ${_formatUuid(service.uuid.toString())}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: isNordicUartService
                                                  ? AppTheme.purpleHighlight
                                                  : null,
                                              fontWeight: isNordicUartService
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                      ),
                                    ),
                                    if (isNordicUartService)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.purpleHighlight,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'UART',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppTheme.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${service.characteristics.length} characteristics',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isNordicUartService
                                            ? AppTheme.purpleHighlight
                                            : AppTheme.lightText,
                                      ),
                                ),
                                children: service.characteristics.map((
                                  characteristic,
                                ) {
                                  final isWriteChar =
                                      characteristic.uuid
                                          .toString()
                                          .toLowerCase() ==
                                      nordicUartWriteCharacteristicUUID
                                          .toLowerCase();
                                  final isNotifyChar =
                                      characteristic.uuid
                                          .toString()
                                          .toLowerCase() ==
                                      nordicUartNotifyCharacteristicUUID
                                          .toLowerCase();
                                  final isNordicUartChar =
                                      isWriteChar || isNotifyChar;

                                  return ListTile(
                                    dense: true,
                                    tileColor: isNordicUartChar
                                        ? AppTheme.lightBlue.withValues(
                                            alpha: 0.3,
                                          )
                                        : null,
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isWriteChar
                                                ? 'Nordic UART Write Characteristic'
                                                : isNotifyChar
                                                ? 'Nordic UART Notify Characteristic'
                                                : 'Characteristic ${_formatUuid(characteristic.uuid.toString())}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: isNordicUartChar
                                                      ? AppTheme.blueAccent
                                                      : null,
                                                  fontWeight: isNordicUartChar
                                                      ? FontWeight.w600
                                                      : null,
                                                ),
                                          ),
                                        ),
                                        if (isNordicUartChar)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isWriteChar
                                                  ? AppTheme.greenAccent
                                                  : AppTheme.blueAccent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isWriteChar ? 'WRITE' : 'NOTIFY',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: AppTheme.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Properties: ${_getCharacteristicProperties(characteristic)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isNordicUartChar
                                                ? AppTheme.blueAccent
                                                : AppTheme.lightText,
                                          ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (characteristic.properties.read)
                                          IconButton(
                                            icon: Icon(
                                              Icons.visibility,
                                              size: 16,
                                            ),
                                            onPressed: () =>
                                                _readCharacteristic(
                                                  characteristic,
                                                ),
                                            tooltip: 'Read',
                                            style: IconButton.styleFrom(
                                              backgroundColor: isNordicUartChar
                                                  ? AppTheme.blueAccent
                                                  : null,
                                              foregroundColor: isNordicUartChar
                                                  ? AppTheme.white
                                                  : null,
                                            ),
                                          ),
                                        if (characteristic.properties.write ||
                                            characteristic
                                                .properties
                                                .writeWithoutResponse)
                                          IconButton(
                                            icon: Icon(Icons.edit, size: 16),
                                            onPressed: () =>
                                                _writeCharacteristic(
                                                  characteristic,
                                                ),
                                            tooltip: 'Write',
                                            style: IconButton.styleFrom(
                                              backgroundColor: isWriteChar
                                                  ? AppTheme.greenAccent
                                                  : null,
                                              foregroundColor: isWriteChar
                                                  ? AppTheme.white
                                                  : null,
                                            ),
                                          ),
                                        if (characteristic.properties.notify ||
                                            characteristic.properties.indicate)
                                          IconButton(
                                            icon: Icon(
                                              Icons.notifications,
                                              size: 16,
                                            ),
                                            onPressed: () =>
                                                _toggleNotifications(
                                                  characteristic,
                                                ),
                                            tooltip: 'Notifications',
                                            style: IconButton.styleFrom(
                                              backgroundColor: isNotifyChar
                                                  ? AppTheme.blueAccent
                                                  : null,
                                              foregroundColor: isNotifyChar
                                                  ? AppTheme.white
                                                  : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCharacteristicProperties(BluetoothCharacteristic characteristic) {
    final properties = <String>[];
    if (characteristic.properties.read) {
      properties.add('Read');
    }
    if (characteristic.properties.write) {
      properties.add('Write');
    }
    if (characteristic.properties.writeWithoutResponse) {
      properties.add('WriteNoResponse');
    }
    if (characteristic.properties.notify) {
      properties.add('Notify');
    }
    if (characteristic.properties.indicate) {
      properties.add('Indicate');
    }
    if (characteristic.properties.broadcast) {
      properties.add('Broadcast');
    }
    if (characteristic.properties.authenticatedSignedWrites) {
      properties.add('AuthSignedWrites');
    }
    if (characteristic.properties.extendedProperties) {
      properties.add('ExtendedProps');
    }
    return properties.join(', ');
  }

  /// Safely format UUID for display
  String _formatUuid(String uuid) {
    if (uuid.length <= 8) {
      return uuid;
    }
    return '${uuid.substring(0, 8)}...';
  }

  void _readCharacteristic(BluetoothCharacteristic characteristic) {
    // TODO: Implement characteristic reading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Read characteristic: ${_formatUuid(characteristic.uuid.toString())}',
        ),
        backgroundColor: AppTheme.purpleHighlight,
      ),
    );
  }

  void _writeCharacteristic(BluetoothCharacteristic characteristic) {
    // TODO: Implement characteristic writing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Write characteristic: ${_formatUuid(characteristic.uuid.toString())}',
        ),
        backgroundColor: AppTheme.purpleHighlight,
      ),
    );
  }

  void _toggleNotifications(BluetoothCharacteristic characteristic) {
    // TODO: Implement notification toggling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Toggle notifications: ${_formatUuid(characteristic.uuid.toString())}',
        ),
        backgroundColor: AppTheme.purpleHighlight,
      ),
    );
  }
}
