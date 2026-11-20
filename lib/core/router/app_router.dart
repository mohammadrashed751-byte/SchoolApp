import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/pending_approval_page.dart';
import '../../features/auth/presentation/pages/register_driver_page.dart';
import '../../features/auth/presentation/pages/register_parent_page.dart';
import '../../features/auth/presentation/pages/register_supervisor_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../features/driver/presentation/pages/driver_home_page.dart';
import '../../features/parent/presentation/cubit/link_request_cubit.dart';
import '../../features/parent/presentation/cubit/parent_gate_cubit.dart';
import '../../features/parent/presentation/pages/parent_gate_page.dart';
import '../../features/supervisor/presentation/pages/supervisor_home_page.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

const _roleParent = 'Parent';
const _roleDriver = 'Driver';
const _roleSupervisor = 'Supervisor';

/// Builds the app router. The `/parent` route's Cubits are created through
/// the two factory callbacks rather than reached for via `getIt` directly
/// in this file, so the router stays testable with fakes and has no direct
/// get_it dependency of its own.
GoRouter buildAppRouter(
  AuthCubit authCubit, {
  required ParentGateCubit Function() createParentGateCubit,
  required LinkRequestCubit Function() createLinkRequestCubit,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) => computeRedirect(authCubit, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.registerParent,
        builder: (context, state) => const RegisterParentPage(),
      ),
      GoRoute(
        path: AppRoutes.registerDriver,
        builder: (context, state) => const RegisterDriverPage(),
      ),
      GoRoute(
        path: AppRoutes.registerSupervisor,
        builder: (context, state) => const RegisterSupervisorPage(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalPage(),
      ),
      GoRoute(
        path: AppRoutes.parent,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<ParentGateCubit>(create: (_) => createParentGateCubit()),
            BlocProvider<LinkRequestCubit>(create: (_) => createLinkRequestCubit()),
          ],
          child: const ParentGatePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (context, state) => const DriverHomePage(),
      ),
      GoRoute(
        path: AppRoutes.supervisorHome,
        builder: (context, state) => const SupervisorHomePage(),
      ),
    ],
  );
}

/// Pure redirect decision, factored out of [buildAppRouter] so it can be
/// unit-tested without a running [GoRouter].
///
/// `/pending-approval` is intentionally never checked here: it is reachable
/// only by explicit navigation and is never an automatic redirect source or
/// target.
String? computeRedirect(AuthCubit authCubit, GoRouterState state) {
  final authState = authCubit.state;
  final location = state.matchedLocation;

  final isSplash = location == AppRoutes.splash;
  final isLogin = location == AppRoutes.login;
  final isRoleHome = location == AppRoutes.parent ||
      location == AppRoutes.driverHome ||
      location == AppRoutes.supervisorHome;
  final isRegisterRoute = location.startsWith(AppRoutes.register);

  if (authState is AuthInitial || authState is AuthLoading) {
    return isSplash ? null : AppRoutes.splash;
  }

  if (authState is AuthUnauthenticated ||
      authState is AuthActionFailure ||
      authState is AuthRegistrationSuccess) {
    if (isSplash || isRoleHome) return AppRoutes.login;
    return null;
  }

  if (authState is AuthAuthenticated) {
    if (isSplash || isLogin || isRegisterRoute) {
      final target = _homeRouteFor(authState.user.roleCode);
      // Avoid go_router flagging a "redirect to the same place" as a loop
      // when the role is unrecognized and we're already sitting at /login.
      return target == location ? null : target;
    }
    return null;
  }

  return null;
}

String _homeRouteFor(String roleCode) {
  switch (roleCode) {
    case _roleParent:
      return AppRoutes.parent;
    case _roleDriver:
      return AppRoutes.driverHome;
    case _roleSupervisor:
      return AppRoutes.supervisorHome;
    default:
      if (kDebugMode) {
        debugPrint('computeRedirect: unexpected roleCode "$roleCode", sending to /login');
      }
      return AppRoutes.login;
  }
}
