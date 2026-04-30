import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/core/contracts/api_contracts.dart';

void main() {
  group('ApiPayloads admin users', () {
    test('buscar envia user legacy', () {
      final payload = ApiPayloads.adminUsersBuscar(user: '  jheisson  ');

      expect(payload['user'], 'jheisson');
      expect(payload.length, 1);
    });

    test('crear incluye usuario_var y trims', () {
      final payload = ApiPayloads.newUsersCrear(
        user: '  operador01 ',
        password: ' 1234 ',
        rol: ' Operario ',
        usuarioActor: ' admin.pcp ',
      );

      expect(payload, {
        'user': 'operador01',
        'password': '1234',
        'rol': 'Operario',
        'usuario_var': 'admin.pcp',
      });
    });

    test('editar mantiene contrato legacy', () {
      final payload = ApiPayloads.adminUsersEditar(
        user: 'u1',
        password: 'p1',
        rol: 'Administrador',
        usuarioActor: 'pcp',
      );

      expect(payload, {
        'user': 'u1',
        'password': 'p1',
        'rol': 'Administrador',
        'usuario_var': 'pcp',
      });
    });

    test('eliminar envia marcadores delete', () {
      final payload = ApiPayloads.adminUsersEliminar(
        user: 'u2',
        usuarioActor: 'pcp',
      );

      expect(payload, {
        'user': 'u2',
        'password': 'delete',
        'rol': 'delete',
        'usuario_var': 'pcp',
      });
    });
  });
}
