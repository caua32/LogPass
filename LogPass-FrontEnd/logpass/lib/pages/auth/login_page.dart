import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

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
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _fadeAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, (_fadeAnim.value - 0.6) * 10),
                      child: Opacity(
                        opacity: _fadeAnim.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.computer, size: 32, color: Color(0xFF4CE0D2)),
                            const SizedBox(width: 12),
                            AnimatedBuilder(
                              animation: _typingAnim,
                              builder: (_, __) {
                                const text = 'LogPass';
                                final visible = text.substring(0, (_typingAnim.value * text.length).round());
                                return Row(children: [
                                  Text(visible, style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CE0D2), fontFamily: 'monospace',
                                  )),
                                  if (_typingAnim.value < 1.0)
                                    Container(width: 2, height: 32, color: const Color(0xFF4CE0D2)),
                                ]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 350),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4CE0D2)),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.3),
                      blurRadius: 15,
                    )],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Login', style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                      )),
                      const SizedBox(height: 16),
                      _buildField('Email:', _emailCtrl, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildField('Senha:', _senhaCtrl, obscure: true),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tipo de Usuário:', style: TextStyle(color: Color(0xFF4CE0D2), fontSize: 14)),
                          const SizedBox(height: 8),
                          _buildRadio('empresa', 'Empresa'),
                          _buildRadio('consumidor', 'Consumidor'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const CircularProgressIndicator(color: Color(0xFF4CE0D2))
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CE0D2),
                              foregroundColor: const Color(0xFF0A1929),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              elevation: 0,
                            ),
                            child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text('Não possui conta? ', style: TextStyle(color: Color(0xFF4CE0D2), fontSize: 14)),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text('Cadastre-se', style: TextStyle(
                              color: Color(0xFF4CE0D2), decoration: TextDecoration.underline, fontSize: 14,
                            )),
                          ),
                        ],
                      ),
                      if (_erro.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(_erro, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF4CE0D2), fontSize: 14)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF4CE0D2)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A1929),
            isDense: true,
            contentPadding: const EdgeInsets.all(8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildRadio(String value, String label) {
    return Row(children: [
      Radio<String>(
        value: value, groupValue: _tipo,
        onChanged: (v) => setState(() => _tipo = v),
        activeColor: const Color(0xFF4CE0D2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      Text(label, style: const TextStyle(color: Color(0xFF4CE0D2), fontSize: 14)),
    ]);
  }
}

