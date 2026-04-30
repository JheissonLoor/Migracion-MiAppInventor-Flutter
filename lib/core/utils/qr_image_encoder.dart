import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

class QrImageEncoder {
  const QrImageEncoder._();

  static Future<String> toBase64Png(String data, {int size = 420}) async {
    final value = data.trim();
    if (value.isEmpty) {
      throw Exception('No se puede generar QR de un texto vacio');
    }

    final painter = QrPainter(
      data: value,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: ui.Color(0xFF111111),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: ui.Color(0xFF111111),
      ),
    );

    final byteData = await painter.toImageData(
      size.toDouble(),
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('No fue posible convertir el QR a imagen');
    }

    final bytes = Uint8List.view(byteData.buffer);
    return base64Encode(bytes);
  }
}
