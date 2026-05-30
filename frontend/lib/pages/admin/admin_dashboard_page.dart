import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/admin_auth_service.dart';
import '../../models/reclamacao_model.dart';
import '../../core/constants.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  List<Reclamacao> _reclamacoes = [];
  String? _token;
  String? _nomeAdmin;
  bool _loading = true;
  String? _error;
  int? _filtroStatus;

  static const _cyan = Color(0xFF44CABD);
  static const _bg = Color(0xFF0A1929);
  static const _card = Color(0xFF0D2137);

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _init();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _token = await AdminAuthService.getToken();
    _nomeAdmin = await AdminAuthService.getNome();
    if (_token == null) {
      if (mounted) context.go('/admin/login');
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await ApiService.getAdminReclamacoes(_token!);
      setState(() {
        _reclamacoes = lista
            .map((e) => Reclamacao.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Erro ao carregar reclamações.';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(Reclamacao r, int novoStatus) async {
    try {
      await ApiService.updateReclamacaoStatus(_token!, r.id, novoStatus);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF0A1929), size: 16),
            SizedBox(width: 8),
            Text('Status atualizado!'),
          ]),
          backgroundColor: _cyan,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _cyan.withValues(alpha: 0.20)),
        ),
        title: const Text('Sair do painel',
            style: TextStyle(
                color: Color(0xFFE8F8F7), fontWeight: FontWeight.w700)),
        content: Text(
          'Tem certeza que deseja sair do painel administrativo?',
          style: TextStyle(color: _cyan.withValues(alpha: 0.70), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: _cyan.withValues(alpha: 0.70))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AdminAuthService.clearSession();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Sair',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<Reclamacao> get _filtradas => _filtroStatus == null
      ? _reclamacoes
      : _reclamacoes.where((r) => r.idStatus == _filtroStatus).toList();

  Color _statusColor(int status) {
    switch (status) {
      case 1: return Colors.orange;
      case 2: return Colors.blueAccent;
      case 3: return Colors.green;
      case 4: return const Color(0xFFFF6B6B);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _cyan, strokeWidth: 2))
                : _error != null
                    ? _buildError()
                    : SlideTransition(
                        position: _slideAnim,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            children: [
                              _buildStats(),
                              _buildFiltros(),
                              Expanded(child: _buildLista()),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF102A43)],
        ),
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.22), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _cyan,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                    color: _cyan.withValues(alpha: 0.40),
                    blurRadius: 12,
                    spreadRadius: 1),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: _bg, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('LogPass',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _cyan,
                          letterSpacing: 1)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _cyan.withValues(alpha: 0.30)),
                    ),
                    child: const Text('ADMIN',
                        style: TextStyle(
                            fontSize: 8,
                            color: _cyan,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                ]),
                if (_nomeAdmin != null)
                  Text(
                    _nomeAdmin!,
                    style: TextStyle(
                        fontSize: 11,
                        color: _cyan.withValues(alpha: 0.60)),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: _cyan, size: 20),
            tooltip: 'Atualizar',
          ),
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded,
                color: _cyan.withValues(alpha: 0.75), size: 20),
            tooltip: 'Sair',
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = [
      _StatData('Total', _reclamacoes.length, Icons.inbox_outlined, _cyan),
      _StatData('Pendentes',
          _reclamacoes.where((r) => r.idStatus == 1).length,
          Icons.schedule_outlined, Colors.orange),
      _StatData('Em Análise',
          _reclamacoes.where((r) => r.idStatus == 2).length,
          Icons.search_outlined, Colors.blueAccent),
      _StatData('Resolvidas',
          _reclamacoes.where((r) => r.idStatus == 3).length,
          Icons.check_circle_outline, Colors.green),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: stats
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildStatChip(s),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStatChip(_StatData s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, color: s.color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.value.toString(),
                style: TextStyle(
                    color: s.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1),
              ),
              Text(
                s.label,
                style: TextStyle(
                    color: s.color.withValues(alpha: 0.70),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Todos', null),
            const SizedBox(width: 8),
            _filterChip('Pendente', 1),
            const SizedBox(width: 8),
            _filterChip('Em Análise', 2),
            const SizedBox(width: 8),
            _filterChip('Resolvida', 3),
            const SizedBox(width: 8),
            _filterChip('Não Resolvida', 4),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int? status) {
    final selected = _filtroStatus == status;
    final color = status != null ? _statusColor(status) : _cyan;
    return GestureDetector(
      onTap: () => setState(() => _filtroStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.70)
                  : _cyan.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : _cyan.withValues(alpha: 0.60),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_filtradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: _cyan.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Nenhuma reclamação encontrada',
              style: TextStyle(
                  color: _cyan.withValues(alpha: 0.55), fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _cyan,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: _filtradas.length,
        itemBuilder: (_, i) => _buildCard(_filtradas[i], i),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 40),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Color(0xFFFF6B6B))),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: const Text('Tentar novamente',
                style: TextStyle(color: _cyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Reclamacao r, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 55).clamp(0, 280)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: r.statusColor.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: r.statusColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: r.statusColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.titulo,
                          style: const TextStyle(
                            color: Color(0xFFE8F8F7),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _cyan.withValues(alpha: 0.50),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: r.statusColor.withValues(alpha: 0.50)),
                    ),
                    child: Text(
                      r.statusNome,
                      style: TextStyle(
                          color: r.statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // Corpo do card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (r.nomeEmpresa != null) ...[
                      Icon(Icons.business_outlined,
                          size: 13,
                          color: _cyan.withValues(alpha: 0.55)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          r.nomeEmpresa!,
                          style: TextStyle(
                              fontSize: 12,
                              color: _cyan.withValues(alpha: 0.65)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (r.nomeConsumidor != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.person_outline,
                          size: 13,
                          color: _cyan.withValues(alpha: 0.55)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          r.nomeConsumidor!,
                          style: TextStyle(
                              fontSize: 12,
                              color: _cyan.withValues(alpha: 0.65)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'ALTERAR STATUS',
                    style: TextStyle(
                      color: _cyan.withValues(alpha: 0.45),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: kStatusNomes.entries.map((e) {
                      final isActive = r.idStatus == e.key;
                      final color = _statusColor(e.key);
                      return GestureDetector(
                        onTap: isActive
                            ? null
                            : () => _updateStatus(r, e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? color
                                  : color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              color: isActive
                                  ? color
                                  : color.withValues(alpha: 0.60),
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}
