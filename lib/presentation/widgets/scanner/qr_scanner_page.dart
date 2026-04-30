import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_theme.dart';

Future<String?> openQrScanner(
  BuildContext context, {
  String title = 'Escanear QR',
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => QrScannerPage(title: title),
    ),
  );
}

class QrScannerPage extends StatefulWidget {
  final String title;

  const QrScannerPage({super.key, required this.title});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_completed) return;

    for (final barcode in capture.barcodes) {
      final raw = (barcode.rawValue ?? '').trim();
      if (raw.isEmpty) continue;

      _completed = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
          const Positioned.fill(child: _ScannerOverlay()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _ActionIcon(
                        icon: Icons.flash_on_rounded,
                        onTap: _controller.toggleTorch,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        icon: Icons.cameraswitch_rounded,
                        onTap: _controller.switchCamera,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'Alinea el codigo dentro del marco. El escaneo es automatico.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
      ),
      icon: Icon(icon, color: Colors.white),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final cutoutSize = size.width * 0.72;
        final rect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: cutoutSize,
          height: cutoutSize,
        );

        return CustomPaint(
          painter: _ScannerOverlayPainter(rect),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CorporateTokens.cyan300.withValues(alpha: 0.95),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CorporateTokens.cyan500.withValues(
                            alpha: 0.20,
                          ),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect cutoutRect;

  _ScannerOverlayPainter(this.cutoutRect);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.52);
    final framePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final overlayPath = Path()..addRect(Offset.zero & size);
    final cutoutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)),
        );

    final finalPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, overlayPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect;
  }
}
