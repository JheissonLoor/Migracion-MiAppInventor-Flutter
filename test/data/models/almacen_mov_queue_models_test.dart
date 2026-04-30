import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/data/models/almacen_mov_queue_models.dart';

void main() {
  test('SalidaQueueJobModel serializa y deserializa', () {
    const job = SalidaQueueJobModel(
      id: 's-1',
      qrCampos: 16,
      codigoKardex: '100175/36/1PA/LAD1760',
      codigoPcp: 'PCP-001',
      lote: 'L-10',
      planta: 'PLANTA 1',
      nuevaUbicacion: 'VENTA',
      ubicacionPayload: 'VENTA - INVERSIONES TAKI',
      destinoVenta: 'INVERSIONES TAKI',
      destinoCliente: '',
      fechaSalida: '20/02/2026',
      horaSalida: '11:25:00',
      servicio: 'NO',
      telar: '',
      numeroGuia: 'G-001',
      ordenCompra: 'OC-7788',
      numCajas: '2',
      totalBobinas: '20',
      pesoBrutoTotal: '100.5',
      pesoNetoTotal: '98.0',
      usuario: 'OPERARIO',
      createdAtIso: '2026-02-12T10:00:00.000',
      attempts: 1,
    );

    final parsed = SalidaQueueJobModel.fromJson(job.toJson());

    expect(parsed.id, job.id);
    expect(parsed.codigoPcp, 'PCP-001');
    expect(parsed.qrCampos, 16);
    expect(parsed.codigoKardex, '100175/36/1PA/LAD1760');
    expect(parsed.lote, 'L-10');
    expect(parsed.nuevaUbicacion, 'VENTA');
    expect(parsed.ubicacionPayload, 'VENTA - INVERSIONES TAKI');
    expect(parsed.destinoVenta, 'INVERSIONES TAKI');
    expect(parsed.numeroGuia, 'G-001');
    expect(parsed.ordenCompra, 'OC-7788');
    expect(parsed.attempts, 1);
  });

  test('SalidaQueueJobModel mantiene compatibilidad con payload antiguo', () {
    final parsed = SalidaQueueJobModel.fromJson({
      'id': 'old-1',
      'codigo_pcp': 'PCP-OLD',
      'nueva_ubicacion': 'TRAMA',
      'guia_box': 'G-OLD',
      'oc_box': 'OC-OLD',
      'num_cajas': '1',
      'total_bobinas': '10',
      'peso_bruto_total': '50',
      'peso_neto_total': '49',
      'usuario': 'OPERARIO',
      'created_at_iso': '2026-02-20T10:00:00.000',
      'attempts': 0,
    });

    expect(parsed.qrCampos, 0);
    expect(parsed.codigoKardex, isEmpty);
    expect(parsed.codigoPcp, 'PCP-OLD');
    expect(parsed.nuevaUbicacion, 'TRAMA');
    expect(parsed.numeroGuia, 'G-OLD');
    expect(parsed.ordenCompra, 'OC-OLD');
  });

  test('ReingresoQueueJobModel serializa y deserializa', () {
    const job = ReingresoQueueJobModel(
      id: 'r-1',
      nuevaUbicacion: 'ALMACEN-A',
      usuario: 'OPERARIO',
      createdAtIso: '2026-02-12T10:00:00.000',
      attempts: 2,
      codigoPcp: 'PCP-001',
      codigoKardex: 'K-99',
      material: 'ALGODON',
      titulo: '40/1',
      color: 'CRUDO',
      lote: 'L-10',
      numCajas: '1',
      totalBobinas: '10',
      cantidadReenconado: '0',
      pesoBruto: '50',
      pesoNeto: '49.5',
      proveedor: 'PROV',
      fechaIngreso: '12/02/2026',
      fechaSalida: '12/02/2026',
      horaSalida: '10:10:10',
      servicio: 'SERV',
      movimiento: 'REINGRESO',
    );

    final parsed = ReingresoQueueJobModel.fromJson(job.toJson());

    expect(parsed.id, job.id);
    expect(parsed.codigoPcp, 'PCP-001');
    expect(parsed.nuevaUbicacion, 'ALMACEN-A');
    expect(parsed.attempts, 2);
  });

  test('QueueTelemetryModel serializa y deserializa', () {
    const telemetry = QueueTelemetryModel(
      enqueuedTotal: 5,
      processedTotal: 3,
      failedAttemptsTotal: 2,
      retryAttemptsTotal: 2,
      lastAttemptAtIso: '2026-02-12T11:00:00.000',
      lastProcessedAtIso: '2026-02-12T11:02:00.000',
      lastError: 'timeout',
    );

    final parsed = QueueTelemetryModel.fromJson(telemetry.toJson());

    expect(parsed.enqueuedTotal, 5);
    expect(parsed.processedTotal, 3);
    expect(parsed.failedAttemptsTotal, 2);
    expect(parsed.retryAttemptsTotal, 2);
    expect(parsed.lastError, 'timeout');
  });
}
