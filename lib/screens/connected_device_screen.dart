import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../viewmodels/connected_device_viewmodel.dart';
import '../theme/app_theme.dart';

class ConnectedDeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String deviceName;
  final VoidCallback onDisconnect;

  const ConnectedDeviceScreen({
    super.key,
    required this.device,
    required this.deviceName,
    required this.onDisconnect,
  });

  @override
  State<ConnectedDeviceScreen> createState() => _ConnectedDeviceScreenState();
}

class _ConnectedDeviceScreenState extends State<ConnectedDeviceScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = ConnectedDeviceViewModel(
          device: widget.device,
          deviceName: widget.deviceName,
        );
        // Set up callback to show file selection popup
        viewModel.onFilesReady = () => _showFileSelectionDialog(context, viewModel);
        return viewModel;
      },
      child: Consumer<ConnectedDeviceViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppTheme.lightBlue,
            appBar: AppBar(
              title: Text('Connected: ${widget.deviceName}'),
              backgroundColor: AppTheme.purpleHighlight,
              foregroundColor: AppTheme.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.bluetooth_disabled),
                  onPressed: () async {
                    await viewModel.disconnect();
                    widget.onDisconnect();
                  },
                  tooltip: 'Disconnect',
                ),
              ],
            ),
            body: Column(
              children: [
                // Connection status and controls
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Connection status
                      Row(
                        children: [
                          Icon(
                            viewModel.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            color: viewModel.isConnected ? AppTheme.greenAccent : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.isConnected ? 'Connected' : 'Disconnected',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: viewModel.isConnected ? AppTheme.greenAccent : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Command sequence controls
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: viewModel.isConnected && viewModel.state == CommunicationState.idle
                                  ? viewModel.startCommandSequence
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Commands'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.purpleHighlight,
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: viewModel.commandResponses.isNotEmpty
                                ? viewModel.resetCommandSequence
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.blueAccent,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      
                      // File selection button (show when files are available)
                      if (viewModel.availableBcuFiles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.blueAccent),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.audiotrack,
                                    color: AppTheme.purpleHighlight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Available Audio Files',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppTheme.purpleHighlight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Selected: ${viewModel.selectedBcuFile}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.darkText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _showFileSelectionDialog(context, viewModel),
                                    icon: const Icon(Icons.folder_open, size: 16),
                                    label: const Text('Change'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.orangeAccent,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Progress indicator
                      if (viewModel.state == CommunicationState.sending || viewModel.state == CommunicationState.waiting)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: viewModel.isSendingPlayCommands 
                                    ? (viewModel.playCommandResponses.length / ConnectedDeviceViewModel.playCommands.length)
                                    : (viewModel.commandResponses.length / ConnectedDeviceViewModel.commands.length),
                                backgroundColor: AppTheme.lightBlue,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.purpleHighlight),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                viewModel.isSendingPlayCommands
                                    ? 'Play Commands: ${viewModel.playCommandResponses.length + 1}/${ConnectedDeviceViewModel.playCommands.length} - ${_getStateText(viewModel.state)}'
                                    : '${viewModel.commandResponses.length + 1}/${ConnectedDeviceViewModel.commands.length} - ${_getStateText(viewModel.state)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.purpleHighlight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Commands list
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.purpleLight,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.list_alt,
                                color: AppTheme.purpleHighlight,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Command Sequence',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.purpleHighlight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (viewModel.hasCompletedAllCommands)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.greenAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'COMPLETED',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Commands list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: ConnectedDeviceViewModel.commands.length + ConnectedDeviceViewModel.playCommands.length,
                            itemBuilder: (context, index) {
                              // Determine if this is a regular command or play command
                              final isPlayCommand = index >= ConnectedDeviceViewModel.commands.length;
                              final commandIndex = isPlayCommand 
                                  ? index - ConnectedDeviceViewModel.commands.length 
                                  : index;
                              
                              final command = isPlayCommand 
                                  ? ConnectedDeviceViewModel.playCommands[commandIndex]
                                  : ConnectedDeviceViewModel.commands[commandIndex];
                              
                              final response = isPlayCommand
                                  ? (commandIndex < viewModel.playCommandResponses.length 
                                      ? viewModel.playCommandResponses[commandIndex] 
                                      : null)
                                  : (commandIndex < viewModel.commandResponses.length 
                                      ? viewModel.commandResponses[commandIndex] 
                                      : null);
                              
                              final isCompleted = response != null;
                              final isCurrent = viewModel.state == CommunicationState.sending && 
                                              ((!isPlayCommand && viewModel.commandResponses.length == commandIndex && !viewModel.isSendingPlayCommands) ||
                                               (isPlayCommand && viewModel.isSendingPlayCommands && viewModel.playCommandResponses.length == commandIndex));
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: isCurrent ? AppTheme.lightBlue : AppTheme.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isCompleted 
                                      ? BorderSide(color: isPlayCommand ? AppTheme.orangeAccent : AppTheme.greenAccent, width: 2)
                                      : isCurrent
                                          ? BorderSide(color: isPlayCommand ? AppTheme.orangeAccent : AppTheme.blueAccent, width: 2)
                                          : BorderSide.none,
                                ),
                                child: ExpansionTile(
                                  leading: _getCommandIcon(isCompleted, isCurrent, isPlayCommand),
                                  title: Row(
                                    children: [
                                      if (isPlayCommand) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.orangeAccent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'PLAY',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: AppTheme.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          command,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: isCompleted ? (isPlayCommand ? AppTheme.orangeAccent : AppTheme.greenAccent) : null,
                                            fontWeight: isCompleted ? FontWeight.w600 : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    isCompleted 
                                        ? 'Response received at ${_formatTime(response.timestamp)}'
                                        : isCurrent 
                                            ? 'Sending...'
                                            : 'Pending',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isCompleted ? (isPlayCommand ? AppTheme.orangeAccent : AppTheme.greenAccent) : AppTheme.lightText,
                                    ),
                                  ),
                                  children: [
                                    if (isCompleted) ...[
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Response:',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: AppTheme.purpleHighlight,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppTheme.lightBlue,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppTheme.blueAccent),
                                              ),
                                              child: Text(
                                                response.response,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getCommandIcon(bool isCompleted, bool isCurrent, bool isPlayCommand) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isPlayCommand ? AppTheme.orangeAccent : AppTheme.greenAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.check,
          color: AppTheme.white,
          size: 16,
        ),
      );
    } else if (isCurrent) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isPlayCommand ? AppTheme.orangeAccent : AppTheme.blueAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.sync,
          color: AppTheme.white,
          size: 16,
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.lightText,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.schedule,
          color: AppTheme.white,
          size: 16,
        ),
      );
    }
  }

  String _getStateText(CommunicationState state) {
    switch (state) {
      case CommunicationState.sending:
        return 'Sending command...';
      case CommunicationState.waiting:
        return 'Waiting for response...';
      case CommunicationState.completed:
        return 'All commands completed';
      case CommunicationState.error:
        return 'Error occurred';
      default:
        return 'Ready';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _showFileSelectionDialog(BuildContext context, ConnectedDeviceViewModel viewModel) {
    print('=== SHOWING FILE SELECTION DIALOG ===');
    print('Available files: ${viewModel.availableBcuFiles}');
    print('Selected file: ${viewModel.selectedBcuFile}');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: AppTheme.purpleHighlight,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Select Audio File',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.purpleHighlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: viewModel.availableBcuFiles.length,
              itemBuilder: (context, index) {
                final filename = viewModel.availableBcuFiles[index];
                final isSelected = filename == viewModel.selectedBcuFile;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? AppTheme.lightBlue : AppTheme.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.purpleHighlight : AppTheme.lightBlue,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.purpleHighlight : AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: isSelected ? AppTheme.white : AppTheme.purpleHighlight,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      filename,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected ? AppTheme.purpleHighlight : AppTheme.darkText,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Audio file',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightText,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: AppTheme.purpleHighlight,
                            size: 24,
                          )
                        : null,
                    onTap: () {
                      viewModel.selectBcuFile(filename);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.lightText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
