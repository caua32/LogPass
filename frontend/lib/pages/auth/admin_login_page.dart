import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/admin_auth_service.dart';
import '../../core/particles_background.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _erro = '';

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
    _logoFade = CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut));

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
    _userCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _erro = '');
    if (_userCtrl.text.trim().isEmpty || _senhaCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.adminLogin(
          _userCtrl.text.trim(), _senhaCtrl.text.trim());
      final token = res['token'] as String;
      final nome =
          res['funcionario']?['nome'] ?? res['nome'] ?? _userCtrl.text;
      await AdminAuthService.saveSession(token, nome.toString());
      if (mounted) context.go('/admin/dashboard');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = 'Nao foi possivel conectar ao servidor.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const ParticlesBackground(count: 100, showLines: true),
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
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _cyan.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _cyan.withValues(alpha: 0.28)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: _cyan, size: 15),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          // Logo
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
                                          color: _cyan.withValues(alpha: 0.22),
                                          blurRadius: 28,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.admin_panel_settings,
                                        size: 34,
                                        color: _cyan),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'LogPass',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: _cyan,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(color: _cyan, blurRadius: 18)
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _cyan.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: _cyan.withValues(alpha: 0.28)),
                                    ),
                                    child: Text(
                                      'PAINEL ADMINISTRATIVO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: _cyan.withValues(alpha: 0.80),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Card
                          SlideTransition(
                            position: _cardSlide,
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    width: double.infinity,
                                    constraints:
                                        const BoxConstraints(maxWidth: 380),
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: _card.withValues(alpha: 0.88),
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border: Border.all(
                                          color:
                                              _cyan.withValues(alpha: 0.18)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Acesso restrito',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFE8F8F7),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Apenas administradores autorizados',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color:
                                                _cyan.withValues(alpha: 0.50),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        _buildField('Email', _userCtrl,
                                            Icons.person_outline),
                                        const SizedBox(height: 16),
                                        _buildField(
                                          'Senha',
                                          _senhaCtrl,
                                          Icons.lock_outline,
                                          obscure: _obscure,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscure
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                              color: _cyan.withValues(
                                                  alpha: 0.6),
                                              size: 18,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscure = !_obscure),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _buildBotao(),
                                        if (_erro.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF6B6B)
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: const Color(
                                                          0xFFFF6B6B)
                                                      .withValues(alpha: 0.35)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.error_outline,
                                                    color: Color(0xFFFF6B6B),
                                                    size: 16),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _erro,
                                                    style: const TextStyle(
                                                        color: Color(0xFFFF6B6B),
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool obscure = false,
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
          onSubmitted: (_) => _login(),
          style: const TextStyle(color: Color(0xFFE8F8F7), fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF071520),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(icon,
                color: _cyan.withValues(alpha: 0.5), size: 18),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: _cyan.withValues(alpha: 0.18)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: _cyan.withValues(alpha: 0.18)),
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

  Widget _buildBotao() {
    if (_loading) {
      return SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            color: _cyan,
            strokeWidth: 2,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text(
          'Entrar no Painel',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
