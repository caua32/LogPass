import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  List<Reclamacao> _reclamacoes = [];
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
      setState(() {
        _reclamacoes = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar relatórios.'; _loading = false; });
    }
  }

  int _count(int status) => _reclamacoes.where((r) => r.idStatus == status).length;
  double get _taxaResolucao => _reclamacoes.isEmpty ? 0 : (_count(3) / _reclamacoes.length) * 100;

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
                const Icon(Icons.analytics_outlined, size: 32, color: Color(0xFF4CE0D2)),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Relatórios e Análises', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                  )),
                  Text('Visão geral das reclamações', style: TextStyle(
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
                        child: Column(children: [
                          _statCard('Total de Reclamações', _reclamacoes.length, Colors.blue, Icons.inbox_outlined),
                          const SizedBox(height: 15),
                          _statCard('Pendentes', _count(1), Colors.orange, Icons.pending_outlined),
                          const SizedBox(height: 15),
                          _statCard('Em Análise', _count(2), Colors.blue, Icons.hourglass_top_outlined),
                          const SizedBox(height: 15),
                          _statCard('Resolvidas', _count(3), Colors.green, Icons.check_circle_outline),
                          const SizedBox(height: 15),
                          _statCard('Não Resolvidas', _count(4), Colors.red, Icons.cancel_outlined),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF102A43),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Taxa de Resolução', style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                              )),
                              const SizedBox(height: 15),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _taxaResolucao / 100,
                                  minHeight: 12,
                                  backgroundColor: const Color(0xFF0A1929),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CE0D2)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('${_taxaResolucao.toStringAsFixed(1)}% das reclamações foram resolvidas',
                                  style: TextStyle(color: const Color(0xFF4CE0D2).withValues(alpha: 0.7))),
                            ]),
                          ),
                        ]),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(color: Color(0xFF4CE0D2), fontSize: 16))),
        Text(value.toString(), style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: color,
        )),
      ]),
    );
  }
}

