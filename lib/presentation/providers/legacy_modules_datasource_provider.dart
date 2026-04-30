import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/legacy_modules_remote_datasource.dart';
import 'auth_provider.dart';

final legacyModulesDatasourceProvider = Provider<LegacyModulesRemoteDatasource>(
  (ref) => LegacyModulesRemoteDatasource(ref.read(apiClientProvider)),
);
