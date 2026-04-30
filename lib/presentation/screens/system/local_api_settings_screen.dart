import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/local_api_health_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class LocalApiSettingsScreen extends ConsumerStatefulWidget {
  const LocalApiSettingsScreen({super.key});

  @override
  ConsumerState<LocalApiSettingsScreen> createState() =>
      _LocalApiSettingsScreenState();
}

class _LocalApiSettingsScreenState extends ConsumerState<LocalApiSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _impresionController;
  late final TextEditingController _telaresController;
  late final AnimationController _entryController;

  bool _saving = false;
  String? _infoMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageProvider);
    _impresionController = TextEditingController(text: storage.localApiUrl);
    _telaresController = TextEditingController(
      text: storage.telaresLocalApiUrl,
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localApiHealthProvider.notifier).manualRefresh();
    });
  }

  @override
  void dispose() {
    _impresionController.dispose();
    _telaresController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(localApiHealthProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _entryController,
                curve: Curves.easeOutCubic,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 14),
                  _buildConfigCard(),
                  const SizedBox(height: 12),
                  _buildHealthCard(health),
                  if (_infoMessage != null || _errorMessage != null) ...[
                    const SizedBox(height: 10),
                    _buildStatusMessage(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CorporateTokens.navy900,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: CorporateTokens.borderSoft),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuracion API local',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Solo admin: host de impresion y telares con fallback operativo',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hosts operativos',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Formato recomendado: http://192.168.1.34:5001',
            style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _impresionController,
            decoration: const InputDecoration(
              labelText: 'API impresion local',
              hintText: 'http://192.168.1.34:5001',
              prefixIcon: Icon(Icons.print_rounded),
            ),
            keyboardType: TextInputType.url,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telaresController,
            decoration: const InputDecoration(
              labelText: 'API local telares',
              hintText: 'http://192.168.1.43:5000',
              prefixIcon: Icon(Icons.precision_manufacturing_rounded),
            ),
            keyboardType: TextInputType.url,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                  style: FilledButton.styleFrom(
                    backgroundColor: CorporateTokens.cobalt600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _restoreDefaults,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Restaurar por defecto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _saving
                          ? null
                          : () =>
                              ref
                                  .read(localApiHealthProvider.notifier)
                                  .manualRefresh(),
                  icon: const Icon(Icons.network_check_rounded),
                  label: const Text('Probar conexion'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(LocalApiHealthState health) {
    final available = health.available;
    final statusColor =
        available ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                health.checking
                    ? 'Verificando conectividad...'
                    : (available
                        ? 'API local disponible'
                        : 'API local no disponible'),
                style: const TextStyle(
                  color: CorporateTokens.navy900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kv(
            'Host configurado',
            health.configuredBaseUrl.isEmpty ? '-' : health.configuredBaseUrl,
          ),
          _kv('Host activo', health.activeBaseUrl ?? '-'),
          _kv('Fallbacks', health.candidates.join(' | ')),
          _kv('Detalle', health.message ?? '-'),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    final isError = _errorMessage != null;
    final text = _errorMessage ?? _infoMessage ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isError ? AppColors.error : AppColors.success).withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isError ? AppColors.error : AppColors.success).withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String? _normalizeUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) {
      value = 'http://$value';
    }
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return null;
    }
    return value;
  }

  Future<void> _save() async {
    final impresionUrl = _normalizeUrl(_impresionController.text);
    final telaresUrl = _normalizeUrl(_telaresController.text);

    if (impresionUrl == null) {
      setState(() {
        _errorMessage =
            'URL de impresion invalida. Ejemplo: http://192.168.1.34:5001';
        _infoMessage = null;
      });
      return;
    }

    if (telaresUrl == null) {
      setState(() {
        _errorMessage =
            'URL de telares invalida. Ejemplo: http://192.168.1.43:5000';
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
      _infoMessage = null;
      _impresionController.text = impresionUrl;
      _telaresController.text = telaresUrl;
    });

    try {
      final storage = ref.read(localStorageProvider);
      await storage.setLocalApiUrl(impresionUrl);
      await storage.setTelaresLocalApiUrl(telaresUrl);
      await ref.read(localApiHealthProvider.notifier).manualRefresh();

      setState(() {
        _infoMessage =
            'Configuracion guardada. Se aplicara de inmediato en los modulos.';
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'No se pudo guardar configuracion: $error';
        _infoMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _restoreDefaults() async {
    setState(() {
      _impresionController.text = EnvironmentConfig.localApiUrl;
      _telaresController.text = EnvironmentConfig.telaresLocalApiUrl;
      _infoMessage = null;
      _errorMessage = null;
    });
    await _save();
  }
}
