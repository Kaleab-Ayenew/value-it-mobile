import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pending_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/inspection/inspection_form_screen.dart';
import '../features/inspection/inspector_home.dart';
import '../features/projects/assign_screen.dart';
import '../features/projects/manager_home.dart';
import '../features/projects/project_form_screen.dart';
import '../features/projects/report_review_screen.dart';
import '../features/valuation/valuation_screen.dart';
import '../features/valuation/valuer_home.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (auth.isLoading) return null;

      final user = auth.valueOrNull;
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }
      if (user.isPending) {
        return loc == '/pending' ? null : '/pending';
      }
      if (isAuthRoute || loc == '/pending') {
        return homeRouteFor(user);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingScreen()),
      GoRoute(path: '/manager', builder: (_, __) => const ManagerHome()),
      GoRoute(path: '/manager/project/new', builder: (_, __) => const ProjectFormScreen()),
      GoRoute(
        path: '/manager/project/:id/assign',
        builder: (_, s) => AssignScreen(projectId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/manager/project/:id/report',
        builder: (_, s) => ReportReviewScreen(projectId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/valuer', builder: (_, __) => const ValuerHome()),
      GoRoute(
        path: '/valuer/project/:id',
        builder: (_, s) => ValuationScreen(projectId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/inspector', builder: (_, __) => const InspectorHome()),
      GoRoute(
        path: '/inspector/project/:id',
        builder: (_, s) => InspectionFormScreen(projectId: int.parse(s.pathParameters['id']!)),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}
