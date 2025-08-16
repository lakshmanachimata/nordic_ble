# Nordic BLE Scanner

A Flutter application designed to discover and connect to Nordic Semiconductor BLE devices. Built with MVVM architecture and a modern, clean UI featuring a light blue and light green theme with purple highlights.

## Features

- **Nordic Device Detection**: Automatically identifies Nordic BLE devices based on name patterns and manufacturer data
- **Real-time Scanning**: Live BLE device discovery with signal strength indicators
- **Permission Management**: Handles Bluetooth and location permissions automatically
- **Modern UI**: Clean, intuitive interface with smooth animations and visual feedback
- **MVVM Architecture**: Clean separation of concerns with proper state management
- **Cross-platform**: Works on both Android and iOS

## Architecture

This app follows the **MVVM (Model-View-ViewModel)** pattern:

- **Models**: Data classes representing BLE devices
- **Views**: UI components and screens
- **ViewModels**: Business logic and state management using Provider pattern

### Project Structure

```
lib/
├── models/
│   └── ble_device.dart          # BLE device data model
├── viewmodels/
│   └── ble_scanner_viewmodel.dart # BLE scanning logic
├── screens/
│   └── ble_scanner_screen.dart  # Main scanner screen
├── widgets/
│   ├── device_list_item.dart    # Device list item widget
│   ├── scan_button.dart         # Animated scan button
│   └── status_indicator.dart    # Status display widget
├── theme/
│   └── app_theme.dart           # Custom theme configuration
└── main.dart                    # App entry point
```

## Nordic Device Detection

The app identifies Nordic devices using multiple criteria:

1. **Name Patterns**: Looks for common Nordic device names like:
   - `nRF` (nRF52, nRF53, nRF91 series)
   - `Nordic`
   - `Thingy`
   - `DK` (Development Kits)
   - `PCA` (Product Codes)

2. **Manufacturer Data**: Checks for Nordic's company identifier (0x0059)

## Dependencies

- **flutter_blue_plus**: BLE functionality
- **permission_handler**: Permission management
- **provider**: State management
- **shimmer**: Loading animations
- **flutter_svg**: SVG support

## Setup

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Android Studio / Xcode
- Physical device with Bluetooth LE support

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Platform-specific Setup

#### Android

The app automatically requests the following permissions:
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

#### iOS

The app requests:
- Bluetooth Always Usage
- Bluetooth Peripheral Usage
- Location When In Use

## Usage

1. **Launch the app** - It will automatically request necessary permissions
2. **Tap "Start Scan"** - Begins searching for BLE devices
3. **View Nordic devices** - Only Nordic devices are displayed in the main list
4. **Tap a device** - View detailed information and connect options
5. **Stop scanning** - Tap the scan button again to stop

## Theme

The app uses a carefully designed color scheme:

- **Light Blue** (`#E3F2FD`): Primary background color
- **Light Green** (`#E8F5E8`): Secondary background color
- **Purple Highlight** (`#9C27B0`): Primary accent color
- **Blue Accent** (`#2196F3`): Secondary accent color
- **Green Accent** (`#4CAF50`): Success/action color

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Acknowledgments

- Nordic Semiconductor for BLE technology
- Flutter team for the amazing framework
- The open-source community for the packages used

## Troubleshooting

### Common Issues

1. **No devices found**: Ensure Bluetooth is enabled and location permissions are granted
2. **Permission errors**: Check device settings for Bluetooth and location permissions
3. **Scan not working**: Restart the app and ensure all permissions are granted

### Debug Mode

Enable debug logging by setting the log level in the BLE view model:

```dart
// In ble_scanner_viewmodel.dart
FlutterBluePlus.setLogLevel(LogLevel.verbose);
```

## Future Enhancements

- [ ] Device connection and communication
- [ ] Service and characteristic discovery
- [ ] Data logging and export
- [ ] Device pairing management
- [ ] Advanced filtering options
- [ ] Dark theme support
