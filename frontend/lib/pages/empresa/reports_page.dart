import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';
import '../../core/app_header.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  List<Reclamacao> _reclamacoes = [];
  bool _loading = true;
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
  double get _taxaResolucao =>
      _reclamacoes.isEmpty ? 0 : (_count(3) / _reclamacoes.length) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          AppHeader(
            title: 'Relatórios e Análises',
            subtitle: 'Visão geral das reclamações',
            icon: Icons.analytics_outlined,
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: Color(0xFF44CABD), size: 20),
                tooltip: 'Atualizar',
              ),
            ],
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
                            onPressed: _load,
                            child: const Text('Tentar novamente',
                                style: TextStyle(color: Color(0xFF44CABD))),
                          ),
                        ],
                      ))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(children: [
                          // Grid de métricas
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _metricCard('Total', _reclamacoes.length,
                                  const Color(0xFF44CABD), Icons.inbox_outlined),
                              _metricCard('Pendentes', _count(1),
                                  Colors.orange, Icons.pending_outlined),
                              _metricCard('Em Análise', _count(2),
                                  Colors.blueAccent, Icons.hourglass_top_outlined),
                              _metricCard('Resolvidas', _count(3),
                                  Colors.green, Icons.check_circle_outline),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Não resolvidas (full width)
                          _fullStatCard('Não Resolvidas', _count(4),
                              Colors.red, Icons.cancel_outlined),
                          const SizedBox(height: 14),
                          // Taxa de resolução
                          _buildTaxaCard(),
                          // Lista recente
                          if (_reclamacoes.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildRecentList(),
                          ],
                          const SizedBox(height: 20),
                        ]),
                      ),
          ),
        ]),
        ),
      ),
    );
  }

  Widget _metricCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: TextStyle(
              color: const Color(0xFF44CABD).withValues(alpha: 0.7),
              fontSize: 11,
            ))),
          ]),
          const Spacer(),
          Text(value.toString(), style: TextStyle(
            fontSize: 30, fontWeight: FontWeight.bold, color: color,
          )),
        ],
      ),
    );
  }

  Widget _fullStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: TextStyle(
          color: const Color(0xFF44CABD).withValues(alpha: 0.8),
          fontSize: 14,
        ))),
        Text(value.toString(), style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: color,
        )),
      ]),
    );
  }

  Widget _buildTaxaCard() {
    final taxa = _taxaResolucao;
    final color = taxa >= 70
        ? Colors.green
        : taxa >= 40
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.pie_chart_outline,
              color: const Color(0xFF44CABD).withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 8),
          const Text('Taxa de Resolução', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF44CABD),
          )),
          const Spacer(),
          Text('${taxa.toStringAsFixed(1)}%', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color,
          )),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: taxa / 100,
            minHeight: 10,
            backgroundColor: const Color(0xFF0A1929),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Text('${_count(3)} de ${_reclamacoes.length} reclamações resolvidas',
            style: TextStyle(
              color: const Color(0xFF44CABD).withValues(alpha: 0.55),
              fontSize: 12,
            )),
      ]),
    );
  }

  Widget _buildRecentList() {
    final recentes = _reclamacoes.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF44CABD).withValues(alpha: 0.18)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Icon(Icons.history, color: const Color(0xFF44CABD).withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
            const Text('Recentes', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF44CABD),
            )),
          ]),
        ),
        const Divider(color: Color(0xFF44CABD), height: 1),
        ...recentes.map((r) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Container(width: 3, height: 32,
                decoration: BoxDecoration(
                    color: r.statusColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.titulo, style: const TextStyle(
                color: Color(0xFF44CABD), fontSize: 12, fontWeight: FontWeight.w500,
              ), overflow: TextOverflow.ellipsis),
              Text(r.nomeConsumidor ?? '', style: TextStyle(
                color: const Color(0xFF44CABD).withValues(alpha: 0.55), fontSize: 11,
              )),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: r.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(r.statusNome, style: TextStyle(
                color: r.statusColor, fontSize: 10, fontWeight: FontWeight.bold,
              )),
            ),
          ]),
        )),
      ]),
    );
  }
}
