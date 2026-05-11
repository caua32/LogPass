import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';

class ProblemsNotificationPage extends StatefulWidget {
  const ProblemsNotificationPage({super.key});

  @override
  State<ProblemsNotificationPage> createState() => _ProblemsNotificationPageState();
}

class _ProblemsNotificationPageState extends State<ProblemsNotificationPage> with SingleTickerProviderStateMixin {
  List<Reclamacao> _urgentes = [];
  bool _loading = true;
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token!;
    try {
      final lista = await ApiService.getReclamacoesEmpresa(token);
      final todas = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _urgentes = todas.where((r) => r.idStatus == 1 || r.idStatus == 2).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar alertas.'; _loading = false; });
    }
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
                const Icon(Icons.warning_amber_outlined, size: 32, color: Color(0xFF4CE0D2)),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Notificações de Problemas', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                  )),
                  Text('Reclamações pendentes e em análise', style: TextStyle(
                    fontSize: 12, color: Color(0xFF4CE0D2), fontStyle: FontStyle.italic,
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
                    : _urgentes.isEmpty
                        ? const Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF4CE0D2)),
                              SizedBox(height: 16),
                              Text('Nenhum alerta pendente!',
                                  style: TextStyle(fontSize: 18, color: Color(0xFF4CE0D2))),
                            ],
                          ))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _urgentes.length,
                            itemBuilder: (_, i) => _buildCard(_urgentes[i]),
                          ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCard(Reclamacao r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: r.statusColor.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: r.statusColor.withValues(alpha: 0.2), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(r.titulo, style: const TextStyle(
            color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold, fontSize: 16,
          ), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: r.statusColor, borderRadius: BorderRadius.circular(8)),
            child: Text(r.statusNome, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(r.descricao, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: const Color(0xFF4CE0D2).withValues(alpha: 0.7))),
        if (r.nomeConsumidor != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.person, size: 14, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(r.nomeConsumidor!, style: TextStyle(
              fontSize: 12, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
            )),
          ]),
        ],
      ]),
    );
  }
}

