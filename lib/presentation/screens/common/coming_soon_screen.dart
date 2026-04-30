import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/enterprise_backdrop.dart';

class ComingSoonScreen extends StatefulWidget {
  final String moduleName;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.moduleName,
    this.icon = Icons.construction_rounded,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _iconScale;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeAnim);

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.20, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _pulse = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CorporateTokens.borderSoft),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: CorporateTokens.navy900, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.moduleName,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _iconScale,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Transform.scale(scale: _pulse.value, child: child);
                },
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CorporateTokens.cobalt600.withValues(alpha: 0.08),
                    border: Border.all(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CorporateTokens.cobalt600.withValues(alpha: 0.08),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 52,
                    color: CorporateTokens.cobalt600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _StaggerReveal(
              parent: _entryController,
              begin: 0.35,
              end: 0.65,
              child: const Text(
                'En Desarrollo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CorporateTokens.navy900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _StaggerReveal(
              parent: _entryController,
              begin: 0.45,
              end: 0.75,
              child: Text(
                'El modulo "${widget.moduleName}" estara\ndisponible muy pronto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: CorporateTokens.slate500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _StaggerReveal(
              parent: _entryController,
              begin: 0.55,
              end: 0.82,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: CorporateTokens.surfaceBottom,
                  border: Border.all(color: CorporateTokens.borderSoft),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16,
                        color: CorporateTokens.slate500),
                    const SizedBox(width: 8),
                    Text(
                      'Mientras tanto, usa la version anterior',
                      style: TextStyle(
                        fontSize: 12,
                        color: CorporateTokens.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _StaggerReveal(
              parent: _entryController,
              begin: 0.62,
              end: 0.92,
              child: _buildProgressIndicator(),
            ),
            const SizedBox(height: 32),
            _StaggerReveal(
              parent: _entryController,
              begin: 0.70,
              end: 1.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: CorporateTokens.primaryButtonGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CorporateTokens.cobalt600.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Volver al Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        return Column(
          children: [
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.3 + (math.sin(t * math.pi) * 0.15),
                  backgroundColor: CorporateTokens.steel200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CorporateTokens.cobalt600.withValues(alpha: 0.50),
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progreso de migracion',
              style: TextStyle(
                color: CorporateTokens.slate300,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaggerReveal extends StatelessWidget {
  final AnimationController parent;
  final double begin;
  final double end;
  final Widget child;

  const _StaggerReveal({
    required this.parent,
    required this.begin,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: parent,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
