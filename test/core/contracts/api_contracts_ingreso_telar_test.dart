import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/core/contracts/api_contracts.dart';

void main() {
  group('ApiPayloads ingreso telar', () {
    test('construye contrato legacy completo con trims', () {
      final payload = ApiPayloads.ingresoTelar(
        telar: ' 12 ',
        articulo: ' ART-55 ',
        hilo: ' HILO A ',
        titulo: ' TITULO X ',
        metraje: ' 900 ',
        fechaInicio: ' 2026-4-29 ',
        fechaFinal: ' 2026-4-30 ',
        pesoTotal: ' 120.5 ',
        estado: ' EN PROGRESO ',
        operario: ' Percy ',
        accion: ' guardar ',
      );

      expect(payload, {
        'telar': '12',
        'articulo': 'ART-55',
        'hilo': 'HILO A',
        'titulo': 'TITULO X',
        'metraje': '900',
        'fecha_inicio': '2026-4-29',
        'fecha_final': '2026-4-30',
        'peso_total': '120.5',
        'estado': 'EN PROGRESO',
        'operario': 'Percy',
        'accion': 'guardar',
      });
    });

    test('permite campos opcionales vacios sin romper llaves', () {
      final payload = ApiPayloads.ingresoTelar(
        telar: '8',
        articulo: 'ART-01',
        hilo: '',
        titulo: '',
        metraje: '',
        fechaInicio: '',
        fechaFinal: '',
        pesoTotal: '',
        estado: 'COMPLETADO',
        operario: 'Admin',
        accion: 'completar',
      );

      expect(payload.keys, {
        'telar',
        'articulo',
        'hilo',
        'titulo',
        'metraje',
        'fecha_inicio',
        'fecha_final',
        'peso_total',
        'estado',
        'operario',
        'accion',
      });
      expect(payload['telar'], '8');
      expect(payload['articulo'], 'ART-01');
      expect(payload['estado'], 'COMPLETADO');
      expect(payload['accion'], 'completar');
    });
  });
}
