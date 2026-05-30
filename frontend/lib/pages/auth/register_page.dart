import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../core/particles_background.dart';

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
  bool _senhaVisivel = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
    if (_tipo == 'consumidor') {
      if (!RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$').hasMatch(_cpfCtrl.text.trim())) {
        setState(() { _erro = 'CPF inválido. Use o formato 000.000.000-00.'; });
        return;
      }
    } else {
      if (!RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$').hasMatch(_cnpjCtrl.text.trim())) {
        setState(() { _erro = 'CNPJ inválido. Use o formato 00.000.000/0000-00.'; });
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.registrar(
          _nomeCtrl.text.trim(), _emailCtrl.text.trim(), _senhaCtrl.text, _tipo!);
      final token = res['token'] as String;
      if (_tipo == 'consumidor') {
        await ApiService.addConsumidor(token, {
          'nome': _nomeCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'cpf': _cpfCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
        });
      } else {
        await ApiService.addEmpresa(token, {
          'nomeempresa': _razaoCtrl.text.trim(),
          'cnpj': _cnpjCtrl.text.trim(),
          'contato': _telefoneCtrl.text.trim(),
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
          FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                                blurRadius: 16,
                              )],
                            ),
                            child: const Icon(Icons.computer, size: 30, color: Color(0xFF4CE0D2)),
                          ),
                          const SizedBox(width: 10),
                          const Text('LogPass', style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold,
                            color: Color(0xFF4CE0D2), fontFamily: 'monospace',
                            letterSpacing: 2,
                            shadows: [Shadow(color: Color(0xFF4CE0D2), blurRadius: 12)],
                          )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Crie sua conta', style: TextStyle(
                        color: const Color(0xFF4CE0D2).withValues(alpha: 0.5),
                        fontSize: 11,
                        letterSpacing: 2,
                      )),
                      const SizedBox(height: 24),
                      // Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 380),
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
                              children: [
                                const Text('Cadastro', style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold,
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
                                const SizedBox(height: 20),
                                _buildField('Nome completo', _nomeCtrl, icon: Icons.person_outline),
                                const SizedBox(height: 12),
                                _buildField('Email', _emailCtrl,
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 12),
                                _buildField('Telefone', _telefoneCtrl,
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone),
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
                                if (_tipo == 'consumidor') ...[
                                  const SizedBox(height: 12),
                                  _buildField('CPF', _cpfCtrl,
                                      icon: Icons.badge_outlined,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [_CpfFormatter()]),
                                ],
                                if (_tipo == 'empresa') ...[
                                  const SizedBox(height: 12),
                                  _buildField('CNPJ', _cnpjCtrl,
                                      icon: Icons.business_outlined,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [_CnpjFormatter()]),
                                  const SizedBox(height: 12),
                                  _buildField('Razão Social', _razaoCtrl,
                                      icon: Icons.apartment_outlined),
                                ],
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
                                      onPressed: _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4CE0D2),
                                        foregroundColor: const Color(0xFF0A1929),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Cadastrar', style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1,
                                      )),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Text('Já possui conta? ', style: TextStyle(
                                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.6),
                                      fontSize: 13,
                                    )),
                                    GestureDetector(
                                      onTap: () => context.pop(),
                                      child: const Text('Faça login', style: TextStyle(
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
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool obscure = false, TextInputType? keyboardType, IconData? icon,
      Widget? suffixIcon, List<TextInputFormatter>? inputFormatters}) {
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
          inputFormatters: inputFormatters,
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

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _CnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 14) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('/');
      if (i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}
