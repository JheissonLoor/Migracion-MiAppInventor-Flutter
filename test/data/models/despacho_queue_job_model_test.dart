import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/data/models/despacho_queue_job_model.dart';

void main() {
  test('DespachoQueueJobModel serializa y deserializa', () {
    const job = DespachoQueueJobModel(
      id: 'job-1',
      rollos: [
        DespachoQueueRolloModel(
          codigo: 'T14F211125-1',
          articulo: 'RIP STOP',
          metraje: 120,
          peso: 34.5,
          ubicacion: 'PLANTA 2-A',
        ),
      ],
      destino: 'CLIENTE XYZ',
      guia: 'G001-26',
      observaciones: 'Urgente',
      usuario: 'OPERARIO',
      createdAtIso: '2026-02-12T10:00:00.000',
      attempts: 1,
    );

    final json = job.toJson();
    final parsed = DespachoQueueJobModel.fromJson(json);

    expect(parsed.id, job.id);
    expect(parsed.rollos.length, 1);
    expect(parsed.rollos.first.codigo, 'T14F211125-1');
    expect(parsed.totalMetros, 120);
    expect(parsed.totalPeso, 34.5);
    expect(parsed.attempts, 1);
  });

  test('DespachoQueueTelemetryModel serializa y deserializa', () {
    const telemetry = DespachoQueueTelemetryModel(
      enqueuedTotal: 3,
      processedTotal: 2,
      failedAttemptsTotal: 1,
      retryAttemptsTotal: 1,
      lastAttemptAtIso: '2026-02-12T11:00:00.000',
      lastProcessedAtIso: '2026-02-12T11:02:00.000',
      lastError: 'API local offline',
    );

    final json = telemetry.toJson();
    final parsed = DespachoQueueTelemetryModel.fromJson(json);

    expect(parsed.enqueuedTotal, 3);
    expect(parsed.processedTotal, 2);
    expect(parsed.failedAttemptsTotal, 1);
    expect(parsed.retryAttemptsTotal, 1);
    expect(parsed.lastError, 'API local offline');
  });
}
