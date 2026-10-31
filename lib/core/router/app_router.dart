import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_clinic_detail_screen.dart';
import '../../features/admin/presentation/admin_clinics_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/appointments/presentation/book_appointment_screen.dart';
import '../../features/appointments/presentation/user_appointment_detail_screen.dart';
import '../../features/appointments/presentation/user_appointments_screen.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/locked_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/clinic_admin/presentation/clinic_appointment_detail_screen.dart';
import '../../features/clinic_admin/presentation/clinic_dashboard_screen.dart';
import '../../features/clinic_admin/presentation/clinic_doctors_screen.dart';
import '../../features/clinic_admin/presentation/clinic_services_screen.dart';
import '../../features/clinic_admin/presentation/clinic_setup_screen.dart';
import '../../features/clinic_admin/presentation/clinic_status_screen.dart';
import '../../features/clinics/presentation/clinic_detail_screen.dart';
import '../../features/clinics/presentation/clinics_screen.dart';
import '../../features/pets/presentation/pet_detail_screen.dart';
import '../../features/pets/presentation/pet_form_screen.dart';
import '../../features/pets/presentation/pet_list_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/clinic.dart';
import '../providers/session_providers.dart';
import '../widgets/state_views.dart';

const _publicPaths = {'/login', '/register', '/forgot-password'};
const _clinicStatusPaths = {'/clinic/setup', '/clinic/pending', '/clinic/rejected', '/clinic/locked'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => computeRedirect(
      loc: state.matchedLocation,
      auth: ref.read(authStateProvider),
      profile: ref.read(currentUserProvider),
      clinic: ref.read(myClinicProvider),
    ),
    routes: _routes,
  );
});

/// Báo cho GoRouter chạy lại redirect khi phiên đăng nhập, hồ sơ người dùng hoặc trạng thái phòng khám đổi.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
    ref.listen(myClinicProvider, (_, __) => notifyListeners());
  }
}

/// Quyết định chuyển hướng theo vai trò; trả null nghĩa là giữ nguyên. Hàm thuần để test.
String? computeRedirect({
  required String loc,
  required AsyncValue<Object?> auth,
  required AsyncValue<AppUser?> profile,
  required AsyncValue<Clinic?> clinic,
}) {
  String? to(String target) => loc == target ? null : target;

  if (auth.isLoading) return to('/splash');
  final signedIn = auth.when(data: (u) => u != null, loading: () => false, error: (_, __) => false);
  if (!signedIn) return _publicPaths.contains(loc) ? null : '/login';

  if (profile.hasError) return to('/login');
  if (profile.isLoading) return to('/splash');
  final user = profile.when(data: (u) => u, loading: () => null, error: (_, __) => null);
  if (user == null) return to('/splash');
  if (user.isLocked) return to('/locked');

  switch (user.role) {
    case Roles.admin:
      return loc.startsWith('/admin') ? null : '/admin/clinics';
    case Roles.clinic:
      return _clinicRedirect(loc, clinic);
    default:
      return loc.startsWith('/home') ? null : '/home/pets';
  }
}

String? _clinicRedirect(String loc, AsyncValue<Clinic?> clinicAsync) {
  if (clinicAsync.isLoading) return loc == '/splash' ? null : '/splash';
  final c = clinicAsync.when(data: (x) => x, loading: () => null, error: (_, __) => null);
  final status = c?.status;
  final home = switch (status) {
    null => '/clinic/setup',
    ClinicStatus.pending => '/clinic/pending',
    ClinicStatus.rejected => '/clinic/rejected',
    ClinicStatus.locked => '/clinic/locked',
    _ => '/clinic/dashboard',
  };
  if (home == '/clinic/dashboard') {
    return loc.startsWith('/clinic') && !_clinicStatusPaths.contains(loc) ? null : home;
  }
  final allowed = loc == home || (status == ClinicStatus.rejected && loc == '/clinic/setup');
  return allowed ? null : home;
}

/// Danh sách route đầy đủ cho toàn bộ 3 vai trò trong MVP. Thứ tự quan trọng: '/new' đứng trước '/:petId'.
final _routes = <RouteBase>[
  GoRoute(path: '/splash', builder: (_, __) => const Scaffold(body: LoadingView())),
  GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
  GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
  GoRoute(path: '/locked', builder: (_, __) => const LockedScreen()),
  // Chủ nuôi
  GoRoute(path: '/home/pets', builder: (_, __) => const PetListScreen()),
  GoRoute(path: '/home/pets/new', builder: (_, __) => const PetFormScreen()),
  GoRoute(
    path: '/home/pets/:petId',
    builder: (_, state) => PetDetailScreen(petId: state.pathParameters['petId']!),
  ),
  GoRoute(
    path: '/home/pets/:petId/edit',
    builder: (_, state) => PetFormScreen(petId: state.pathParameters['petId']),
  ),
  GoRoute(path: '/home/reminders', builder: (_, __) => const RemindersScreen()),
  GoRoute(path: '/home/clinics', builder: (_, __) => const ClinicsScreen()),
  GoRoute(
    path: '/home/clinics/:clinicId',
    builder: (_, state) => ClinicDetailScreen(clinicId: state.pathParameters['clinicId']!),
  ),
  GoRoute(
    path: '/home/clinics/:clinicId/book',
    builder: (_, state) => BookAppointmentScreen(clinicId: state.pathParameters['clinicId']!),
  ),
  GoRoute(path: '/home/appointments', builder: (_, __) => const UserAppointmentsScreen()),
  GoRoute(
    path: '/home/appointments/:id',
    builder: (_, state) => UserAppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
  ),
  GoRoute(path: '/home/profile', builder: (_, __) => const ProfileScreen()),
  GoRoute(path: '/home/change-password', builder: (_, __) => const ChangePasswordScreen()),
  // Đối tác phòng khám
  GoRoute(path: '/clinic/setup', builder: (_, __) => const ClinicSetupScreen()),
  GoRoute(
    path: '/clinic/pending',
    builder: (_, __) => const ClinicStatusScreen(status: ClinicStatus.pending),
  ),
  GoRoute(
    path: '/clinic/rejected',
    builder: (_, __) => const ClinicStatusScreen(status: ClinicStatus.rejected),
  ),
  GoRoute(
    path: '/clinic/locked',
    builder: (_, __) => const ClinicStatusScreen(status: ClinicStatus.locked),
  ),
  GoRoute(path: '/clinic/dashboard', builder: (_, __) => const ClinicDashboardScreen()),
  GoRoute(
    path: '/clinic/appointments/:id',
    builder: (_, state) => ClinicAppointmentDetailScreen(appointmentId: state.pathParameters['id']!),
  ),
  GoRoute(path: '/clinic/services', builder: (_, __) => const ClinicServicesScreen()),
  GoRoute(path: '/clinic/doctors', builder: (_, __) => const ClinicDoctorsScreen()),
  GoRoute(path: '/clinic/profile', builder: (_, __) => const ClinicSetupScreen()),
  GoRoute(path: '/clinic/change-password', builder: (_, __) => const ChangePasswordScreen()),
  // Admin
  GoRoute(path: '/admin/clinics', builder: (_, __) => const AdminClinicsScreen()),
  GoRoute(
    path: '/admin/clinics/:id',
    builder: (_, state) => AdminClinicDetailScreen(clinicId: state.pathParameters['id']!),
  ),
  GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
  GoRoute(path: '/admin/change-password', builder: (_, __) => const ChangePasswordScreen()),
];
