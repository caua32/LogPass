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
  static const _cyan  = Color(0xFF44CABD);
  static const _bg    = Color(0xFF0A1929);
  static const _card  = Color(0xFF0D2137);

  List<Reclamacao> _reclamacoes = [];
  bool _loading = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 420), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _fadeCtrl, curve: Curves.easeOutQuart));
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
        _reclamacoes = lista
            .map((e) => Reclamacao.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar relatórios.'; _loading = false; });
    }
  }

  int _count(int status) =>
      _reclamacoes.where((r) => r.idStatus == status).length;

  double get _taxaResolucao =>
      _reclamacoes.isEmpty ? 0 : (_count(3) / _reclamacoes.length) * 100;

  // ── Modal ────────────────────────────────────────────────────────────────

  void _abrirModal(String titulo, List<Reclamacao> lista, Color cor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: lista.isEmpty ? 0.35 : 0.75,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (_, ctrl) => Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44, height: 4,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(children: [
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        color: Color(0xFFE8F8F7),
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cor.withValues(alpha: 0.35)),
                ),
                child: Text('${lista.length}',
                    style: TextStyle(
                        color: cor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          const Divider(color: Color(0xFF1A3A55), height: 1),
          // Conteúdo
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: _cyan.withValues(alpha: 0.25)),
                        const SizedBox(height: 14),
                        Text('Nenhuma reclamação neste filtro',
                            style: TextStyle(
                                color: _cyan.withValues(alpha: 0.5),
                                fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const Divider(
                        color: Color(0xFF1A3A55), height: 1, indent: 16),
                    itemBuilder: (_, i) => _modalItem(lista[i]),
                  ),
          ),
          SafeArea(top: false, child: const SizedBox(height: 8)),
        ]),
      ),
    );
  }

  Widget _modalItem(Reclamacao r) {
    String? dataFormatada;
    if (r.createdAt != null) {
      try {
        final dt = DateTime.parse(r.createdAt!).toLocal();
        dataFormatada =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 4, height: 44,
          decoration: BoxDecoration(
            color: r.statusColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.titulo,
                  style: const TextStyle(
                      color: _cyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                if (r.nomeConsumidor != null) ...[
                  Icon(Icons.person_outline,
                      size: 12, color: _cyan.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(r.nomeConsumidor!,
                        style: TextStyle(
                            color: _cyan.withValues(alpha: 0.6),
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ),
                ] else
                  const Spacer(),
                if (dataFormatada != null)
                  Text(dataFormatada,
                      style: TextStyle(
                          color: _cyan.withValues(alpha: 0.4),
                          fontSize: 10)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: r.statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: r.statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(r.statusNome,
              style: TextStyle(
                  color: r.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(children: [
            AppHeader(
              title: 'Relatórios e Análises',
              subtitle: 'Toque em um card para ver detalhes',
              icon: Icons.analytics_outlined,
              actions: [
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, color: _cyan, size: 20),
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: _cyan, strokeWidth: 2))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFFF6B6B), size: 40),
                              const SizedBox(height: 12),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: Color(0xFFFF6B6B))),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Tentar novamente',
                                    style: TextStyle(color: _cyan)),
                              ),
                            ],
                          ),
                        )
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
                                _metricCard(
                                  'Total', _reclamacoes.length,
                                  _cyan, Icons.inbox_outlined,
                                  onTap: () => _abrirModal(
                                      'Todas as Reclamações',
                                      _reclamacoes, _cyan),
                                ),
                                _metricCard(
                                  'Pendentes', _count(1),
                                  Colors.orange, Icons.pending_outlined,
                                  onTap: () => _abrirModal(
                                      'Pendentes',
                                      _reclamacoes
                                          .where((r) => r.idStatus == 1)
                                          .toList(),
                                      Colors.orange),
                                ),
                                _metricCard(
                                  'Em Análise', _count(2),
                                  Colors.blueAccent,
                                  Icons.hourglass_top_outlined,
                                  onTap: () => _abrirModal(
                                      'Em Análise',
                                      _reclamacoes
                                          .where((r) => r.idStatus == 2)
                                          .toList(),
                                      Colors.blueAccent),
                                ),
                                _metricCard(
                                  'Resolvidas', _count(3),
                                  Colors.green, Icons.check_circle_outline,
                                  onTap: () => _abrirModal(
                                      'Resolvidas',
                                      _reclamacoes
                                          .where((r) => r.idStatus == 3)
                                          .toList(),
                                      Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Não resolvidas
                            _fullStatCard(
                              'Não Resolvidas', _count(4),
                              Colors.red, Icons.cancel_outlined,
                              onTap: () => _abrirModal(
                                  'Não Resolvidas',
                                  _reclamacoes
                                      .where((r) => r.idStatus == 4)
                                      .toList(),
                                  Colors.red),
                            ),
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

  // ── Cards ────────────────────────────────────────────────────────────────

  Widget _metricCard(
    String title, int value, Color color, IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: _cyan.withValues(alpha: 0.7), fontSize: 11)),
            ),
            Icon(Icons.chevron_right,
                size: 14, color: color.withValues(alpha: 0.5)),
          ]),
          const Spacer(),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
      ),
    );
  }

  Widget _fullStatCard(
    String title, int value, Color color, IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
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
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: _cyan.withValues(alpha: 0.8), fontSize: 14)),
          ),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right,
              size: 16, color: color.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  Widget _buildTaxaCard() {
    final taxa = _taxaResolucao;
    final color = taxa >= 70
        ? Colors.green
        : taxa >= 40
            ? Colors.orange
            : Colors.red;
    final concluidas = _reclamacoes
        .where((r) => r.idStatus == 3 || r.idStatus == 4)
        .toList();

    return GestureDetector(
      onTap: () => _abrirModal('Concluídas', concluidas, color),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cyan.withValues(alpha: 0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.pie_chart_outline,
                color: _cyan.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
            const Text('Taxa de Resolução',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _cyan)),
            const Spacer(),
            Text('${taxa.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right,
                size: 16, color: color.withValues(alpha: 0.5)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: taxa / 100,
              minHeight: 10,
              backgroundColor: _bg,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_count(3)} de ${_reclamacoes.length} reclamações resolvidas',
            style: TextStyle(
                color: _cyan.withValues(alpha: 0.55), fontSize: 12),
          ),
        ]),
      ),
    );
  }

  Widget _buildRecentList() {
    final recentes = _reclamacoes.take(5).toList();
    return GestureDetector(
      onTap: () => _abrirModal('Histórico de Reclamações', _reclamacoes, _cyan),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cyan.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Icon(Icons.history,
                  color: _cyan.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 8),
              const Text('Recentes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _cyan)),
              const Spacer(),
              Text('ver todos',
                  style: TextStyle(
                      color: _cyan.withValues(alpha: 0.5), fontSize: 11)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 14, color: _cyan.withValues(alpha: 0.4)),
            ]),
          ),
          const Divider(color: Color(0xFF1A3A55), height: 1),
          ...recentes.map((r) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 3, height: 32,
                    decoration: BoxDecoration(
                      color: r.statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.titulo,
                            style: const TextStyle(
                                color: _cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                        Text(r.nomeConsumidor ?? '',
                            style: TextStyle(
                                color: _cyan.withValues(alpha: 0.55),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(r.statusNome,
                        style: TextStyle(
                            color: r.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              )),
        ]),
      ),
    );
  }
}
