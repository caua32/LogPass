import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _razaoCtrl = TextEditingController();
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
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    _cnpjCtrl.dispose();
    _razaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _erro = ''; });
    if (_nomeCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) {
      setState(() { _erro = 'Preencha todos os campos.'; });
      return;
    }
    if (_tipo == null) {
      setState(() { _erro = 'Selecione o tipo de usuário.'; });
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.registrar(_nomeCtrl.text.trim(), _emailCtrl.text.trim(), _senhaCtrl.text, _tipo!);
      final token = res['token'] as String;
      if (_tipo == 'consumidor') {
        await ApiService.addConsumidor(token, {
          'cpf': _cpfCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
        });
      } else {
        await ApiService.addEmpresa(token, {
          'cnpj': _cnpjCtrl.text.trim(),
          'razao_social': _razaoCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Color(0xFF4CE0D2),
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
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
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
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
                            const Icon(Icons.computer, size: 48, color: Color(0xFF4CE0D2)),
                            const SizedBox(width: 16),
                            AnimatedBuilder(
                              animation: _typingAnim,
                              builder: (_, __) {
                                const text = 'LogPass';
                                final visible = text.substring(0, (_typingAnim.value * text.length).round());
                                return Row(children: [
                                  Text(visible, style: const TextStyle(
                                    fontSize: 48, fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CE0D2), fontFamily: 'monospace',
                                  )),
                                  if (_typingAnim.value < 1.0)
                                    Container(width: 3, height: 48, color: const Color(0xFF4CE0D2)),
                                ]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 350),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4CE0D2)),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.3), blurRadius: 15,
                    )],
                  ),
                  child: Column(
                    children: [
                      const Text('Cadastro', style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                      )),
                      const SizedBox(height: 20),
                      _buildField('Nome:', _nomeCtrl),
                      const SizedBox(height: 15),
                      _buildField('Email:', _emailCtrl, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _buildField('Senha:', _senhaCtrl, obscure: true),
                      const SizedBox(height: 15),
                      _buildField('Telefone:', _telefoneCtrl, keyboardType: TextInputType.phone),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tipo de Usuário:', style: TextStyle(color: Color(0xFF4CE0D2), fontSize: 16)),
                          const SizedBox(height: 10),
                          _buildRadio('empresa', 'Empresa'),
                          _buildRadio('consumidor', 'Consumidor'),
                        ],
                      ),
                      if (_tipo == 'consumidor') ...[
                        const SizedBox(height: 15),
                        _buildField('CPF:', _cpfCtrl, keyboardType: TextInputType.number),
                      ],
                      if (_tipo == 'empresa') ...[
                        const SizedBox(height: 15),
                        _buildField('CNPJ:', _cnpjCtrl, keyboardType: TextInputType.number),
                        const SizedBox(height: 15),
                        _buildField('Razão Social:', _razaoCtrl),
                      ],
                      const SizedBox(height: 20),
                      if (_loading)
                        const CircularProgressIndicator(color: Color(0xFF4CE0D2))
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CE0D2),
                              foregroundColor: const Color(0xFF0A1929),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              elevation: 0,
                            ),
                            child: const Text('Cadastrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      const SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text('Já possui conta? ', style: TextStyle(color: Color(0xFF4CE0D2))),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Text('Faça login', style: TextStyle(
                              color: Color(0xFF4CE0D2), decoration: TextDecoration.underline,
                            )),
                          ),
                        ],
                      ),
                      if (_erro.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Text(_erro, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14),
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
        Text(label, style: const TextStyle(color: Color(0xFF4CE0D2), fontSize: 16)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF4CE0D2)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A1929),
            contentPadding: const EdgeInsets.all(10),
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
      ),
      Text(label, style: const TextStyle(color: Color(0xFF4CE0D2))),
    ]);
  }
}

