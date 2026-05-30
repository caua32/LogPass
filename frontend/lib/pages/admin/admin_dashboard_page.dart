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

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Reclamacao> _reclamacoes = [];
  String? _token;
  String? _nomeAdmin;
  bool _loading = true;
  String? _error;
  int? _filtroStatus;

  @override
  void initState() {
    super.initState();
    _init();
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
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await ApiService.getAdminReclamacoes(_token!);
      setState(() {
        _reclamacoes = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar reclamações.'; _loading = false; });
    }
  }

  Future<void> _updateStatus(Reclamacao r, int novoStatus) async {
    try {
      await ApiService.updateReclamacaoStatus(_token!, r.id, novoStatus);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Status atualizado!'),
          backgroundColor: Color(0xFF4CE0D2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF102A43),
        title: const Text('Confirmar Logout', style: TextStyle(color: Color(0xFF4CE0D2))),
        content: const Text('Tem certeza que deseja sair do painel administrativo?',
            style: TextStyle(color: Color(0xFF4CE0D2))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF4CE0D2))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AdminAuthService.clearSession();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CE0D2),
              foregroundColor: const Color(0xFF0A1929),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showStats() {
    final total = _reclamacoes.length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF102A43),
        title: const Text('Estatísticas', style: TextStyle(color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _statRow('Total', total, Colors.blue),
          _statRow('Pendentes', _reclamacoes.where((r) => r.idStatus == 1).length, Colors.orange),
          _statRow('Em Análise', _reclamacoes.where((r) => r.idStatus == 2).length, Colors.blue),
          _statRow('Resolvidas', _reclamacoes.where((r) => r.idStatus == 3).length, Colors.green),
          _statRow('Não Resolvidas', _reclamacoes.where((r) => r.idStatus == 4).length, Colors.red),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CE0D2), foregroundColor: const Color(0xFF0A1929),
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF4CE0D2))),
        ]),
        Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  List<Reclamacao> get _filtradas => _filtroStatus == null
      ? _reclamacoes
      : _reclamacoes.where((r) => r.idStatus == _filtroStatus).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Painel Administrativo', style: TextStyle(
            color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold, fontSize: 18,
          )),
          if (_nomeAdmin != null)
            Text('Admin • $_nomeAdmin', style: const TextStyle(
              color: Color(0xFF4CE0D2), fontSize: 12, fontWeight: FontWeight.normal,
            )),
        ]),
        leading: null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF4CE0D2)), onPressed: _load),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4CE0D2)),
            color: const Color(0xFF102A43),
            onSelected: (v) {
              if (v == 'stats') _showStats();
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'stats', child: Row(children: [
                Icon(Icons.analytics, color: Color(0xFF4CE0D2)),
                SizedBox(width: 8),
                Text('Estatísticas', style: TextStyle(color: Color(0xFF4CE0D2))),
              ])),
              const PopupMenuItem(value: 'logout', child: Row(children: [
                Icon(Icons.logout, color: Color(0xFF4CE0D2)),
                SizedBox(width: 8),
                Text('Sair', style: TextStyle(color: Color(0xFF4CE0D2))),
              ])),
            ],
          ),
        ],
      ),
      body: Row(children: [
        // Lateral com lista
        Container(
          width: 300,
          decoration: const BoxDecoration(
            color: Color(0xFF102A43),
            border: Border(right: BorderSide(color: Color(0xFF4CE0D2))),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF4CE0D2))),
              ),
              child: Column(children: [
                const Row(children: [
                  Icon(Icons.list_alt, color: Color(0xFF4CE0D2)),
                  SizedBox(width: 8),
                  Text('Reclamações', style: TextStyle(
                    color: Color(0xFF4CE0D2), fontSize: 16, fontWeight: FontWeight.bold,
                  )),
                ]),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _filterChip('Todos', null),
                    const SizedBox(width: 6),
                    _filterChip('Pendente', 1),
                    const SizedBox(width: 6),
                    _filterChip('Em Análise', 2),
                    const SizedBox(width: 6),
                    _filterChip('Resolvida', 3),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CE0D2)))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))))
                      : ListView.builder(
                          itemCount: _filtradas.length,
                          itemBuilder: (_, i) {
                            final r = _filtradas[i];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: r.statusColor.withValues(alpha: 0.5)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: r.statusColor,
                                  child: Text('${r.id}', style: const TextStyle(
                                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold,
                                  )),
                                ),
                                title: Text(r.titulo, style: const TextStyle(
                                  color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold, fontSize: 13,
                                ), overflow: TextOverflow.ellipsis),
                                subtitle: Text(r.nomeConsumidor ?? '-', style: TextStyle(
                                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.6), fontSize: 11,
                                )),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: r.statusColor, borderRadius: BorderRadius.circular(8)),
                                  child: Text(r.statusNome, style: const TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold,
                                  )),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ]),
        ),
        // Ãrea principal
        Expanded(
          child: _filtradas.isEmpty && !_loading
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF4CE0D2)),
                  SizedBox(height: 16),
                  Text('Nenhuma reclamação encontrada', style: TextStyle(color: Color(0xFF4CE0D2), fontSize: 18)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtradas.length,
                  itemBuilder: (_, i) => _buildCard(_filtradas[i]),
                ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, int? status) {
    final selected = _filtroStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filtroStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4CE0D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CE0D2)),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? const Color(0xFF0A1929) : const Color(0xFF4CE0D2),
          fontSize: 11, fontWeight: FontWeight.bold,
        )),
      ),
    );
  }

  Widget _buildCard(Reclamacao r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF4CE0D2).withValues(alpha: 0.1), blurRadius: 10)],
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
        const SizedBox(height: 8),
        Row(children: [
          if (r.nomeEmpresa != null) ...[
            Icon(Icons.business, size: 14, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(r.nomeEmpresa!, style: TextStyle(fontSize: 12, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7))),
            const SizedBox(width: 16),
          ],
          if (r.nomeConsumidor != null) ...[
            Icon(Icons.person, size: 14, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(r.nomeConsumidor!, style: TextStyle(fontSize: 12, color: const Color(0xFF4CE0D2).withValues(alpha: 0.7))),
          ],
        ]),
        const SizedBox(height: 12),
        const Text('Alterar status:', style: TextStyle(fontSize: 12, color: Color(0xFF4CE0D2))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: kStatusNomes.entries.map((e) {
          final isActive = r.idStatus == e.key;
          return GestureDetector(
            onTap: isActive ? null : () => _updateStatus(r, e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? _statusColor(e.key) : _statusColor(e.key).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _statusColor(e.key)),
              ),
              child: Text(e.value, style: TextStyle(
                color: isActive ? Colors.white : _statusColor(e.key),
                fontSize: 12, fontWeight: FontWeight.bold,
              )),
            ),
          );
        }).toList()),
      ]),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1: return Colors.orange;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }
}

