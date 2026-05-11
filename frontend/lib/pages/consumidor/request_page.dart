import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _empresaIdCtrl = TextEditingController();
  String _tipo = 'troca';
  bool _loading = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _tituloCtrl.dispose();
    _descricaoCtrl.dispose();
    _empresaIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await ApiService.criarReclamacao(token, {
        'titulo': _tituloCtrl.text.trim(),
        'descricao': _descricaoCtrl.text.trim(),
        'id_empresa': int.tryParse(_empresaIdCtrl.text.trim()) ?? 0,
      });
      if (mounted) _showSucesso();
    } on ApiException catch (e) {
      if (mounted) _showErro(e.message);
    } catch (_) {
      if (mounted) _showErro('Erro ao enviar solicitação.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSucesso() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF102A43),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF4CE0D2)),
          SizedBox(width: 10),
          Text('Solicitação Enviada!', style: TextStyle(color: Color(0xFF4CE0D2))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sua solicitação foi registrada com sucesso!', style: TextStyle(color: Color(0xFF4CE0D2))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CE0D2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Protocolo: LP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                style: const TextStyle(color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text('Tipo: ${_tipo == 'troca' ? 'Troca' : 'Reembolso'}',
                  style: const TextStyle(color: Color(0xFF4CE0D2))),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('Nossa equipe analisará sua solicitação em até 24h úteis.',
              style: TextStyle(color: Color(0xFF4CE0D2), fontStyle: FontStyle.italic)),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); context.go('/dashboard'); },
            child: const Text('OK', style: TextStyle(color: Color(0xFF4CE0D2))),
          ),
        ],
      ),
    );
  }

  void _showErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final nome = context.read<AuthProvider>().user?.nome ?? 'Usuário';
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
                const Icon(Icons.assignment_outlined, size: 32, color: Color(0xFF4CE0D2)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nova Solicitação', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                  )),
                  Text('Olá, $nome!', style: const TextStyle(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSection('ID da Empresa', [
                    TextFormField(
                      controller: _empresaIdCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Color(0xFF4CE0D2)),
                      decoration: _inputDeco('ID numérico da empresa'),
                      validator: (v) => v!.isEmpty ? 'Informe o ID da empresa' : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Tipo de Solicitação', [
                    Row(children: [
                      Expanded(child: RadioListTile<String>(
                        title: const Text('Troca', style: TextStyle(color: Color(0xFF4CE0D2))),
                        value: 'troca', groupValue: _tipo,
                        activeColor: const Color(0xFF4CE0D2),
                        onChanged: (v) => setState(() => _tipo = v!),
                      )),
                      Expanded(child: RadioListTile<String>(
                        title: const Text('Reembolso', style: TextStyle(color: Color(0xFF4CE0D2))),
                        value: 'reembolso', groupValue: _tipo,
                        activeColor: const Color(0xFF4CE0D2),
                        onChanged: (v) => setState(() => _tipo = v!),
                      )),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Título da Reclamação', [
                    TextFormField(
                      controller: _tituloCtrl,
                      style: const TextStyle(color: Color(0xFF4CE0D2)),
                      decoration: _inputDeco('Ex: Produto chegou danificado'),
                      validator: (v) => v!.isEmpty ? 'Informe o título' : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Descrição do Problema', [
                    TextFormField(
                      controller: _descricaoCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Color(0xFF4CE0D2)),
                      decoration: _inputDeco('Descreva detalhadamente o que aconteceu...'),
                      validator: (v) => v!.isEmpty ? 'Descreva o problema' : null,
                    ),
                  ]),
                  const SizedBox(height: 30),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF4CE0D2)))
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CE0D2),
                          foregroundColor: const Color(0xFF0A1929),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Enviar Solicitação',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
        )),
        const SizedBox(height: 15),
        ...children,
      ]),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4CE0D2)),
      filled: true,
      fillColor: const Color(0xFF0A1929),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 2)),
    );
  }
}

