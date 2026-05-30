import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _slideCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isEmpresa = auth.tipo == 'empresa';
    final nome = auth.user?.nome ?? 'Usuário';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(nome, isEmpresa),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildLogoSection(),
                      const SizedBox(height: 28),
                      _buildMenuGrid(isEmpresa),
                      const SizedBox(height: 20),
                      _buildTip(isEmpresa),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String nome, bool isEmpresa) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.2)),
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4CE0D2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(
                color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                blurRadius: 10, spreadRadius: 1,
              )],
            ),
            child: const Icon(Icons.computer, color: Color(0xFF0A1929), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LogPass', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Color(0xFF4CE0D2), letterSpacing: 1,
                )),
                Row(
                  children: [
                    Text('Olá, $nome', style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                    )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CE0D2).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4CE0D2).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isEmpresa ? 'Empresa' : 'Consumidor',
                        style: const TextStyle(
                          fontSize: 9, color: Color(0xFF4CE0D2),
                          fontWeight: FontWeight.bold, letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async => await context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout, size: 16, color: Color(0xFF4CE0D2)),
            label: const Text('Sair', style: TextStyle(
              color: Color(0xFF4CE0D2), fontSize: 13, fontWeight: FontWeight.w600,
            )),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (_, value, __) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.85 + (0.15 * value),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4CE0D2),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                color: const Color(0xFF4CE0D2).withValues(alpha: 0.35),
                blurRadius: 24, spreadRadius: 4,
              )],
            ),
            child: const Icon(Icons.computer, color: Color(0xFF0A1929), size: 42),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(bool isEmpresa) {
    final consumerItems = [
      _MenuItem(Icons.assignment_outlined, 'Nova\nSolicitação', '/nova-reclamacao', 100),
      _MenuItem(Icons.star_outline, 'Avaliação\nde Satisfação', '/satisfacao', 200),
      _MenuItem(Icons.person_outline, 'Meus\nDados', '/perfil/consumidor', 300),
      _MenuItem(Icons.list_alt_outlined, 'Minhas\nSolicitações', '/minhas-reclamacoes', 400),
    ];

    final empresaItems = [
      _MenuItem(Icons.inventory_2_outlined, 'Consultar\nDados', '/empresa/consulta', 100),
      _MenuItem(Icons.chat_bubble_outline, 'Notificações\nProblemas', '/empresa/problemas', 200),
      _MenuItem(Icons.person_outline, 'Perfil\nEmpresa', '/perfil/empresa', 300),
      _MenuItem(Icons.analytics_outlined, 'Relatórios\ne Análises', '/empresa/relatorios', 400),
    ];

    final items = isEmpresa ? empresaItems : consumerItems;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (_, i) => _buildMenuCard(items[i]),
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + item.delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (_, value, __) => Transform.scale(
        scale: 0.7 + (0.3 * value),
        child: Opacity(
          opacity: value,
          child: GestureDetector(
            onTap: () => context.push(item.route),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF102A43),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.08),
                  blurRadius: 12,
                )],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CE0D2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(item.icon, color: const Color(0xFF4CE0D2), size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(item.label, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF4CE0D2), height: 1.3,
                  ), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(bool isEmpresa) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              color: const Color(0xFF4CE0D2).withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEmpresa
                  ? 'Verifique as notificações regularmente para manter a satisfação dos clientes.'
                  : 'Use Nova Solicitação sempre que precisar registrar um problema com um produto.',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF4CE0D2).withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  final int delay;
  const _MenuItem(this.icon, this.label, this.route, this.delay);
}
