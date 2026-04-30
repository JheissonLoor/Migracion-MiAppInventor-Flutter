import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/environment.dart';

class ProveedorTarasModel {
  final String taraCono;
  final String taraBolsa;
  final String taraCaja;
  final String taraSaco;

  const ProveedorTarasModel({
    required this.taraCono,
    required this.taraBolsa,
    required this.taraCaja,
    required this.taraSaco,
  });

  static ProveedorTarasModel fromDynamic(dynamic source) {
    if (source is String) {
      final trimmed = source.trim();
      final decoded = jsonDecode(trimmed);
      return fromDynamic(decoded);
    }

    if (source is! Map) {
      throw Exception('Formato inesperado de taras para proveedor');
    }

    final map = Map<String, dynamic>.from(source);

    String readKey(List<String> keys) {
      for (final key in keys) {
        for (final entry in map.entries) {
          if (entry.key.toString().trim().toLowerCase() ==
              key.toLowerCase()) {
            return entry.value.toString().trim();
          }
        }
      }
      return '';
    }

    return ProveedorTarasModel(
      taraCono: readKey(const ['Tara cono', 'tara_cono', 'taraCono']),
      taraBolsa: readKey(const ['Tara bolsa', 'tara_bolsa', 'taraBolsa']),
      taraCaja: readKey(const ['Tara Caja', 'tara_caja', 'taraCaja']),
      taraSaco: readKey(const ['Tara Saco', 'tara_saco', 'taraSaco']),
    );
  }

  Map<String, String> toQueryMap({required String codigo}) {
    return {
      'codigo': codigo.trim(),
      'tara_cono': taraCono.trim(),
      'tara_bolsa': taraBolsa.trim(),
      'tara_caja': taraCaja.trim(),
      'tara_saco': taraSaco.trim(),
    };
  }
}

class ProveedorRemoteDatasource {
  static const String _searchCodigoUrl =
      'https://script.google.com/macros/s/AKfycbx21YAYDDvB-aPKV1KM9CLntPku-Kdmg-BqKlkuxmlMY2NaCImxSxdxwB5kVBwlSQ6azg/exec';
  static const String _searchTarasUrl =
      'https://script.google.com/macros/s/AKfycbw9wAtofEd6MhM-bgl7VQckKfTTe7P5zFh69Hu57HXM8VRkx8ggyT-9I1hlY4bgUBYnlw/exec';
  static const String _updateTarasUrl =
      'https://script.google.com/macros/s/AKfycbybBsh6gpMEd8RCCNTQnCyle8WWT2OXbbEOrq4mhors5nzMqMpy89O1uNop-wKD4wGPhw/exec';

  final Dio _dio;

  ProveedorRemoteDatasource()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: Duration(seconds: EnvironmentConfig.connectTimeout),
            receiveTimeout: Duration(seconds: EnvironmentConfig.receiveTimeout),
          ),
        );

  Future<String> buscarCodigoProveedor({
    required String proveedor,
    required String material,
    required String titulo,
  }) async {
    final response = await _dio.get(
      _searchCodigoUrl,
      queryParameters: {
        'Proveedor': proveedor.trim(),
        'Material': material.trim(),
        'Titulo': titulo.trim(),
      },
    );

    final text = _responseToText(response.data);
    if (text.toLowerCase().contains('no encontrado')) {
      throw Exception('No se encontro objeto que coincida');
    }

    if (text.trim().isEmpty) {
      throw Exception('No se recibio codigo de proveedor');
    }

    return text.trim();
  }

  Future<ProveedorTarasModel> obtenerTarasPorCodigo(String codigo) async {
    final response = await _dio.get(
      _searchTarasUrl,
      queryParameters: {'Codigo': codigo.trim()},
    );

    final text = _responseToText(response.data);
    if (text.toLowerCase().contains('no encontrado')) {
      throw Exception('No se encontraron taras para el codigo indicado');
    }

    try {
      return ProveedorTarasModel.fromDynamic(response.data);
    } catch (_) {
      return ProveedorTarasModel.fromDynamic(text);
    }
  }

  Future<String> actualizarTarasProveedor({
    required String codigo,
    required ProveedorTarasModel taras,
  }) async {
    final response = await _dio.get(
      _updateTarasUrl,
      queryParameters: taras.toQueryMap(codigo: codigo),
    );

    final text = _responseToText(response.data);
    if (text.trim().isEmpty) {
      return 'Datos actualizados correctamente';
    }

    return text.trim();
  }

  String _responseToText(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    if (data is Map || data is List) {
      return jsonEncode(data);
    }
    return data.toString();
  }
}
