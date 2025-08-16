import 'package:flutter/material.dart';
import '../models/ble_device.dart';
import '../theme/app_theme.dart';

class DeviceListItem extends StatelessWidget {
  final BleDevice device;
  final VoidCallback onTap;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Device icon with Evolv28 indicator
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: device.isEvolv28 
                      ? AppTheme.purpleLight 
                      : AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: device.isEvolv28 
                        ? AppTheme.purpleHighlight 
                        : AppTheme.blueAccent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  device.isEvolv28 ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: device.isEvolv28 
                      ? AppTheme.purpleHighlight 
                      : AppTheme.blueAccent,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Device information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.isEvolv28)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleHighlight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Evolv28',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppTheme.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      device.id,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightText,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        // RSSI indicator
                        Row(
                          children: [
                            Icon(
                              _getRssiIcon(device.rssi),
                              size: 16,
                              color: _getRssiColor(device.rssi),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${device.rssi} dBm',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getRssiColor(device.rssi),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Time since discovery
                        Text(
                          _formatTimeAgo(device.discoveredAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Arrow indicator
              Icon(
                Icons.chevron_right,
                color: AppTheme.lightText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRssiIcon(int rssi) {
    if (rssi >= -50) return Icons.signal_cellular_4_bar;
    if (rssi >= -60) return Icons.signal_cellular_4_bar;
    if (rssi >= -70) return Icons.signal_cellular_4_bar;
    if (rssi >= -80) return Icons.signal_cellular_4_bar;
    return Icons.signal_cellular_4_bar;
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -50) return AppTheme.greenAccent;
    if (rssi >= -60) return AppTheme.greenAccent;
    if (rssi >= -70) return AppTheme.blueAccent;
    if (rssi >= -80) return AppTheme.purpleHighlight;
    return AppTheme.lightText;
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
