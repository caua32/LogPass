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

class _AdminLoginPageState extends State<AdminLoginPage> with TickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late AnimationController _logoCtrl;
  late AnimationController _formCtrl;
  late Animation<double> _logoAnim;
  late Animation<double> _formAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _formCtrl = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _logoAnim = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _formAnim = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _formCtrl.dispose();
    _userCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _senhaCtrl.text.trim().isEmpty) {
      _showMsg('Por favor, preencha todos os campos.', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.adminLogin(
          _userCtrl.text.trim(), _senhaCtrl.text.trim());
      final token = res['token'] as String;
      final nome = res['funcionario']?['nome'] ?? res['nome'] ?? _userCtrl.text;
      await AdminAuthService.saveSession(token, nome.toString());
      if (mounted) context.go('/admin/dashboard');
    } on ApiException catch (e) {
      if (mounted) { setState(() => _loading = false); _showMsg(e.message, isError: true); }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showMsg('Não foi possível conectar ao servidor.', isError: true);
      }
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.white : const Color(0xFF0A1929), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? const Color(0xFFFF6B6B) : const Color(0xFF4CE0D2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Stack(
        children: [
          const ParticlesBackground(count: 20),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Color(0x000A1929), Color(0xCC0A1929)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Botão voltar
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Color(0xFF4CE0D2), size: 16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Logo admin
                        AnimatedBuilder(
                          animation: _logoAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _logoAnim.value,
                            child: Column(children: [
                              Container(
                                width: 90, height: 90,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [BoxShadow(
                                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.3),
                                    blurRadius: 24, spreadRadius: 3,
                                  )],
                                ),
                                child: const Icon(Icons.admin_panel_settings,
                                    size: 44, color: Color(0xFF4CE0D2)),
                              ),
                              const SizedBox(height: 18),
                              const Text('LogPass', style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold,
                                color: Color(0xFF4CE0D2), letterSpacing: 2,
                                shadows: [Shadow(color: Color(0xFF4CE0D2), blurRadius: 12)],
                              )),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF102A43),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.4)),
                                ),
                                child: const Text('PAINEL ADMINISTRATIVO', style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CE0D2), letterSpacing: 2,
                                )),
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Card de login
                        SlideTransition(
                          position: _slideAnim,
                          child: FadeTransition(
                            opacity: _formAnim,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(26),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF102A43).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                                    ),
                                    boxShadow: [BoxShadow(
                                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.1),
                                      blurRadius: 30,
                                    )],
                                  ),
                                  child: Column(children: [
                                    const Text('Acesso Restrito', style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CE0D2), letterSpacing: 0.5,
                                    )),
                                    const SizedBox(height: 4),
                                    Text('Apenas administradores autorizados',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.55),
                                        )),
                                    const SizedBox(height: 22),
                                    _buildField('Email / Usuário', _userCtrl,
                                        Icons.person_outline),
                                    const SizedBox(height: 14),
                                    _buildField('Senha', _senhaCtrl, Icons.lock_outline,
                                        obscure: _obscure,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() => _obscure = !_obscure),
                                        )),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4CE0D2),
                                          foregroundColor: const Color(0xFF0A1929),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                          elevation: 0,
                                        ),
                                        child: _loading
                                            ? const SizedBox(width: 20, height: 20,
                                                child: CircularProgressIndicator(
                                                    color: Color(0xFF0A1929), strokeWidth: 2))
                                            : const Text('ENTRAR NO PAINEL', style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2)),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {bool obscure = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          color: const Color(0xFF4CE0D2).withValues(alpha: 0.8),
          fontSize: 12, letterSpacing: 0.5,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          onSubmitted: (_) => _login(),
          style: const TextStyle(color: Color(0xFF4CE0D2), fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A1929).withValues(alpha: 0.7),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: Icon(icon,
                color: const Color(0xFF4CE0D2).withValues(alpha: 0.6), size: 18),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.35)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
