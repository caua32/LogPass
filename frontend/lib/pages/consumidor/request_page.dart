import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/app_header.dart';

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cnpjCtrl = TextEditingController();
  final _numeroPedidoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  String _tipo = 'troca';
  bool _loading = false;

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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _cnpjCtrl.dispose();
    _numeroPedidoCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await ApiService.criarReclamacao(token, {
        'empresa_cnpj': _cnpjCtrl.text.trim(),
        'numero_pedido': _numeroPedidoCtrl.text.trim(),
        'motivo': _motivoCtrl.text.trim(),
        'forma_solucao': _tipo,
      });
      if (mounted) _showSucesso();
    } on ApiException catch (e) {
      if (mounted) _showErro(e.message);
    } catch (_) {
      if (mounted) _showErro('Erro ao enviar solicitaÃ§Ã£o.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSucesso() {
    final protocolo = 'LP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF102A43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: const Color(0xFF44CABD).withValues(alpha: 0.4)),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF44CABD).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: Color(0xFF44CABD), size: 22),
          ),
          const SizedBox(width: 10),
          const Text('Enviado!', style: TextStyle(
            color: Color(0xFF44CABD), fontSize: 18, fontWeight: FontWeight.bold,
          )),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sua solicitaÃ§Ã£o foi registrada com sucesso.',
              style: TextStyle(color: const Color(0xFF44CABD).withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF44CABD).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.tag, size: 14, color: const Color(0xFF44CABD).withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('Protocolo: $protocolo', style: const TextStyle(
                  color: Color(0xFF44CABD), fontWeight: FontWeight.bold, fontSize: 13,
                )),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.swap_horiz, size: 14, color: const Color(0xFF44CABD).withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('Tipo: ${_tipo == 'troca' ? 'Troca' : 'Reembolso'}',
                    style: TextStyle(color: const Color(0xFF44CABD).withValues(alpha: 0.8), fontSize: 13)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Nossa equipe analisarÃ¡ em atÃ© 24h Ãºteis.',
              style: TextStyle(
                color: const Color(0xFF44CABD).withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              )),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); context.go('/dashboard'); },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF44CABD),
                foregroundColor: const Color(0xFF0A1929),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFFFF6B6B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
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
            title: 'Nova SolicitaÃ§Ã£o',
            subtitle: 'Registre sua reclamaÃ§Ã£o',
            icon: Icons.assignment_outlined,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionCard(
                    title: 'CNPJ da Empresa',
                    titleIcon: Icons.business_outlined,
                    children: [
                      TextFormField(
                        controller: _cnpjCtrl,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: Color(0xFF44CABD), fontSize: 14),
                        decoration: appInputDeco('00.000.000/0000-00'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Informe o CNPJ da empresa' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Tipo de SolicitaÃ§Ã£o',
                    titleIcon: Icons.swap_horiz,
                    children: [
                      Row(children: [
                        Expanded(child: _buildTipoCard('troca', 'Troca', Icons.sync)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTipoCard('reembolso', 'Reembolso', Icons.attach_money)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'NÃºmero do Pedido',
                    titleIcon: Icons.receipt_outlined,
                    children: [
                      TextFormField(
                        controller: _numeroPedidoCtrl,
                        style: const TextStyle(color: Color(0xFF44CABD), fontSize: 14),
                        decoration: appInputDeco('Ex: 12345'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Informe o nÃºmero do pedido' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SectionCard(
                    title: 'Motivo da ReclamaÃ§Ã£o',
                    titleIcon: Icons.edit_note_outlined,
                    children: [
                      TextFormField(
                        controller: _motivoCtrl,
                        maxLines: 4,
                        style: const TextStyle(color: Color(0xFF44CABD), fontSize: 14),
                        decoration: appInputDeco('Descreva detalhadamente o que aconteceu...'),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Descreva o problema (mÃ­nimo 10 caracteres)' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: CircularProgressIndicator(
                        color: Color(0xFF44CABD), strokeWidth: 2))
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _enviar,
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: const Text('Enviar SolicitaÃ§Ã£o', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                        )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF44CABD),
                          foregroundColor: const Color(0xFF0A1929),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
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

  Widget _buildTipoCard(String value, String label, IconData icon) {
    final selected = _tipo == value;
    return GestureDetector(
      onTap: () => setState(() => _tipo = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF44CABD).withValues(alpha: 0.15)
              : const Color(0xFF0A1929).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF44CABD)
                : const Color(0xFF44CABD).withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon,
              color: selected ? const Color(0xFF44CABD) : const Color(0xFF44CABD).withValues(alpha: 0.4),
              size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            color: selected ? const Color(0xFF44CABD) : const Color(0xFF44CABD).withValues(alpha: 0.5),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          )),
        ]),
      ),
    );
  }
}
