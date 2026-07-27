import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/company/company_home_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/company/company_job_details_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/company/company_my_jobs_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/company/company_post_job_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/individual_home_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/individual_job_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/job_details_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/profile_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/providers/current_profile_provider.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:hireasy_mobile/features/notifications/presentation/pages/notification_screen.dart';
import 'package:hireasy_mobile/features/notifications/presentation/view_model/notification_view_model.dart';
import 'package:hireasy_mobile/features/support_messages/presentation/pages/support_chat_screen.dart';

class CollectiveScreen extends ConsumerStatefulWidget {
  final String role;

  const CollectiveScreen({super.key, required this.role});

  @override
  ConsumerState<CollectiveScreen> createState() => _CollectiveScreenState();
}

class _CollectiveScreenState extends ConsumerState<CollectiveScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _notificationTimer;

  bool get _isCompany {
    final role = widget.role.trim().toLowerCase();
    return role == 'company' || role == 'client' || role == 'employer';
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_startNotifications);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopNotificationPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startNotifications();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopNotificationPolling();
    }
  }

  Future<void> _startNotifications() async {
    if (!mounted) return;
    await ref.read(notificationViewModelProvider.notifier).initialize();
    if (!mounted || _notificationTimer != null) return;
    _notificationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      ref.read(notificationViewModelProvider.notifier).refresh();
      ref.invalidate(currentProfileProvider);
    });
  }

  void _stopNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  void _openPostJob([String? roleType]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyPostJobScreen(initialRoleType: roleType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationViewModelProvider);
    final screens = <Widget>[
      _isCompany
          ? CompanyHomeScreen(
              isActive: _currentIndex == 0,
              onPostJobRequested: _openPostJob,
            )
          : const IndividualHomeScreen(),
      _isCompany
          ? CompanyMyJobsScreen(isActive: _currentIndex == 1)
          : IndividualJobScreen(isActive: _currentIndex == 1),
      NotificationScreen(
        onOpenProfile: () => _selectTab(3),
        onOpenJob: (jobId) => _openNotificationJob(jobId),
        onOpenApplicants: (jobId) => _openNotificationJob(jobId),
        onOpenSupport: _openSupport,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _CollectiveBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        secondLabel: _isCompany ? 'My Jobs' : 'Applications',
        hasUnreadNotifications:
            notificationState.isAuthenticated &&
            notificationState.unreadCount > 0,
      ),
    );
  }

  void _openNotificationJob(String jobId) {
    final job = _findJob(jobId);
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job is not currently available.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isCompany
            ? CompanyJobDetailsScreen(job: job)
            : JobDetailsScreen(job: job),
      ),
    );
  }

  void _openSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupportChatScreen()),
    );
  }

  JobEntity? _findJob(String jobId) {
    for (final job in ref.read(jobViewModelProvider).jobs) {
      if (job.id == jobId) return job;
    }
    return null;
  }
}

class _CollectiveBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String secondLabel;
  final bool hasUnreadNotifications;

  const _CollectiveBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.secondLabel,
    required this.hasUnreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E4E9))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavigationItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavigationItem(
              icon: Icons.description_outlined,
              selectedIcon: Icons.description_rounded,
              label: secondLabel,
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavigationItem(
              icon: Icons.notifications_none_rounded,
              selectedIcon: Icons.notifications_rounded,
              label: 'Notifications',
              selected: currentIndex == 2,
              showUnreadDot: hasUnreadNotifications,
              onTap: () => onTap(2),
            ),
            _NavigationItem(
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool showUnreadDot;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    this.showUnreadDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF435D95) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : const Color(0xFF17191D),
                size: 29,
              ),
              if (showUnreadDot)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
