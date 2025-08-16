import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScanButton extends StatefulWidget {
  final bool isScanning;
  final VoidCallback onScanPressed;

  const ScanButton({
    super.key,
    required this.isScanning,
    required this.onScanPressed,
  });

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void didUpdateWidget(ScanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isScanning ? _scaleAnimation.value : 1.0,
          child: ElevatedButton.icon(
            onPressed: widget.onScanPressed,
            icon: widget.isScanning
                ? Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: const Icon(Icons.stop),
                  )
                : const Icon(Icons.search),
            label: Text(
              widget.isScanning ? 'Stop Scan' : 'Start Scan',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isScanning 
                  ? AppTheme.greenAccent 
                  : AppTheme.purpleHighlight,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: widget.isScanning ? 4 : 2,
            ),
          ),
        );
      },
    );
  }
}
