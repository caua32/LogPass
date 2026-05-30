import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/particles_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  String? _tipo;
  String _erro = '';
  bool _loading = false;
  bool _senhaVisivel = false;

  static const _cyan = Color(0xFF44CABD);
  static const _bg = Color(0xFF0A1929);
  static const _card = Color(0xFF0D2137);

  late AnimationController _logoCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut));

    _cardCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _cardCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _erro = '');
    if (_emailCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    if (_tipo == null) {
      setState(() => _erro = 'Selecione o tipo de usuÃ¡rio.');
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await context
          .read<AuthProvider>()
          .login(_emailCtrl.text.trim(), _senhaCtrl.text, _tipo!);
      if (!ok && mounted) setState(() => _erro = 'Email ou senha incorretos.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (_) {
      if (mounted) setState(() => _erro = 'NÃ£o foi possÃ­vel conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/admin/login'),
        backgroundColor: _card,
        foregroundColor: _cyan,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _cyan.withValues(alpha: 0.25)),
        ),
        child: const Icon(Icons.admin_panel_settings, size: 16),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Stack(
        children: [
          const ParticlesBackground(count: 50, showLines: true),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [
                  _bg.withValues(alpha: 0),
                  _bg.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // Logo animado
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _cyan.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _cyan.withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _cyan.withValues(alpha: 0.25),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.computer,
                                    size: 34, color: _cyan),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'LogPass',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: _cyan,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(color: _cyan, blurRadius: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'GERENCIAMENTO DE RECLAMAÃ‡Ã•ES',
                                style: TextStyle(
                                  color: _cyan.withValues(alpha: 0.40),
                                  fontSize: 9,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Card animado
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxWidth: 380),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: _card.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _cyan.withValues(alpha: 0.18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 40,
                                      offset: const Offset(0, 16),
                                    ),
                                    BoxShadow(
                                      color: _cyan.withValues(alpha: 0.06),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bem-vindo de volta',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE8F8F7),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Entre com suas credenciais para continuar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _cyan.withValues(alpha: 0.50),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    _buildField('Email', _emailCtrl,
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress),
                                    const SizedBox(height: 16),
                                    _buildField('Senha', _senhaCtrl,
                                        icon: Icons.lock_outline,
                                        obscure: !_senhaVisivel,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _senhaVisivel
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: _cyan.withValues(alpha: 0.6),
                                            size: 18,
                                          ),
                                          onPressed: () => setState(
                                              () => _senhaVisivel = !_senhaVisivel),
                                        )),
                                    const SizedBox(height: 16),
                                    _buildTipoSelector(),
                                    const SizedBox(height: 24),
                                    _buildBotao(),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        children: [
                                          Text(
                                            'NÃ£o possui conta? ',
                                            style: TextStyle(
                                              color: _cyan.withValues(alpha: 0.5),
                                              fontSize: 13,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.push('/register'),
                                            child: const Text(
                                              'Cadastre-se',
                                              style: TextStyle(
                                                color: _cyan,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                                decorationColor: _cyan,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_erro.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      _buildErro(),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    TextInputType? keyboardType,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _cyan.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFE8F8F7), fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF071520),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: icon != null
                ? Icon(icon, color: _cyan.withValues(alpha: 0.5), size: 18)
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _cyan.withValues(alpha: 0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _cyan.withValues(alpha: 0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _cyan, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipoSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF071520),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIPO DE USUÃRIO',
            style: TextStyle(
              color: _cyan.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTipoOption('empresa', Icons.business_outlined, 'Empresa')),
              const SizedBox(width: 10),
              Expanded(child: _buildTipoOption('consumidor', Icons.person_outline, 'Consumidor')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipoOption(String value, IconData icon, String label) {
    final selected = _tipo == value;
    return GestureDetector(
      onTap: () => setState(() => _tipo = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _cyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _cyan.withValues(alpha: 0.5) : _cyan.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? _cyan : _cyan.withValues(alpha: 0.4),
                size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? _cyan : _cyan.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotao() {
    if (_loading) {
      return SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            color: _cyan, strokeWidth: 2,
            backgroundColor: _cyan.withValues(alpha: 0.15),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: _bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          shadowColor: _cyan.withValues(alpha: 0.4),
        ),
        child: const Text(
          'Entrar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _erro,
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
