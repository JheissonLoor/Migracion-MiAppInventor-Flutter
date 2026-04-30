// Contratos de API para migracion gradual sin romper backend legacy.
//
// Objetivo:
// - Centralizar rutas usadas por App Inventor y Flutter.
// - Enviar payloads compatibles (claves legacy + nuevas cuando aplique).
// - Reducir riesgo de errores por typo en nombres de campos.

class ApiRoutes {
  const ApiRoutes._();

  // Backend principal (PythonAnywhere)
  static const String inicioSesion = '/inicio_sesion';
  static const String consultaAlmacen = '/consulta_almacen';
  static const String consultaHistorial = '/consulta_historial';
  static const String consultaPcp = '/consulta_pcp';
  static const String stockActualPcp = '/stock_actual_pcp';
  static const String registrarIngresoTela = '/registrar_ingreso_tela';
  static const String validarRolloDespacho = '/validar_rollo_despacho';
  static const String movimientoRestringido = '/movimiento_restringido';
  static const String movimientoRestringidoSalida =
      '/movimiento_restringido_salida';
  static const String datosTara = '/datos_tara';
  static const String inventarioCero = '/api/inventario_cero';
  static const String almacenUbicacion = '/almacen_ubicacion';
  static const String actualizarDatos = '/actualizar_datos';
  static const String verificarPcpPrefix = '/api/verificar_pcp';
  static const String obtenerDatosGenerales = '/obtener_datos_generales';
  static const String urdidoScan = '/urdido_scan';
  static const String urdidoSend = '/urdido_send';
  static const String engomadoUrdidoSearch = '/engomado_urdido_search';
  static const String engomadoData = '/engomado_data';
  static const String telarSearch = '/telar_search';
  static const String telarSend = '/telar_send';
  static const String telarIngreso = '/telar_ingreso';
  static const String telarCargarProgreso = '/telar_cargar_progreso';
  static const String telarArticuloActual = '/telar_articulo_actual';
  static const String telarHistorialTabla = '/telar_historial_tabla';
  static const String urdidoHistorial = '/urdido_historial';
  static const String urdidoHistorialTabla = '/urdido_historial_tabla';
  static const String consultaHistorialTelaCruda =
      '/consulta_historial_telacruda';
  static const String generarKardex = '/generar_kardex';
  static const String adminUsers = '/admin_users';
  static const String newUsers = '/new_users';
  static const String readColumn = '/read_column';

  // Apps Script legacy usado por HistorialAdmin en MIT App Inventor.
  static const String historialAdminScriptUrl =
      'https://script.google.com/macros/s/AKfycbwoPrqY2JsoBjrjPqkBY5xpk574cpQFQlmyyiEWgM7rRYPSag-o-5ccxkU1h2LXJJkc/exec';

  // API local de impresion
  static const String localHealth = '/health';
  static const String localImpresoras = '/impresoras';
  static const String localGeneratePdf = '/generate_pdf';
  static const String localImprimir = '/imprimir';
  static const String localImprimirDespacho = '/imprimir_despacho';
}

class ApiPayloads {
  const ApiPayloads._();

  static Map<String, dynamic> inicioSesion(String password) {
    return {'password': password.trim()};
  }

  static Map<String, dynamic> consultaAlmacen({
    required String codigoPcp,
    String? usuario,
  }) {
    return {
      // Clave usada hoy en backend legacy.
      'codigopcp': codigoPcp.trim(),
      // Clave de compatibilidad para clientes nuevos.
      'codigo_pcp': codigoPcp.trim(),
      if (usuario != null && usuario.trim().isNotEmpty) 'usuario_var': usuario,
    };
  }

  static Map<String, dynamic> consultaHistorial({
    required String usuario,
    required String filtro,
  }) {
    return {
      // Clave legacy
      'nombre': usuario.trim(),
      // Clave temporal de compatibilidad
      'usuario': usuario.trim(),
      'filtro': filtro.trim(),
    };
  }

  static Map<String, dynamic> consultaPcp(String codigoPcp) {
    return {
      // Clave legacy confirmada en backend actual.
      'codigopcp': codigoPcp.trim(),
      // Clave de compatibilidad durante la migracion.
      'codigo_pcp': codigoPcp.trim(),
    };
  }

  static Map<String, dynamic> stockActualPcp(String codigoPcp) {
    return {'codigo_pcp': codigoPcp.trim()};
  }

  static Map<String, dynamic> registrarIngresoTela({
    required String codigoQr,
    required String almacen,
    required String ubicacion,
    required String observaciones,
    required String usuario,
  }) {
    return {
      'codigo_qr': codigoQr.trim(),
      'almacen': almacen.trim(),
      'ubicacion': ubicacion.trim(),
      'observaciones': observaciones.trim(),
      'usuario': usuario.trim(),
    };
  }

  static Map<String, dynamic> almacenUbicacion(String codigoPcp) {
    return {'codigo_pcp': codigoPcp.trim()};
  }

