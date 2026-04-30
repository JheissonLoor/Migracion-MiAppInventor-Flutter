import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/data/models/print_job_model.dart';

void main() {
  test('PrintJobModel serializa y deserializa correctamente', () {
    const model = PrintJobModel(
      id: 'job-1',
      qrRaw: 'QR-RAW',
      text: 'LINEA1\nLINEA2',
      codigo: 'COD-1',
      lote: 'LOTE-2',
      articulo: 'RIPSTOP',
      metraje: '100',
      revisador: 'ANA',
      createdAtIso: '2026-02-12T10:00:00.000',
      attempts: 2,
    );

    final json = model.toJson();
    final parsed = PrintJobModel.fromJson(json);

    expect(parsed.id, model.id);
    expect(parsed.qrRaw, model.qrRaw);
    expect(parsed.text, model.text);
    expect(parsed.codigo, model.codigo);
    expect(parsed.attempts, model.attempts);
  });
}
