import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/reclamacao_model.dart';

class DataConsultPage extends StatefulWidget {
  const DataConsultPage({super.key});

  @override
  State<DataConsultPage> createState() => _DataConsultPageState();
}

class _DataConsultPageState extends State<DataConsultPage> {
  final _searchCtrl = TextEditingController();
  List<Reclamacao> _todas = [];
  List<Reclamacao> _filtradas = [];
  String _filtroStatus = 'todos';
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _perPage = 5;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final token = context.read<AuthProvider>().token!;
    try {
      final lista = await ApiService.getReclamacoesEmpresa(token);
      setState(() {
        _todas = lista.map((e) => Reclamacao.fromJson(e as Map<String, dynamic>)).toList();
        _applyFilter();
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erro ao carregar dados.'; _loading = false; });
    }
  }

  void _applyFilter() {
    final search = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtradas = _todas.where((r) {
        final matchStatus = _filtroStatus == 'todos' || r.idStatus.toString() == _filtroStatus;
        final matchSearch = search.isEmpty ||
            r.titulo.toLowerCase().contains(search) ||
            r.descricao.toLowerCase().contains(search);
        return matchStatus && matchSearch;
      }).toList();
      _page = 1;
    });
  }

  List<Reclamacao> get _paginadas {
    final start = (_page - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _filtradas.length);
    return _filtradas.sublist(start, end);
  }

  int get _totalPages => (_filtradas.length / _perPage).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    final nome = context.read<AuthProvider>().user?.nome ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Row(children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF102A43),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CE0D2)),
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF4CE0D2)),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Consulta de Dados', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
            )),
          ]),
          const SizedBox(height: 20),
          _buildCard(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Reclamações Recebidas', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                )),
                if (nome.isNotEmpty) Text('Bem-vindo, $nome!', style: const TextStyle(
                  fontSize: 14, color: Color(0xFF4CE0D2), fontStyle: FontStyle.italic,
                )),
              ])),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CE0D2),
                  foregroundColor: const Color(0xFF0A1929),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  elevation: 0,
                ),
                child: const Text('Atualizar'),
              ),
            ]),
          ]),
          const SizedBox(height: 20),
          _buildCard(children: [
            const Text('Filtros de Busca', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
            )),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(flex: 3, child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Color(0xFF4CE0D2)),
                decoration: _inputDeco('Buscar por título ou descrição...'),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1929),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF4CE0D2)),
                ),
                child: DropdownButton<String>(
                  value: _filtroStatus,
                  dropdownColor: const Color(0xFF102A43),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: Color(0xFF4CE0D2)),
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: '1', child: Text('Pendente')),
                    DropdownMenuItem(value: '2', child: Text('Em Análise')),
                    DropdownMenuItem(value: '3', child: Text('Resolvida')),
                    DropdownMenuItem(value: '4', child: Text('Não Resolvida')),
                  ],
                  onChanged: (v) { setState(() => _filtroStatus = v ?? 'todos'); _applyFilter(); },
                ),
              )),
            ]),
          ]),
          const SizedBox(height: 20),
          _buildCard(children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircularProgressIndicator(color: Color(0xFF4CE0D2)),
                  SizedBox(width: 16),
                  Text('Carregando...', style: TextStyle(color: Color(0xFF4CE0D2))),
                ]),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B)))
            else if (_filtradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nenhuma reclamação encontrada.', style: TextStyle(color: Color(0xFF4CE0D2)), textAlign: TextAlign.center),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF0A1929)),
                  dataRowColor: WidgetStateProperty.all(const Color(0xFF102A43)),
                  border: TableBorder.all(color: const Color(0xFF4CE0D2)),
                  columns: const [
                    DataColumn(label: Text('ID', style: TextStyle(color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Título', style: TextStyle(color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Consumidor', style: TextStyle(color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold))),
                  ],
                  rows: _paginadas.map((r) => DataRow(cells: [
                    DataCell(Text('#${r.id}', style: const TextStyle(color: Color(0xFF4CE0D2)))),
                    DataCell(Text(r.titulo, style: const TextStyle(color: Color(0xFF4CE0D2)))),
                    DataCell(Text(r.nomeConsumidor ?? '-', style: const TextStyle(color: Color(0xFF4CE0D2)))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: r.statusColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(r.statusNome, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    )),
                  ])).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Página $_page de $_totalPages (${_filtradas.length} resultados)',
                    style: const TextStyle(color: Color(0xFF4CE0D2))),
                Row(children: [
                  ElevatedButton(
                    onPressed: _page > 1 ? () => setState(() => _page--) : null,
                    style: _btnStyle(),
                    child: const Text('Anterior'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _page < _totalPages ? () => setState(() => _page++) : null,
                    style: _btnStyle(),
                    child: const Text('Próxima'),
                  ),
                ]),
              ]),
            ],
          ]),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CE0D2)),
        boxShadow: [BoxShadow(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3), blurRadius: 15)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF4CE0D2)),
    filled: true,
    fillColor: const Color(0xFF0A1929),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF4CE0D2))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF4CE0D2), width: 2)),
    contentPadding: const EdgeInsets.all(15),
  );

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF4CE0D2),
    foregroundColor: const Color(0xFF0A1929),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  );
}
