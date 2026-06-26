import 'package:flutter/material.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/company/company_home_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/company/company_post_job_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/individual_home_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/my_jobs_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/profile_screen.dart';

class CollectiveScreen extends StatefulWidget {
  final String role;

  const CollectiveScreen({super.key, required this.role});

  @override
  State<CollectiveScreen> createState() => _CollectiveScreenState();
}

class _CollectiveScreenState extends State<CollectiveScreen> {
  int _currentIndex = 0;
  String? _initialRoleType;
  int _postScreenVersion = 0;

  bool get _isCompany {
    final role = widget.role.trim().toLowerCase();
    return role == 'company' || role == 'client' || role == 'employer';
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openPostJob([String? roleType]) {
    setState(() {
      _initialRoleType = roleType;
      _postScreenVersion++;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      _isCompany
          ? CompanyHomeScreen(onPostJobRequested: _openPostJob)
          : const IndividualHomeScreen(),
      _isCompany
          ? CompanyPostJobScreen(
              key: ValueKey(_postScreenVersion),
              initialRoleType: _initialRoleType,
            )
          : const MyJobsScreen(),
      const _PlaceholderScreen(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        message: 'Your latest updates will appear here.',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _CollectiveBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        secondLabel: _isCompany ? 'Post job' : 'Applications',
      ),
    );
  }
}

class _CollectiveBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String secondLabel;

  const _CollectiveBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.secondLabel,
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
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
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
          child: Icon(
            selected ? selectedIcon : icon,
            color: selected ? Colors.white : const Color(0xFF17191D),
            size: 29,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 50, color: const Color(0xFF71809C)),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF777C86)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
