import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/data/datasources/remote/produccion_remote_datasource.dart';

void main() {
  group('Produccion historial models', () {
    test('UrdidoHistorialTablaItem.fromMap mantiene contrato backend', () {
      final item = UrdidoHistorialTablaItem.fromMap({
        'codigo_urdido': 'U1-2026-001',
        'articulo': 'ART-900',
        'metros_urdido': '14500',
        'peso_hilos_urdido': '820.5',
        'fecha': '2026-04-29',
      });

      expect(item.codigoUrdido, 'U1-2026-001');
      expect(item.articulo, 'ART-900');
      expect(item.metrosUrdido, '14500');
      expect(item.pesoHilosUrdido, '820.5');
      expect(item.fecha, '2026-04-29');
    });

    test('TelarHistorialTablaItem.fromMap mantiene contrato backend', () {
      final item = TelarHistorialTablaItem.fromMap({
        'telar': '4',
        'articulo': 'ART-300',
        'hilos': 'HILO A',
        'mts': '9800',
        'titulo': 'TIT-01',
        'caract': 'PEINADO',
        'parcial': '12',
        'fecha_inicio': '2026-04-20',
        'peso_total': '420',
        'estado': 'EN PROGRESO',
      });

      expect(item.telar, '4');
      expect(item.articulo, 'ART-300');
      expect(item.hilos, 'HILO A');
      expect(item.mts, '9800');
      expect(item.titulo, 'TIT-01');
      expect(item.caract, 'PEINADO');
      expect(item.parcial, '12');
      expect(item.fechaInicio, '2026-04-20');
      expect(item.pesoTotal, '420');
      expect(item.estado, 'EN PROGRESO');
    });

    test('TelaCrudaHistorialItem.fromMap mantiene contrato MIT', () {
      final item = TelaCrudaHistorialItem.fromMap({
        'fecha': '30/04/2026',
        'hora': '10:22:00',
        'codtela': 'TC-001',
        'op': 'OP-450',
        'articulo': 'PIQUE',
        'telar': '12',
        'plegador': 'P-8',
        'cc': 'A',
        'metro': '124.5',
        'peso': '32.1',
        'fecha_revisado': '30/04/2026',
        'rendimiento': 'FUERA',
        'val_rendimiento': 'REVISAR',
      });

      expect(item.codTela, 'TC-001');
      expect(item.op, 'OP-450');
      expect(item.articulo, 'PIQUE');
      expect(item.telar, '12');
      expect(item.rendimientoFuera, isTrue);
    });

    test('HistorialAdminItem.fromMap mantiene contrato Apps Script', () {
      final item = HistorialAdminItem.fromMap({
        'fecha': '30/04/2026',
        'hora': '10:30:00',
        'codigoKardex': '100175/36/1PA/VERMIL',
        'codigo': 'H180225-302',
        'almacen': 'PLANTA 1',
        'ubicacion': 'VENTA',
        'movimiento': 'SALIDA',
      });

      expect(item.codigoKardex, '100175/36/1PA/VERMIL');
      expect(item.codigo, 'H180225-302');
      expect(item.almacen, 'PLANTA 1');
      expect(item.ubicacion, 'VENTA');
      expect(item.movimiento, 'SALIDA');
    });
  });
}
