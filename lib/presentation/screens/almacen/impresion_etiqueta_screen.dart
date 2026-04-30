import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/impresion_etiqueta_provider.dart';
import '../../widgets/local_api_status_chip.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class ImpresionEtiquetaScreen extends ConsumerStatefulWidget {
  const ImpresionEtiquetaScreen({super.key});

  @override
  ConsumerState<ImpresionEtiquetaScreen> createState() =>
      _ImpresionEtiquetaScreenState();
}

class _ImpresionEtiquetaScreenState
    extends ConsumerState<ImpresionEtiquetaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _qrController;
  late final TextEditingController _materialController;
  late final TextEditingController _tituloController;
  late final TextEditingController _colorController;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _qrController = TextEditingController();
    _materialController = TextEditingController();
    _tituloController = TextEditingController();
    _colorController = TextEditingController();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();

    Future.microtask(
      () => ref.read(impresionEtiquetaProvider.notifier).refrescarEstadoApi(),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _qrController.dispose();
    _materialController.dispose();
    _tituloController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(impresionEtiquetaProvider);
    final notifier = ref.read(impresionEtiquetaProvider.notifier);
    final usuario = ref.watch(authProvider).user?.usuario ?? 'OPERARIO';
    final sidePadding = MediaQuery.sizeOf(context).width >= 920 ? 28.0 : 16.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CorporateTokens.surfaceTop, CorporateTokens.surfaceBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 16),
            child: Column(
              children: [
                _buildHeader(context, state, notifier),
                const SizedBox(height: 10),
                _buildBanner(state),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.05,
                            end: 0.55,
                            child: _buildQrCard(state, notifier),
                          ),
                          const SizedBox(height: 10),
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.10,
                            end: 0.68,
                            child: _buildKardexCard(state, notifier),
                          ),
                          const SizedBox(height: 10),
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.18,
                            end: 0.75,
                            child: _buildActionsCard(
                              state: state,
                              notifier: notifier,
                              usuario: usuario,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _StaggerReveal(
                            controller: _entryController,
                            start: 0.28,
                            end: 0.95,
                            child: _buildQueueCard(state, notifier),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanQr(
    ImpresionEtiquetaNotifier notifier,
    ImpresionEtiquetaState state,
  ) async {
    if (state.isBusy) return;

    final result = await openQrScanner(
      context,
      title: 'Escanear QR para etiqueta',
    );
    if (!mounted || result == null || result.trim().isEmpty) return;

    _qrController.text = result;
    notifier.setQrRaw(result);
  }

  Widget _buildHeader(
    BuildContext context,
    ImpresionEtiquetaState state,
    ImpresionEtiquetaNotifier notifier,
  ) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: CorporateTokens.borderSoft),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CorporateTokens.navy900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actualizar etiqueta',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state.localApiDisponible
                    ? 'Impresion Zebra disponible'
                    : 'Impresion Zebra offline (cola activa)',
                style: const TextStyle(
                  color: CorporateTokens.slate500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const LocalApiStatusChip(compact: true),
            const SizedBox(height: 6),
            IconButton(
              onPressed: state.isBusy ? null : notifier.refrescarEstadoApi,
              tooltip: 'Refrescar estado API local',
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: CorporateTokens.surfaceBottom,
                side: const BorderSide(color: CorporateTokens.borderSoft),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                color: CorporateTokens.slate500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBanner(ImpresionEtiquetaState state) {
    final hasError = (state.errorMessage ?? '').isNotEmpty;
    final hasMessage = (state.message ?? '').isNotEmpty;
    if (!hasError && !hasMessage) return const SizedBox.shrink();

    final isError = hasError;
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final borderColor =
        isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final iconColor =
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final text = isError ? state.errorMessage! : state.message!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(
    ImpresionEtiquetaState state,
    ImpresionEtiquetaNotifier notifier,
  ) {
    return _GlassBlock(
      title: 'Datos QR para etiqueta',
      child: Column(
        children: [
          TextFormField(
            controller: _qrController,
            onChanged: notifier.setQrRaw,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: CorporateTokens.navy900),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Ingrese o escanee un QR';
              }
              return null;
            },
            decoration: _inputDecoration(
              label: 'Texto QR',
              hint: 'Pega el string completo del QR',
              icon: Icons.qr_code_2_rounded,
              suffixIcon: IconButton(
                onPressed: () => _scanQr(notifier, state),
                tooltip: 'Escanear con camara',
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: CorporateTokens.slate500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () async {
                        if (_formKey.currentState?.validate() != true) {
                          return;
                        }
                        await notifier.parsearQr();
                      },
              icon:
                  state.status == ImpresionEtiquetaStatus.parsing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CorporateTokens.cobalt600,
                        ),
                      )
                      : const Icon(Icons.analytics_rounded),
              label: const Text('Parsear QR para etiqueta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: CorporateTokens.cobalt600,
                side: BorderSide(
                  color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          if (state.payload != null) ...[
            const SizedBox(height: 10),
            _buildPayloadPreview(state),
          ],
        ],
      ),
    );
  }

  Widget _buildKardexCard(
    ImpresionEtiquetaState state,
    ImpresionEtiquetaNotifier notifier,
  ) {
    final isGenerating =
        state.status == ImpresionEtiquetaStatus.generatingKardex;

    return _GlassBlock(
      title: 'Generador de Kardex',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Replica MIT: usa /generar_kardex con material, titulo y color. Si hay un QR de hilos cargado, el kardex generado se aplica a la vista previa y al QR impreso.',
            style: TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final fields = [
                TextFormField(
                  controller: _materialController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Material',
                    hint: 'Ejemplo: POLYESTER',
                    icon: Icons.category_rounded,
                  ),
                ),
                TextFormField(
                  controller: _tituloController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Titulo',
                    hint: 'Ejemplo: 75/36/1 P.A',
                    icon: Icons.short_text_rounded,
                  ),
                ),
                TextFormField(
                  controller: _colorController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: CorporateTokens.navy900),
                  decoration: _inputDecoration(
                    label: 'Color',
                    hint: 'Ejemplo: VERDE MILITAR 577-18',
                    icon: Icons.palette_rounded,
                  ),
                ),
              ];

              if (compact) {
                return Column(
                  children:
                      fields
                          .map(
                            (field) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: field,
                            ),
                          )
                          .toList(),
                );
              }

              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 10),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 10),
                  Expanded(child: fields[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.isBusy
                          ? null
                          : () => notifier.generarKardex(
                            material: _materialController.text,
                            titulo: _tituloController.text,
                            color: _colorController.text,
                          ),
                  icon:
                      isGenerating
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CorporateTokens.cobalt600,
                            ),
                          )
                          : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    isGenerating ? 'Generando Kardex...' : 'Generar Kardex',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ),
              if (state.generatedKardex.trim().isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.generatedKardex,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CorporateTokens.navy900,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayloadPreview(ImpresionEtiquetaState state) {
    final payload = state.payload!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceBottom,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa de etiqueta',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _line('Codigo', payload.codigo.isEmpty ? '-' : payload.codigo),
          _line(
            'Kardex',
            payload.codigoKardex.isEmpty ? '-' : payload.codigoKardex,
          ),
          _line('Lote', payload.lote.isEmpty ? '-' : payload.lote),
          _line('Articulo', payload.articulo.isEmpty ? '-' : payload.articulo),
          _line('Metraje', payload.metraje.isEmpty ? '-' : payload.metraje),
          _line(
            'Revisador',
            payload.revisador.isEmpty ? '-' : payload.revisador,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceTop,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Text(
              payload.text,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard({
    required ImpresionEtiquetaState state,
    required ImpresionEtiquetaNotifier notifier,
    required String usuario,
  }) {
    return _GlassBlock(
      title: 'Impresion con fallback offline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceTop,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Text(
              'Usuario operativo: $usuario\nSi la API local esta offline, la etiqueta se guarda en cola automaticamente.',
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: CorporateTokens.primaryButtonGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () async {
                        if (_formKey.currentState?.validate() != true) {
                          return;
                        }
                        await notifier.imprimirConFallbackOffline();
                      },
              icon:
                  state.status == ImpresionEtiquetaStatus.printing ||
                          state.status == ImpresionEtiquetaStatus.queueing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.print_rounded),
              label: Text(
                state.status == ImpresionEtiquetaStatus.printing
                    ? 'Generando e imprimiendo...'
                    : state.status == ImpresionEtiquetaStatus.queueing
                    ? 'Guardando en cola segura...'
                    : 'Imprimir etiqueta (con fallback)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                disabledBackgroundColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () {
                        _formKey.currentState?.reset();
                        _qrController.clear();
                        _materialController.clear();
                        _tituloController.clear();
                        _colorController.clear();
                        notifier.limpiarFormulario();
                      },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Limpiar formulario'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(
    ImpresionEtiquetaState state,
    ImpresionEtiquetaNotifier notifier,
  ) {
    return _GlassBlock(
      title: 'Cola local de etiquetas pendientes',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: CorporateTokens.surfaceTop,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CorporateTokens.borderSoft),
            ),
            child: Row(
              children: [
                Text(
                  'Pendientes: ${state.queue.length}',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  state.localApiDisponible
                      ? 'API local: online'
                      : 'API local: offline',
                  style: TextStyle(
                    color:
                        state.localApiDisponible
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      state.isBusy ? null : notifier.procesarColaPendiente,
                  icon:
                      state.status == ImpresionEtiquetaStatus.drainingQueue
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CorporateTokens.cobalt600,
                            ),
                          )
                          : const Icon(Icons.playlist_play_rounded),
                  label: const Text('Procesar cola'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                    minimumSize: const Size.fromHeight(42),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    state.isBusy || state.queue.isEmpty
                        ? null
                        : notifier.limpiarCola,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CorporateTokens.cobalt600,
                  side: BorderSide(
                    color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                  ),
                  minimumSize: const Size(112, 42),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.queue.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CorporateTokens.surfaceTop,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CorporateTokens.borderSoft),
              ),
              child: const Text(
                'No hay impresiones pendientes.',
                style: TextStyle(color: CorporateTokens.slate300, fontSize: 12),
              ),
            )
          else
            ...state.queue.map(
              (job) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _QueueTile(
                  codigo: job.codigo.isEmpty ? 'Sin codigo' : job.codigo,
                  articulo: job.articulo.isEmpty ? '-' : job.articulo,
                  createdAt: _formatDate(job.createdAtIso),
                  attempts: job.attempts,
                  onDelete:
                      state.isBusy
                          ? null
                          : () => notifier.eliminarTrabajoCola(job.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: CorporateTokens.slate500,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: CorporateTokens.slate500),
      hintStyle: const TextStyle(color: CorporateTokens.slate300),
      prefixIcon: Icon(icon, color: CorporateTokens.slate500, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CorporateTokens.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CorporateTokens.cobalt600,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '-';

    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year;
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }
}

class _QueueTile extends StatelessWidget {
  final String codigo;
  final String articulo;
  final String createdAt;
  final int attempts;
  final VoidCallback? onDelete;

  const _QueueTile({
    required this.codigo,
    required this.articulo,
    required this.createdAt,
    required this.attempts,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.label_rounded,
            color: CorporateTokens.slate500,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  codigo,
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  articulo,
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$createdAt | Reintentos: $attempts',
                  style: const TextStyle(
                    color: CorporateTokens.slate300,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.close_rounded,
              color: CorporateTokens.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _GlassBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StaggerReveal extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;

  const _StaggerReveal({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
