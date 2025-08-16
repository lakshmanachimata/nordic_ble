import 'package:flutter/material.dart';
import '../viewmodels/ble_scanner_viewmodel.dart';
import '../theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final BleState state;
  final String errorMessage;
  final VoidCallback onRetry;

  const StatusIndicator({
    super.key,
    required this.state,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (state == BleState.error || state == BleState.noPermission)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (state) {
      case BleState.idle:
        return AppTheme.blueAccent;
      case BleState.scanning:
        return AppTheme.greenAccent;
      case BleState.error:
        return Colors.red;
      case BleState.noPermission:
        return Colors.orange;
      case BleState.bluetoothOff:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (state) {
      case BleState.idle:
        return Icons.bluetooth;
      case BleState.scanning:
        return Icons.bluetooth_searching;
      case BleState.error:
        return Icons.error_outline;
      case BleState.noPermission:
        return Icons.security;
      case BleState.bluetoothOff:
        return Icons.bluetooth_disabled;
    }
  }

  String _getStatusTitle() {
    switch (state) {
      case BleState.idle:
        return 'Ready to scan';
      case BleState.scanning:
        return 'Scanning for devices...';
      case BleState.error:
        return 'Error occurred';
      case BleState.noPermission:
        return 'Permissions required';
      case BleState.bluetoothOff:
        return 'Bluetooth is turned off';
    }
  }
}
