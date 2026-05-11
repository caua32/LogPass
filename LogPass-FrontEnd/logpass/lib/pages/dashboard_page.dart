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
    _fadeCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _slideCtrl = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));
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
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A43),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF4CE0D2).withValues(alpha: 0.3), blurRadius: 15,
                  )],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CE0D2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF4CE0D2).withValues(alpha: 0.5),
                                blurRadius: 10, spreadRadius: 2,
                              )],
                            ),
                            child: const Icon(Icons.computer, color: Color(0xFF0A1929), size: 28),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LogPass', style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                              )),
                              Text('Bem-vindo, $nome!', style: const TextStyle(
                                fontSize: 14, color: Color(0xFF4CE0D2), fontStyle: FontStyle.italic,
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isEmpresa ? 'Empresa' : 'Consumidor',
                                  style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF4CE0D2), fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async => await context.read<AuthProvider>().logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CE0D2),
                        foregroundColor: const Color(0xFF0A1929),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      TweenAnimationBuilder(
                        duration: const Duration(seconds: 2),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (_, value, __) => Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CE0D2),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF4CE0D2).withValues(alpha: 0.4),
                                blurRadius: 30, spreadRadius: 5,
                              )],
                            ),
                            child: const Icon(Icons.computer, color: Color(0xFF0A1929), size: 60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text('LogPass', style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold,
                        color: Color(0xFF4CE0D2), letterSpacing: 2,
                      )),
                      const SizedBox(height: 60),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(child: _buildBtn(
                                icon: isEmpresa ? Icons.inventory_2_outlined : Icons.assignment_outlined,
                                label: isEmpresa ? 'Consultar\nDados' : 'Nova\nSolicitação',
                                route: isEmpresa ? '/empresa/consulta' : '/nova-reclamacao',
                                delay: 200,
                              )),
                              const SizedBox(width: 30),
                              Expanded(child: _buildBtn(
                                icon: isEmpresa ? Icons.chat_bubble_outline : Icons.support_agent,
                                label: isEmpresa ? 'Notificações\nProblemas' : 'Chat\nSuporte',
                                route: isEmpresa ? '/empresa/problemas' : '/nova-reclamacao',
                                delay: 400,
                              )),
                              const SizedBox(width: 30),
                              Expanded(child: _buildBtn(
                                icon: Icons.person_outline,
                                label: isEmpresa ? 'Perfil\nEmpresa' : 'Meus\nDados',
                                route: isEmpresa ? '/perfil/empresa' : '/perfil/consumidor',
                                delay: 600,
                              )),
                            ],
                          ),
                        ),
                      ),
                      if (isEmpresa) ...[
                        const SizedBox(height: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(child: _buildBtn(
                                  icon: Icons.warning_amber_outlined,
                                  label: 'Notificações\nde Problemas',
                                  route: '/empresa/problemas',
                                  delay: 700,
                                )),
                                const SizedBox(width: 15),
                                Expanded(child: _buildBtn(
                                  icon: Icons.analytics_outlined,
                                  label: 'Relatórios\ne Análises',
                                  route: '/empresa/relatorios',
                                  delay: 800,
                                )),
                                const SizedBox(width: 15),
                                Expanded(child: Container()),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102A43).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.3)),
                        ),
                        child: Column(children: [
                          const Text('Dica do dia', style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CE0D2),
                          )),
                          const SizedBox(height: 8),
                          Text(
                            isEmpresa
                                ? 'Verifique as notificações de problemas regularmente para manter a satisfação dos seus clientes.'
                                : 'Acesse Nova Solicitação sempre que precisar registrar um problema com um produto.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4CE0D2), fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ]),
                      ),
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

  Widget _buildBtn({required IconData icon, required String label, required String route, required int delay}) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (_, value, __) => Transform.scale(
        scale: 0.5 + (0.5 * value),
        child: Opacity(
          opacity: value,
          child: GestureDetector(
            onTap: () => context.push(route),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF102A43),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CE0D2).withValues(alpha: 0.5)),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF4CE0D2).withValues(alpha: 0.2), blurRadius: 15,
                )],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CE0D2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF4CE0D2).withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2,
                      )],
                    ),
                    child: Icon(icon, color: const Color(0xFF0A1929), size: 30),
                  ),
                  const SizedBox(height: 15),
                  Text(label, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: Color(0xFF4CE0D2), height: 1.2,
                  ), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

