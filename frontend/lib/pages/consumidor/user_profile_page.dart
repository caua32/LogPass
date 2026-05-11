import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  List<Reclamacao> _reclamacoes = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token!;
    try {
      final perfil = await ApiService.getConsumidorPerfil(token);
      final lista = await ApiService.getReclamacoesConsumidor(token);
      setState(() {
        _nomeCtrl.text = perfil['nome'] ?? '';
        _emailCtrl.text = perfil['email'] ?? '';
        _telefoneCtrl.text = perfil['telefone'] ?? '';
        _cpfCtrl.text = perfil['cpf'] ?? '';
        _reclamacoes = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
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
      await ApiService.updateConsumidorPerfil(token, {
        'nome': _nomeCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: Color(0xFF4CE0D2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF102A43),
              border: const Border(bottom: BorderSide(color: Color(0xFF4CE0D2))),
              boxShadow: [BoxShadow(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3), blurRadius: 15)],
            ),
            child: Row(children: [
              Expanded(child: Row(children: [
                const Icon(Icons.person_outline, size: 32, color: Color(0xFF4CE0D2)),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Meus Dados', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                  )),
                  Text('Gerencie suas informações pessoais', style: TextStyle(
                    fontSize: 14, color: Color(0xFF4CE0D2), fontStyle: FontStyle.italic,
                  )),
                ]),
              ])),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Voltar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CE0D2),
                  foregroundColor: const Color(0xFF0A1929),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  elevation: 0,
                ),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CE0D2)))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            _buildAvatar(),
                            const SizedBox(height: 20),
                            _buildDadosPessoais(),
                            const SizedBox(height: 20),
                            _buildReclamacoes(),
                            const SizedBox(height: 30),
                            _buildBotoes(),
                            const SizedBox(height: 20),
                          ]),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF4CE0D2),
          child: Text(
            _nomeCtrl.text.isNotEmpty ? _nomeCtrl.text[0].toUpperCase() : 'U',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0A1929)),
          ),
        ),
        const SizedBox(height: 15),
        Text(_nomeCtrl.text, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
        )),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4CE0D2).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text('Consumidor', style: TextStyle(
            fontSize: 12, color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold,
          )),
        ),
      ]),
    );
  }

  Widget _buildDadosPessoais() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Informações Pessoais', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
        )),
        const SizedBox(height: 20),
        _buildField(_nomeCtrl, 'Nome Completo', Icons.person),
        const SizedBox(height: 15),
        _buildField(_emailCtrl, 'Email', Icons.email, enabled: false),
        const SizedBox(height: 15),
        _buildField(_cpfCtrl, 'CPF', Icons.badge),
        const SizedBox(height: 15),
        _buildField(_telefoneCtrl, 'Telefone', Icons.phone),
      ]),
    );
  }

  Widget _buildReclamacoes() {
    if (_reclamacoes.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Minhas Reclamações', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
        )),
        const SizedBox(height: 15),
        ..._reclamacoes.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1929),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: r.statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.titulo, style: const TextStyle(
                color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold,
              )),
              Text(r.descricao, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: const Color(0xFF4CE0D2).withValues(alpha: 0.7), fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.statusColor, borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.statusNome, style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildBotoes() {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _salvar,
          icon: _saving ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(color: Color(0xFF0A1929), strokeWidth: 2))
              : const Icon(Icons.save),
          label: const Text('Salvar Alterações'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CE0D2),
            foregroundColor: const Color(0xFF0A1929),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Cancelar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4CE0D2),
            side: const BorderSide(color: Color(0xFF4CE0D2)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool enabled = true}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      style: const TextStyle(color: Color(0xFF4CE0D2)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4CE0D2)),
        prefixIcon: Icon(icon, color: const Color(0xFF4CE0D2)),
        filled: true,
        fillColor: enabled ? const Color(0xFF0A1929) : const Color(0xFF0A1929).withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.5))),
        suffixIcon: !enabled ? const Icon(Icons.lock, color: Color(0xFF4CE0D2), size: 16) : null,
      ),
    );
  }
}

