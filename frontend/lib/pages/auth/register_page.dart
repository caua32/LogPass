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
        parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeOut));

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
    setState(() => _erro = '');
    if (_nomeCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _senhaCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos obrigatÃ³rios.');
      return;
    }
    if (_tipo == null) {
      setState(() => _erro = 'Selecione o tipo de usuÃ¡rio.');
      return;
    }
    if (_tipo == 'consumidor' &&
        !RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$').hasMatch(_cpfCtrl.text.trim())) {
      setState(() => _erro = 'CPF invÃ¡lido. Use o formato 000.000.000-00.');
      return;
    }
    if (_tipo == 'empresa' &&
        !RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$').hasMatch(_cnpjCtrl.text.trim())) {
      setState(() => _erro = 'CNPJ invÃ¡lido. Use o formato 00.000.000/0000-00.');
      return;
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
          backgroundColor: _cyan,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
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
      body: Stack(
        children: [
          const ParticlesBackground(count: 100, showLines: true),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.4,
                colors: [_bg.withValues(alpha: 0), _bg.withValues(alpha: 0.75)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _cyan.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _cyan.withValues(alpha: 0.35), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cyan.withValues(alpha: 0.22),
                                    blurRadius: 28,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.computer, size: 30, color: _cyan),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'LogPass',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _cyan,
                                letterSpacing: 3,
                                shadows: [Shadow(color: _cyan, blurRadius: 16)],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CRIE SUA CONTA',
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
                    const SizedBox(height: 28),
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
                                border: Border.all(color: _cyan.withValues(alpha: 0.18)),
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
                                    'Criar conta',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE8F8F7),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Preencha os dados para se cadastrar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _cyan.withValues(alpha: 0.50),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildField('Nome completo', _nomeCtrl,
                                      icon: Icons.person_outline),
                                  const SizedBox(height: 16),
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
                                  _buildField('Telefone', _telefoneCtrl,
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone),
                                  const SizedBox(height: 16),
                                  _buildTipoSelector(),
                                  if (_tipo == 'consumidor') ...[
                                    const SizedBox(height: 16),
                                    _buildField('CPF', _cpfCtrl,
                                        icon: Icons.badge_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [_CpfFormatter()]),
                                  ],
                                  if (_tipo == 'empresa') ...[
                                    const SizedBox(height: 16),
                                    _buildField('CNPJ', _cnpjCtrl,
                                        icon: Icons.business_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [_CnpjFormatter()]),
                                    const SizedBox(height: 16),
                                    _buildField('RazÃ£o Social / Nome da Empresa',
                                        _razaoCtrl,
                                        icon: Icons.apartment_outlined),
                                  ],
                                  const SizedBox(height: 24),
                                  _buildBotao(),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Text(
                                          'JÃ¡ possui conta? ',
                                          style: TextStyle(
                                            color: _cyan.withValues(alpha: 0.5),
                                            fontSize: 13,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => context.pop(),
                                          child: const Text(
                                            'FaÃ§a login',
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B6B)
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFFF6B6B)
                                                .withValues(alpha: 0.35)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: Color(0xFFFF6B6B), size: 16),
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
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    TextInputType? keyboardType,
    IconData? icon,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Color(0xFFE8F8F7), fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF071520),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Expanded(
                  child: _buildTipoOption(
                      'empresa', Icons.business_outlined, 'Empresa')),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildTipoOption(
                      'consumidor', Icons.person_outline, 'Consumidor')),
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
            color: selected
                ? _cyan.withValues(alpha: 0.5)
                : _cyan.withValues(alpha: 0.15),
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
        onPressed: _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: _bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text(
          'Criar conta',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
        text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _CnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
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
    return TextEditingValue(
        text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}
