import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/admin_auth_service.dart';

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
    _logoCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _formCtrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _logoAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _formAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutBack));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () => _formCtrl.forward());
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
      final res = await ApiService.adminLogin(_userCtrl.text.trim(), _senhaCtrl.text.trim());
      final token = res['token'] as String;
      final nome = res['funcionario']?['nome'] ?? res['nome'] ?? _userCtrl.text;
      await AdminAuthService.saveSession(token, nome.toString());
      if (mounted) context.go('/admin/dashboard');
    } on ApiException catch (e) {
      if (mounted) { setState(() => _loading = false); _showMsg(e.message, isError: true); }
    } catch (_) {
      if (mounted) { setState(() => _loading = false); _showMsg('Não foi possível conectar ao servidor.', isError: true); }
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red : const Color(0xFF4CE0D2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4CE0D2)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _logoAnim,
              builder: (_, __) => Transform.scale(
                scale: _logoAnim.value,
                child: Column(children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CE0D2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                        blurRadius: 20, spreadRadius: 5,
                      )],
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF0A1929)),
                  ),
                  const SizedBox(height: 30),
                  const Text('LogPass', style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102A43),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF4CE0D2)),
                    ),
                    child: const Text('PAINEL ADMINISTRATIVO', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Color(0xFF4CE0D2), letterSpacing: 1.2,
                    )),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 60),
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _formAnim,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.1),
                      blurRadius: 20, offset: const Offset(0, 10),
                    )],
                  ),
                  child: Column(children: [
                    const Text('Acesso Restrito', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                    )),
                    const SizedBox(height: 8),
                    Text('Apenas administradores autorizados', style: TextStyle(
                      fontSize: 14, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                    )),
                    const SizedBox(height: 30),
                    _buildField('Email / Usuário', _userCtrl, Icons.person),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _senhaCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: Color(0xFF4CE0D2)),
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        labelStyle: const TextStyle(color: Color(0xFF4CE0D2)),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF4CE0D2)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF4CE0D2)),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CE0D2),
                          foregroundColor: const Color(0xFF0A1929),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Color(0xFF0A1929), strokeWidth: 2))
                            : const Text('ENTRAR NO PAINEL', style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Color(0xFF4CE0D2)),
      onSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4CE0D2)),
        prefixIcon: Icon(icon, color: const Color(0xFF4CE0D2)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 2)),
      ),
    );
  }
}

