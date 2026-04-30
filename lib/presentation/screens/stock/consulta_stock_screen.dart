import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/consulta_stock_qr_codec.dart';
import '../../../data/datasources/remote/legacy_modules_remote_datasource.dart';
import '../../providers/consulta_stock_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/scanner/qr_scanner_page.dart';

class ConsultaStockScreen extends ConsumerStatefulWidget {
  const ConsultaStockScreen({super.key});

  @override
  ConsumerState<ConsultaStockScreen> createState() =>
      _ConsultaStockScreenState();
}

class _ConsultaStockScreenState extends ConsumerState<ConsultaStockScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _codigoController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    ref.read(consultaStockProvider.notifier).consultar(_codigoController.text);
  }

  void _limpiar() {
    FocusScope.of(context).unfocus();
    _codigoController.clear();
    ref.read(consultaStockProvider.notifier).reset();
  }

  Future<void> _scanCodigo() async {
    final scanned = await openQrScanner(
      context,
      title: 'Escanear codigo para consulta stock',
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;

    final resolved = ConsultaStockQrCodec.resolveInput(scanned.trim());
    _codigoController.text = resolved.codigoConsulta;
    _buscar();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consultaStockProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 12),
                      _buildSearchCard(state),
                      const SizedBox(height: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child: _buildBody(state),
                        ),
                      ),
                    ],
                  ),
                ),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consulta Stock PCP',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Flujo legacy MIT con /stock_actual_pcp (19 campos)',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard(ConsultaStockState state) {
    final isLoading = state.status == ConsultaStockStatus.loading;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Codigo PCP / QR',
            style: TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codigoController,
            style: const TextStyle(color: CorporateTokens.navy900),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            decoration: InputDecoration(
              hintText: 'Escanee QR completo o ingrese codigo PCP/Kardex',
              hintStyle: const TextStyle(color: CorporateTokens.slate300),
              prefixIcon: const Icon(
                Icons.qr_code_2_rounded,
                color: CorporateTokens.cobalt600,
              ),
              suffixIcon: IconButton(
                onPressed: _scanCodigo,
                tooltip: 'Escanear con camara',
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: CorporateTokens.slate500,
                ),
              ),
              filled: true,
              fillColor: CorporateTokens.surfaceTop,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CorporateTokens.borderSoft),
              ),
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
            ),
          ),
          if (state.codigoPcpDetectado.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _detectChip(
                  label: 'PCP',
                  value: state.codigoPcpDetectado,
                  icon: Icons.confirmation_number_rounded,
                  highlight: true,
                ),
                if (state.codigoKardexDetectado.trim().isNotEmpty)
                  _detectChip(
                    label: 'Kardex',
                    value: state.codigoKardexDetectado,
                    icon: Icons.qr_code_2_rounded,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: CorporateTokens.primaryButtonGradient,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _buscar,
                      icon:
                          isLoading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.search_rounded),
                      label: Text(isLoading ? 'Consultando...' : 'Consultar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: isLoading ? null : _limpiar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CorporateTokens.cobalt600,
                    side: BorderSide(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.30),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ConsultaStockState state) {
    switch (state.status) {
      case ConsultaStockStatus.initial:
        return _buildMessageCard(
          icon: Icons.inventory_2_rounded,
          title: 'Listo para consultar',
          subtitle:
              'Escanee un QR de hilos o ingrese codigo PCP. Se consultara /stock_actual_pcp con formato legacy.',
          accent: CorporateTokens.cobalt600,
        );
      case ConsultaStockStatus.loading:
        return _buildMessageCard(
          icon: Icons.sync_rounded,
          title: 'Consultando backend...',
          subtitle: 'Consultando /stock_actual_pcp y mapeando 19 campos.',
          accent: CorporateTokens.cobalt600,
          loading: true,
        );
      case ConsultaStockStatus.error:
        return _buildMessageCard(
          icon: Icons.error_outline_rounded,
          title: 'No se pudo completar la consulta',
          subtitle: state.errorMessage ?? 'Error desconocido',
          accent: const Color(0xFFDC2626),
          actionLabel: 'Reintentar',
          onAction: _buscar,
        );
      case ConsultaStockStatus.success:
        final result = state.result!;
        return SingleChildScrollView(
          key: ValueKey<String>('ok-${result.codigoConsultado}'),
          child: Column(
            children: [
              _buildResultHeader(
                code: result.stock.codigoPcp,
                kardex: result.stock.codigoKardex,
              ),
              const SizedBox(height: 10),
              _buildStockCard(result.stock),
            ],
          ),
        );
    }
  }

  Widget _buildResultHeader({required String code, required String kardex}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consulta exitosa: $code',
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (kardex.trim().isNotEmpty)
                  Text(
                    'Kardex: $kardex',
                    style: const TextStyle(
                      color: CorporateTokens.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(IngresoStockActualData stock) {
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
          _buildLegacySingleBlock(
            label: 'CODIGO KARDEX',
            value: _safe(stock.codigoKardex),
            backgroundColor: const Color(0xFFE5E7EB),
            borderColor: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE48A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2BE52)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegacySingleField(
                  label: 'CODIGO PCP',
                  value: _safe(stock.codigoPcp),
                ),
                _buildLegacySingleField(
                  label: 'MATERIAL',
                  value: _safe(stock.material),
                ),
                _buildLegacySingleField(
                  label: 'TITULO',
                  value: _safe(stock.titulo),
                ),
                _buildLegacySingleField(
                  label: 'COLOR',
                  value: _safe(stock.color),
                ),
                _buildLegacyPairField(
                  leftLabel: 'LOTE',
                  leftValue: _safe(stock.lote),
                  rightLabel: 'CAJA',
                  rightValue: _safe(stock.numCajas),
                ),
                _buildLegacyPairField(
                  leftLabel: 'BOBINA/CONO',
                  leftValue: _safe(stock.totalBobinas),
                  rightLabel: 'REENCONADO',
                  rightValue: _safe(stock.cantidadReenconado),
                ),
                _buildLegacyPairField(
                  leftLabel: 'PESO BRUTO',
                  leftValue: _safe(stock.pesoBruto),
                  rightLabel: 'PESO NETO',
                  rightValue: _safe(stock.pesoNeto),
                ),
                _buildLegacySingleField(
                  label: 'PROVEEDOR',
                  value: _safe(stock.proveedor),
                ),
                _buildLegacySingleField(
                  label: 'FECHA DE INGRESO',
                  value: _safe(stock.fechaIngreso),
                ),
                _buildLegacySingleField(
                  label: 'FECHA DE SALIDA',
                  value: _fallbackSalida(
                    stock.fechaSalida,
                    'Sin Fecha de Salida',
                  ),
                ),
                _buildLegacySingleField(
                  label: 'HORA DE SALIDA',
                  value: _fallbackSalida(
                    stock.horaSalida,
                    'Sin Hora de Salida',
                  ),
                ),
                _buildLegacyPairField(
                  leftLabel: 'ALMACEN',
                  leftValue: _safe(stock.almacen),
                  rightLabel: 'UBICACION',
                  rightValue: _safe(stock.ubicacion),
                ),
                _buildLegacySingleField(
                  label: 'SERVICIO',
                  value: _safe(stock.servicio),
                ),
                _buildLegacySingleField(
                  label: 'NOMBRE',
                  value: _safe(stock.nombre),
                  withBottomDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _safe(String value) {
    final clean = value.trim();
    return clean.isEmpty ? '-' : clean;
  }

  String _fallbackSalida(String value, String fallback) {
    final clean = value.trim();
    return clean.isEmpty ? fallback : clean;
  }

  Widget _detectChip({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE9F4FF) : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight ? const Color(0xFFB9DAFF) : const Color(0xFFD9E4F2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                highlight
                    ? CorporateTokens.cobalt600
                    : CorporateTokens.slate500,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color:
                  highlight
                      ? CorporateTokens.cobalt600
                      : CorporateTokens.navy900,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySingleBlock({
    required String label,
    required String value,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildLegacySingleField(
              label: label,
              value: value,
              withBottomDivider: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacySingleField({
    required String label,
    required String value,
    bool withBottomDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            decoration:
                withBottomDivider
                    ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0x996B7280), width: 1),
                      ),
                    )
                    : null,
            child: Text(
              value,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyPairField({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 420;
        if (stack) {
          return Column(
            children: [
              _buildLegacySingleField(label: leftLabel, value: leftValue),
              _buildLegacySingleField(label: rightLabel, value: rightValue),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLegacySingleField(
                label: leftLabel,
                value: leftValue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildLegacySingleField(
                label: rightLabel,
                value: rightValue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    String? actionLabel,
    VoidCallback? onAction,
    bool loading = false,
  }) {
    return Container(
      key: ValueKey<String>('message-$title'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: CorporateTokens.cobalt600,
              ),
            )
          else
            Icon(icon, color: accent, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.40)),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