  static Map<String, dynamic> movimientoRestringido({
    required String codigoPcp,
    required String nuevaUbicacion,
    required String usuario,
  }) {
    return {
      'codigopcp': codigoPcp.trim(),
      'nueva_ubicacion': nuevaUbicacion.trim(),
      'usuario_var': usuario.trim(),
    };
  }

  static Map<String, dynamic> actualizarDatos({
    required String codigoPcp,
    required double numCajas,
    required double totalBobinas,
    required double pesoBrutoTotal,
    required double pesoNetoTotal,
    required String usuario,
  }) {
    return {
      // En backend legacy se llama "texto" (codigo HC / PCP).
      'texto': codigoPcp.trim(),
      'NumCajas': numCajas,
      'TotalBobinas': totalBobinas,
      'PesoBrutoTotal': pesoBrutoTotal,
      'PesoNetoTotal': pesoNetoTotal,
      'usuario_var': usuario.trim(),
    };
  }

  static Map<String, dynamic> datosTara({
    required String material,
    required String titulo,
    required String proveedor,
  }) {
    return {
      'material': material.trim(),
      'titulo': titulo.trim(),
      'proveedor': proveedor.trim(),
    };
  }

  static Map<String, dynamic> inventarioCero({
    required String codigoPcp,
    required String material,
    required String titulo,
    required String color,
    required String cantidadBobinas,
    required String pesoBruto,
    required String pesoNeto,
    required String almacen,
    required String ubicacion,
    String codigoKardex = '',
    String lote = '',
    String caja = '',
    String cantidadReenconado = '',
    String proveedor = '',
    String fechaIngreso = '',
    String servicio = '',
    String guia = '',
    String responsable = '',
  }) {
    return {
      'codigo_pcp': codigoPcp.trim(),
      'codigo_kardex': codigoKardex.trim(),
      'material': material.trim(),
      'titulo': titulo.trim(),
      'color': color.trim(),
      'lote': lote.trim(),
      'caja': caja.trim(),
      'cantidad_bobinas': cantidadBobinas.trim(),
      'cantidad_reenconado': cantidadReenconado.trim(),
      'peso_bruto': pesoBruto.trim(),
      'peso_neto': pesoNeto.trim(),
      'proveedor': proveedor.trim(),
      'fecha_ingreso': fechaIngreso.trim(),
      'almacen': almacen.trim(),
      'ubicacion': ubicacion.trim(),
      'servicio': servicio.trim(),
      'guia': guia.trim(),
      'responsable': responsable.trim(),
    };
  }

  static Map<String, dynamic> obtenerDatosGenerales() {
    return {'solicitud': 'GET'};
  }

  static Map<String, dynamic> adminUsersBuscar({required String user}) {
    return {'user': user.trim()};
  }

  static Map<String, dynamic> newUsersCrear({
    required String user,
    required String password,
    required String rol,
    required String usuarioActor,
  }) {
    return {
      'user': user.trim(),
      'password': password.trim(),
      'rol': rol.trim(),
      'usuario_var': usuarioActor.trim(),
    };
  }

  static Map<String, dynamic> adminUsersEditar({
    required String user,
    required String password,
    required String rol,
    required String usuarioActor,
  }) {
    return {
      'user': user.trim(),
      'password': password.trim(),
      'rol': rol.trim(),
      'usuario_var': usuarioActor.trim(),
    };
  }

  static Map<String, dynamic> adminUsersEliminar({
    required String user,
    required String usuarioActor,
  }) {
    return {
      'user': user.trim(),
      'password': 'delete',
      'rol': 'delete',
      'usuario_var': usuarioActor.trim(),
    };
  }

  static Map<String, dynamic> buscarProduccionPorCodigo(String codigoPcp) {
    return {'codigopcp': codigoPcp.trim()};
  }

  static Map<String, dynamic> ingresoTelar({
    required String telar,
    required String articulo,
    required String hilo,
    required String titulo,
    required String metraje,
    required String fechaInicio,
    required String fechaFinal,
    required String pesoTotal,
    required String estado,
    required String operario,
    required String accion,
  }) {
    return {
      'telar': telar.trim(),
      'articulo': articulo.trim(),
      'hilo': hilo.trim(),
      'titulo': titulo.trim(),
      'metraje': metraje.trim(),
      'fecha_inicio': fechaInicio.trim(),
      'fecha_final': fechaFinal.trim(),
      'peso_total': pesoTotal.trim(),
      'estado': estado.trim(),
      'operario': operario.trim(),
      'accion': accion.trim(),
    };
  }

  static Map<String, dynamic> urdidoHistorial({required String operario}) {
    return {'operario': operario.trim()};
  }

  static Map<String, dynamic> consultaHistorialTelaCruda({
    required String nombre,
  }) {
    return {'nombre': nombre.trim()};
  }

  static Map<String, dynamic> generarKardex({
    required String material,
    required String titulo,
    required String color,
  }) {
    return {
      'material': material.trim(),
      'titulo': titulo.trim(),
      'color': color.trim(),
    };
  }
}
