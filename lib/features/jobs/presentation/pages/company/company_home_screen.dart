import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/presentation/providers/current_profile_provider.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:hireasy_mobile/features/jobs/presentation/widgets/home_profile_avatar.dart';

import '../../widgets/worker_category_card.dart';

class _WorkerCategory {
  final String title;
  final String imagePath;

  const _WorkerCategory({required this.title, required this.imagePath});
}

class CompanyHomeScreen extends ConsumerStatefulWidget {
  final bool isActive;
  final ValueChanged<String?>? onPostJobRequested;

  const CompanyHomeScreen({
    super.key,
    this.isActive = true,
    this.onPostJobRequested,
  });

  @override
  ConsumerState<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends ConsumerState<CompanyHomeScreen> {
  final _searchController = TextEditingController();
  Timer? _statsRefreshTimer;
  bool _isRefreshingStats = false;

  static const _categories = [
    _WorkerCategory(
      title: 'Warehouse Associates',
      imagePath: 'assets/images/warehouse.jpg',
    ),
    _WorkerCategory(
      title: 'Factory Workers',
      imagePath: 'assets/images/factory.jpg',
    ),
    _WorkerCategory(title: 'Labors', imagePath: 'assets/images/labors.jpg'),
    _WorkerCategory(title: 'Handyman', imagePath: 'assets/images/handyman.jpg'),
    _WorkerCategory(title: 'Painters', imagePath: 'assets/images/painter.jpg'),
    _WorkerCategory(title: 'Cleaners', imagePath: 'assets/images/cleaner.jpg'),
    _WorkerCategory(title: 'Waiters', imagePath: 'assets/images/waiter.jpg'),
    _WorkerCategory(title: 'Movers', imagePath: 'assets/images/mover.jpg'),
  ];

  static const _primaryBlue = Color(0xFF3F7CF4);
  static const _navyBlue = Color(0xFF18346F);

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      Future.microtask(_startRefreshingStats);
    }
  }

  @override
  void didUpdateWidget(covariant CompanyHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;

    if (widget.isActive) {
      _startRefreshingStats();
    } else {
      _stopRefreshingStats();
    }
  }

  @override
  void dispose() {
    _stopRefreshingStats();
    _searchController.dispose();
    super.dispose();
  }

  void _startRefreshingStats() {
    if (!mounted || _statsRefreshTimer != null) return;
    _refreshStats();
    _statsRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshStats(),
    );
  }

  void _stopRefreshingStats() {
    _statsRefreshTimer?.cancel();
    _statsRefreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredCategories;
    final jobState = ref.watch(jobViewModelProvider);
    final profile = ref.watch(currentProfileProvider);
    final user = profile.maybeWhen(data: (user) => user, orElse: () => null);
    final accountStatus = _accountStatusLabel(
      user?.status ?? ref.watch(tokenServiceProvider).userStatus,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPostJobScreen(context),
        backgroundColor: _navyBlue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: Column(
        children: [
          _buildHeader(
            context,
            profile: user,
            postedJobsCount: jobState.jobs.length,
            activeJobsCount: jobState.jobs.where(_isActiveJob).length,
            accountStatus: accountStatus,
            isLoadingStats: jobState.isFetchingJobs && jobState.jobs.isEmpty,
          ),
          const _SectionTitle(),
          Expanded(
            child: categories.isEmpty
                ? const _NoCategoryResults()
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return WorkerCategoryCard(
                        title: category.title,
                        imagePath: category.imagePath,
                        onTap: () =>
                            _openPostJobScreen(context, category.title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_WorkerCategory> get _filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories
        .where((category) => category.title.toLowerCase().contains(query))
        .toList();
  }

  void _openPostJobScreen(BuildContext context, [String? roleType]) {
    widget.onPostJobRequested?.call(roleType);
  }

  Future<void> _refreshStats() async {
    if (!mounted ||
        !widget.isActive ||
        _isRefreshingStats ||
        ref.read(jobViewModelProvider).isFetchingJobs) {
      return;
    }

    _isRefreshingStats = true;
    try {
      await ref.read(jobViewModelProvider.notifier).getMyJobs();
    } finally {
      _isRefreshingStats = false;
    }
  }

  bool _isActiveJob(JobEntity job) {
    final status = job.status.trim().toLowerCase();
    return status.isEmpty ||
        status == 'open' ||
        status == 'active' ||
        status == 'verified' ||
        status == 'in progress' ||
        status == 'in_progress';
  }

  String _accountStatusLabel(String? status) {
    final normalized = status?.trim().toLowerCase() ?? '';
    if (normalized == 'verified') return 'Verified';
    if (normalized == 'rejected') return 'Rejected';
    return 'Pending';
  }

  Widget _buildHeader(
    BuildContext context, {
    required AuthEntity? profile,
    required int postedJobsCount,
    required int activeJobsCount,
    required String accountStatus,
    required bool isLoadingStats,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final postedJobsValue = isLoadingStats ? '...' : postedJobsCount.toString();
    final activeJobsValue = isLoadingStats ? '...' : activeJobsCount.toString();
    final displayName = _companyDisplayName(profile);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              HomeProfileAvatar(
                radius: 28,
                imageUrl: profile?.profileImage,
                fallbackAsset: 'assets/images/client.png',
                fallbackText: displayName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _MessageButton(onPressed: () {}),
            ],
          ),
          const SizedBox(height: 34),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
            decoration: InputDecoration(
              hintText: 'Search ...',
              hintStyle: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 15,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? const Icon(
                      Icons.search_rounded,
                      color: Colors.black,
                      size: 28,
                    )
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatWidget(
                value: postedJobsValue,
                title: 'Jobs Posted',
                icon: Icons.work_outline_rounded,
              ),
              _StatWidget(
                value: activeJobsValue,
                title: 'Active Jobs',
                icon: Icons.task_alt_rounded,
              ),
              _StatWidget(
                value: accountStatus,
                title: 'Status',
                icon: _statusIcon(accountStatus),
                iconColor: Colors.white,
                iconBackgroundColor: _statusColor(accountStatus),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'open':
      case 'opened':
        return const Color(0xFF38C95B);
      case 'rejected':
        return const Color(0xFFE90012);
      case 'closed':
        return const Color(0xFF8E929B);
      default:
        return const Color(0xFFD5D91C);
    }
  }

  String _companyDisplayName(AuthEntity? profile) {
    final companyName = profile?.companyName?.trim() ?? '';
    if (companyName.isNotEmpty) return companyName;

    final email = profile?.email.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Company';
  }
}

class _MessageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MessageButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF161616),
                size: 25,
              ),
              Positioned(
                right: 16,
                top: 16,
                child: CircleAvatar(
                  radius: 3.5,
                  backgroundColor: Color(0xFFFF001D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String value;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  const _StatWidget({
    required this.value,
    required this.title,
    required this.icon,
    this.iconColor = const Color(0xFF121212),
    this.iconBackgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: iconBackgroundColor,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 34,
      alignment: Alignment.center,
      color: Colors.white,
      child: const Text(
        'Search for workers',
        style: TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _NoCategoryResults extends StatelessWidget {
  const _NoCategoryResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'No matching worker categories found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF777C86),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
