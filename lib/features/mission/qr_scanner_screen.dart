import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../widgets/game_button.dart';
import '../../widgets/ink_icon.dart';

/// Full-screen camera scanner. Pops with the scanned text, or null.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Scanned payloads longer than this are ignored (never a valid game code).
  static const maxPayloadLength = 128;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    if (QrScannerScreen.isSupported) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final code in capture.barcodes) {
      final value = code.rawValue?.trim();
      if (value == null || value.isEmpty || value.length > QrScannerScreen.maxPayloadLength) continue;
      _handled = true;
      _controller?.stop();
      context.pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      appBar: AppBar(
        foregroundColor: AppColors.goldLight,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        title: Text('SCAN THE SECRET CODE', style: AppText.eyebrow(color: AppColors.goldLight)),
        leading: IconButton(
          tooltip: 'Close',
          icon: const InkIcon(InkGlyph.close),
          onPressed: () => context.pop(),
        ),
        // Camera controls and camera errors keep Material icons: device
        // functions, the one exception to the Ink Icon System.
        actions: [
          if (controller != null)
            IconButton(
              tooltip: 'Flashlight',
              icon: const Icon(Icons.flashlight_on_rounded),
              onPressed: controller.toggleTorch,
            ),
        ],
      ),
      body: controller == null
          ? const _ScannerMessage(
              icon: Icons.no_photography_rounded,
              title: 'No camera here',
              message: 'This device cannot scan QR codes.\nGo back and type the code printed under the QR.',
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _ScannerMessage(
                    icon: Icons.videocam_off_rounded,
                    title: error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Camera permission needed'
                        : 'The camera is not available',
                    message: error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Ask a grown-up to allow the camera in Settings,\nor go back and type the code.'
                        : 'Go back and type the code printed under the QR.',
                  ),
                ),
                const IgnorePointer(child: CustomPaint(painter: _FramePainter())),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 48,
                  child: Text(
                    'Point the camera at the QR code',
                    textAlign: TextAlign.center,
                    style: AppText.subtitle(color: AppColors.paperLight),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ScannerMessage extends StatelessWidget {
  const _ScannerMessage({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.goldLight),
            const SizedBox(height: 16),
            Text(title, style: AppText.title(color: AppColors.paperLight), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppText.bodyText(size: 16, color: AppColors.paperLight.withValues(alpha: 0.75)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GameButton(
              label: 'GO BACK',
              style: GameButtonStyle.glass,
              expand: false,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.65;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24))),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    final corner = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const len = 36.0;
    for (final (o, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(o, o + Offset(len * dx, 0), corner);
      canvas.drawLine(o, o + Offset(0, len * dy), corner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
