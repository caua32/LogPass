import 'package:go_router/go_router.dart';
import 'models/reclamacao_model.dart';
import 'providers/auth_provider.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/admin_login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/consumidor/request_page.dart';
import 'pages/consumidor/satisfaction_page.dart';
import 'pages/consumidor/user_profile_page.dart';
import 'pages/empresa/company_profile_page.dart';
import 'pages/empresa/data_consult_page.dart';
import 'pages/empresa/problems_notification_page.dart';
import 'pages/empresa/reports_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'pages/admin/admin_reclamacao_detail_page.dart';
import 'pages/chat/chat_page.dart';
import 'pages/consumidor/minhas_reclamacoes_page.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/login',
    redirect: (context, state) {
      if (auth.loading) return null;
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;
      const publicPaths = ['/login', '/register', '/admin/login'];
      if (!loggedIn && !publicPaths.contains(loc) && !loc.startsWith('/admin')) {
        return '/login';
      }
      if (loggedIn && publicPaths.contains(loc)) return '/dashboard';
      if (loggedIn && !loc.startsWith('/admin')) {
        final tipo = auth.tipo;
        const empresaOnly = ['/empresa/consulta', '/empresa/problemas', '/empresa/relatorios', '/perfil/empresa'];
        const consumidorOnly = ['/nova-reclamacao', '/satisfacao', '/perfil/consumidor', '/minhas-reclamacoes'];
        if (tipo == 'consumidor' && empresaOnly.contains(loc)) return '/dashboard';
        if (tipo == 'empresa' && consumidorOnly.contains(loc)) return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      GoRoute(path: '/admin/login', builder: (c, s) => const AdminLoginPage()),
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardPage()),
      GoRoute(path: '/nova-reclamacao', builder: (c, s) => const RequestPage()),
      GoRoute(path: '/satisfacao', builder: (c, s) => const SatisfactionPage()),
      GoRoute(path: '/perfil/consumidor', builder: (c, s) => const UserProfilePage()),
      GoRoute(path: '/perfil/empresa', builder: (c, s) => const CompanyProfilePage()),
      GoRoute(path: '/empresa/consulta', builder: (c, s) => const DataConsultPage()),
      GoRoute(path: '/empresa/problemas', builder: (c, s) => const ProblemsNotificationPage()),
      GoRoute(path: '/empresa/relatorios', builder: (c, s) => const ReportsPage()),
      GoRoute(path: '/admin/dashboard', builder: (c, s) => const AdminDashboardPage()),
      GoRoute(
        path: '/admin/reclamacao/:id',
        builder: (c, s) {
          final rec = s.extra as Reclamacao;
          return AdminReclamacaoDetailPage(reclamacao: rec);
        },
      ),
      GoRoute(path: '/minhas-reclamacoes', builder: (c, s) => const MinhasReclamacoesPage()),
      GoRoute(
        path: '/chat/:id',
        builder: (c, s) {
          final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
          final extra = s.extra as Map<String, dynamic>?;
          final titulo = extra?['titulo'] as String? ?? 'Reclamao #$id';
          return ChatPage(reclamacaoId: id, titulo: titulo);
        },
      ),
    ],
  );
}
