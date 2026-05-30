import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/app_header.dart';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _razaoCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cnpjCtrl.dispose();
    _razaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    try {
      final perfil = await ApiService.getEmpresaPerfil(token);
      final e = perfil['empresa'] as Map<String, dynamic>;
      setState(() {
        _nomeCtrl.text = e['nomeempresa'] ?? '';
        _cnpjCtrl.text = e['cnpj'] ?? '';
        _telefoneCtrl.text = e['contato'] ?? '';
        _emailCtrl.text = context.read<AuthProvider>().user?.email ?? '';
        _razaoCtrl.text = '';
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar dados.'; _loading = false; });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final token = context.read<AuthProvider>().token!;
    try {
      await ApiService.updateEmpresaPerfil(token, {
        'nomeempresa': _nomeCtrl.text.trim(),
        'contato': _telefoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF0A1929), size: 18),
            SizedBox(width: 8),
            Text('Dados salvos com sucesso!'),
          ]),
          backgroundColor: const Color(0xFF44CABD),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao salvar dados.'),
          backgroundColor: Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          const AppHeader(
            title: 'Perfil da Empresa',
            subtitle: 'Gerenciar informaÃ§Ãµes empresariais',
            icon: Icons.business_outlined,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF44CABD), strokeWidth: 2))
                : _error != null
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFFF6B6B), size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                            child: const Text('Tentar novamente',
                                style: TextStyle(color: Color(0xFF44CABD))),
                          ),
                        ],
                      ))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            _buildAvatar(),
                            const SizedBox(height: 16),
                            SectionCard(
                              title: 'InformaÃ§Ãµes Empresariais',
                              titleIcon: Icons.edit_outlined,
                              children: [
                                _buildField(_nomeCtrl, 'Nome da Empresa',
                                    Icons.business_outlined,
                                    validator: (v) =>
                                        (v == null || v.isEmpty) ? 'Informe o nome' : null),
                                const SizedBox(height: 12),
                                _buildField(_cnpjCtrl, 'CNPJ', Icons.badge_outlined,
                                    enabled: false),
                                const SizedBox(height: 12),
                                _buildField(_razaoCtrl, 'RazÃ£o Social', Icons.apartment_outlined),
                                const SizedBox(height: 12),
                                _buildField(_emailCtrl, 'Email', Icons.email_outlined,
                                    enabled: false),
                                const SizedBox(height: 12),
                                _buildField(_telefoneCtrl, 'Telefone', Icons.phone_outlined),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(children: [
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed: _saving ? null : _salvar,
                                    icon: _saving
                                        ? const SizedBox(width: 16, height: 16,
                                            child: CircularProgressIndicator(
                                                color: Color(0xFF0A1929), strokeWidth: 2))
                                        : const Icon(Icons.save_outlined, size: 18),
                                    label: const Text('Salvar', style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14,
                                    )),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF44CABD),
                                      foregroundColor: const Color(0xFF0A1929),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() { _loading = true; });
                                      _load();
                                    },
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Cancelar', style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14,
                                    )),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF44CABD),
                                      side: BorderSide(
                                          color: const Color(0xFF44CABD).withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 20),
                          ]),
                        ),
                      ),
          ),
        ]),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final inicial = _nomeCtrl.text.isNotEmpty ? _nomeCtrl.text[0].toUpperCase() : 'E';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF44CABD),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: const Color(0xFF44CABD).withValues(alpha: 0.35),
                blurRadius: 16, spreadRadius: 2,
              )],
            ),
            child: Center(child: Text(inicial, style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A1929),
            ))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nomeCtrl.text, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF44CABD),
                )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF44CABD).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.3)),
                  ),
                  child: const Text('Empresa Parceira', style: TextStyle(
                    fontSize: 10, color: Color(0xFF44CABD),
                    fontWeight: FontWeight.bold, letterSpacing: 0.5,
                  )),
                ),
                const SizedBox(height: 4),
                Text(_cnpjCtrl.text, style: TextStyle(
                  fontSize: 11, color: const Color(0xFF44CABD).withValues(alpha: 0.55),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool enabled = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        color: enabled ? const Color(0xFF44CABD) : const Color(0xFF44CABD).withValues(alpha: 0.5),
        fontSize: 14,
      ),
      decoration: appInputDeco(label, prefixIcon: icon).copyWith(
        labelText: label,
        labelStyle: TextStyle(
          color: const Color(0xFF44CABD).withValues(alpha: enabled ? 0.8 : 0.4),
          fontSize: 12,
        ),
        hintText: null,
        suffixIcon: !enabled
            ? Icon(Icons.lock_outline,
                color: const Color(0xFF44CABD).withValues(alpha: 0.3), size: 16)
            : null,
        fillColor: enabled
            ? const Color(0xFF0A1929).withValues(alpha: 0.8)
            : const Color(0xFF0A1929).withValues(alpha: 0.4),
      ),
    );
  }
}
