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

  late AnimationController _fadeCtrl;
  late AnimationController _typingCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _typingAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(duration: const Duration(seconds: 3), vsync: this)
      ..repeat(reverse: true);
    _fadeAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));

    _typingCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _typingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _typingCtrl, curve: Curves.easeInOut));
    _typingCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _typingCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _erro = ''; });
    if (_emailCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) {
      setState(() { _erro = 'Preencha todos os campos.'; });
      return;
    }
    if (_tipo == null) {
      setState(() { _erro = 'Selecione o tipo de usuário.'; });
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await context.read<AuthProvider>().login(
          _emailCtrl.text.trim(), _senhaCtrl.text, _tipo!);
      if (!ok && mounted) setState(() { _erro = 'Email ou senha incorretos.'; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _erro = e.message; });
    } catch (_) {
      if (mounted) setState(() { _erro = 'Não foi possível conectar ao servidor.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/login'),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: const Color(0xFF4CE0D2),
        mini: true,
        child: const Icon(Icons.admin_panel_settings, size: 16),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: Stack(
        children: [
          const ParticlesBackground(),
          // Radial vignette
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Color(0x000A1929), Color(0xCC0A1929)],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SizedBox(
                      height: 110,
                      child: AnimatedBuilder(
                        animation: _fadeAnim,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, (_fadeAnim.value - 0.6) * 8),
                          child: Opacity(
                            opacity: _fadeAnim.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(
                                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        )],
                                      ),
                                      child: const Icon(Icons.computer, size: 34, color: Color(0xFF4CE0D2)),
                                    ),
                                    const SizedBox(width: 12),
                                    AnimatedBuilder(
                                      animation: _typingAnim,
                                      builder: (_, __) {
                                        const text = 'LogPass';
                                        final visible = text.substring(0, (_typingAnim.value * text.length).round());
                                        return Row(children: [
                                          Text(visible, style: const TextStyle(
                                            fontSize: 34, fontWeight: FontWeight.bold,
                                            color: Color(0xFF4CE0D2), fontFamily: 'monospace',
                                            letterSpacing: 2,
                                            shadows: [Shadow(color: Color(0xFF4CE0D2), blurRadius: 14)],
                                          )),
                                          if (_typingAnim.value < 1.0)
                                            Container(width: 2, height: 34, color: const Color(0xFF4CE0D2)),
                                        ]);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gerenciamento de Reclamações',
                                  style: TextStyle(
                                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.5),
                                    fontSize: 11,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Card with glassmorphism
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xFF102A43).withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF4CE0D2).withValues(alpha: 0.45),
                            ),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF4CE0D2).withValues(alpha: 0.12),
                              blurRadius: 32,
                              spreadRadius: 2,
                            )],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Entrar', style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold,
                                color: Color(0xFF4CE0D2), letterSpacing: 1,
                              )),
                              const SizedBox(height: 8),
                              Container(
                                width: 36, height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CE0D2),
                                  borderRadius: BorderRadius.circular(1),
                                  boxShadow: [BoxShadow(
                                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  )],
                                ),
                              ),
                              const SizedBox(height: 22),
                              _buildField('Email', _emailCtrl,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 14),
                              _buildField('Senha', _senhaCtrl,
                                  icon: Icons.lock_outline,
                                  obscure: !_senhaVisivel,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _senhaVisivel
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                                  )),
                              const SizedBox(height: 16),
                              // Tipo de usuário
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1929).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tipo de Usuário', style: TextStyle(
                                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    )),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(child: _buildRadio('empresa', 'Empresa')),
                                        Expanded(child: _buildRadio('consumidor', 'Consumidor')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (_loading)
                                const SizedBox(
                                  height: 44,
                                  child: Center(child: CircularProgressIndicator(
                                    color: Color(0xFF4CE0D2), strokeWidth: 2,
                                  )),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CE0D2),
                                      foregroundColor: const Color(0xFF0A1929),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Entrar', style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1,
                                    )),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text('Não possui conta? ', style: TextStyle(
                                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.6),
                                    fontSize: 13,
                                  )),
                                  GestureDetector(
                                    onTap: () => context.push('/register'),
                                    child: const Text('Cadastre-se', style: TextStyle(
                                      color: Color(0xFF4CE0D2),
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    )),
                                  ),
                                ],
                              ),
                              if (_erro.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Color(0xFFFF6B6B), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_erro, style: const TextStyle(
                                          color: Color(0xFFFF6B6B), fontSize: 12,
                                        )),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboardType, IconData? icon, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          color: const Color(0xFF4CE0D2).withValues(alpha: 0.8),
          fontSize: 12,
          letterSpacing: 0.5,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF4CE0D2), fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A1929).withValues(alpha: 0.7),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF4CE0D2).withValues(alpha: 0.6), size: 18)
                : null,
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

  Widget _buildRadio(String value, String label) {
    final selected = _tipo == value;
    return GestureDetector(
      onTap: () => setState(() => _tipo = value),
      child: Row(children: [
        Radio<String>(
          value: value, groupValue: _tipo,
          onChanged: (v) => setState(() => _tipo = v),
          activeColor: const Color(0xFF4CE0D2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: TextStyle(
          color: selected
              ? const Color(0xFF4CE0D2)
              : const Color(0xFF4CE0D2).withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        )),
      ]),
    );
  }
}
