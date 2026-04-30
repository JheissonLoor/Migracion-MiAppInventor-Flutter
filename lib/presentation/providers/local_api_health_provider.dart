import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'auth_provider.dart';

class LocalApiHealthState {
  final bool checking;
  final bool available;
  final DateTime? lastCheckedAt;
  final String? message;
  final String configuredBaseUrl;
  final String? activeBaseUrl;
  final List<String> candidates;

  const LocalApiHealthState({
    this.checking = false,
    this.available = false,
    this.lastCheckedAt,
    this.message,
    this.configuredBaseUrl = '',
    this.activeBaseUrl,
    this.candidates = const [],
  });

  LocalApiHealthState copyWith({
    bool? checking,
    bool? available,
    DateTime? lastCheckedAt,
    String? message,
    String? configuredBaseUrl,
    String? activeBaseUrl,
    bool clearActiveBaseUrl = false,
    List<String>? candidates,
  }) {
    return LocalApiHealthState(
      checking: checking ?? this.checking,
      available: available ?? this.available,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      message: message ?? this.message,
      configuredBaseUrl: configuredBaseUrl ?? this.configuredBaseUrl,
      activeBaseUrl:
          clearActiveBaseUrl ? null : (activeBaseUrl ?? this.activeBaseUrl),
      candidates: candidates ?? this.candidates,
    );
  }
}

class LocalApiHealthNotifier extends StateNotifier<LocalApiHealthState> {
  final LocalApiClient _client;
  Timer? _timer;

  LocalApiHealthNotifier(this._client) : super(const LocalApiHealthState()) {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  Future<void> manualRefresh() async {
    await _refresh();
  }

  Future<void> _refresh() async {
    state = state.copyWith(checking: true);
    final report = await _client.checkHealth();
    state = state.copyWith(
      checking: false,
      available: report.available,
      lastCheckedAt: DateTime.now(),
      message: report.message,
      configuredBaseUrl: report.configuredBaseUrl,
      activeBaseUrl: report.activeBaseUrl,
      clearActiveBaseUrl: report.activeBaseUrl == null,
      candidates: report.candidateBaseUrls,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final localApiHealthProvider =
    StateNotifierProvider<LocalApiHealthNotifier, LocalApiHealthState>(
      (ref) => LocalApiHealthNotifier(ref.read(localApiClientProvider)),
    );
