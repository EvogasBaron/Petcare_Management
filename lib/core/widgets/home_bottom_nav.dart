import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  static const _paths = [
    '/home/pets',
    '/home/reminders',
    '/home/clinics',
    '/home/appointments',
    '/home/profile',
  ];

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          if (idx != currentIndex) {
            context.go(_paths[idx]);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Thú cưng'),
          NavigationDestination(
              icon: Icon(Icons.alarm_outlined), selectedIcon: Icon(Icons.alarm), label: 'Nhắc lịch'),
          NavigationDestination(
              icon: Icon(Icons.local_hospital_outlined),
              selectedIcon: Icon(Icons.local_hospital),
              label: 'Phòng khám'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Lịch hẹn'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      );
}
