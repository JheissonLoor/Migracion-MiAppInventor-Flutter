import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/core/contracts/api_contracts.dart';

void main() {
  group('ApiPayloads ingreso telar', () {
    test('construye contrato legacy completo con trims', () {
      final payload = ApiPayloads.ingresoTelar(
        telar: ' 12 ',
        articulo: ' ART-55 ',
        hilos: ' HILO A ',
        titulo: ' TITULO X ',
        mts: ' 900 ',
        material: ' ALGODON ',
        color: ' AZUL 045 ',
        pas: ' 120 ',
        anchoPeine: ' 1.75 ',
        trama: ' 30 ',
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
        'hilos': 'HILO A',
        'titulo': 'TITULO X',
        'mts': '900',
        'material': 'ALGODON',
        'color': 'AZUL 045',
        'pas': '120',
        'ancho_peine': '1.75',
        'trama': '30',
        'hilo': 'HILO A',
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
        hilos: '',
        titulo: '',
        mts: '',
        material: '',
        color: '',
        pas: '',
        anchoPeine: '',
        trama: '',
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
        'hilos',
        'mts',
        'material',
        'color',
        'pas',
        'ancho_peine',
        'trama',
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

  group('ApiPayloads corte rollo', () {
    test('construye payload FASE3 con trims', () {
      final payload = ApiPayloads.cortarRollo(
        codigoMadre: ' U22406005 ',
        metros: ' 200 ',
        destino: ' Telar 49 ',
        usuario: ' Percy ',
      );

      expect(payload, {
        'codigo_madre': 'U22406005',
        'metros': '200',
        'destino': 'Telar 49',
        'usuario': 'Percy',
      });
    });
  });
}
