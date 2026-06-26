import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/job_details_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:hireasy_mobile/features/jobs/presentation/widgets/job_card.dart';

class IndividualHomeScreen extends ConsumerStatefulWidget {
  const IndividualHomeScreen({super.key});

  @override
  ConsumerState<IndividualHomeScreen> createState() =>
      _IndividualHomeScreenState();
}

class _IndividualHomeScreenState extends ConsumerState<IndividualHomeScreen> {
  static const _primaryBlue = Color(0xFF3F7CF4);
  static const _navyBlue = Color(0xFF18346F);

  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(jobViewModelProvider.notifier).getJobs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobViewModelProvider);

    // Only keep verified jobs
    final verifiedJobs = state.jobs
        .where((job) => job.status.toLowerCase() == 'verified')
        .toList();

    // Create categories only from verified jobs
    final categories = <String>{
      'All',
      ...verifiedJobs
          .map((job) => job.roleType.trim())
          .where((category) => category.isNotEmpty),
    }.toList();

    // Apply search and category filters on verified jobs only
    final jobs = _filterJobs(verifiedJobs);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          _buildHeader(context),
          _CategoryBar(
            categories: categories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          Expanded(
            child: _buildJobsBody(
              jobs: jobs,
              isLoading: state.isFetchingJobs,
              errorMessage: state.errorMessage,
            ),
          ),
        ],
      ),
    );
  }

  List<JobEntity> _filterJobs(List<JobEntity> jobs) {
    final query = _searchController.text.trim().toLowerCase();

    return jobs.where((job) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          job.roleType.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          job.roleType.toLowerCase().contains(query) ||
          job.location.toLowerCase().contains(query) ||
          job.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white24,
                backgroundImage: AssetImage('assets/images/worker.png'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Find your next job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const _MessageButton(),
            ],
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search jobs or locations',
              hintStyle: const TextStyle(
                color: Color(0xFF92959D),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF25272C),
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCircle(icon: Icons.work_outline_rounded, title: 'Jobs'),
              _StatCircle(icon: Icons.send_outlined, title: 'Applied'),
              _StatCircle(icon: Icons.bookmark_border_rounded, title: 'Saved'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobsBody({
    required List<JobEntity> jobs,
    required bool isLoading,
    required String? errorMessage,
  }) {
    if (isLoading && jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && jobs.isEmpty) {
      return _FeedbackView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load jobs',
        message: errorMessage,
        buttonText: 'Try again',
        onPressed: () => ref.read(jobViewModelProvider.notifier).getJobs(),
      );
    }

    if (jobs.isEmpty) {
      return const _FeedbackView(
        icon: Icons.search_off_rounded,
        title: 'No jobs found',
        message: 'Try another search or category.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(jobViewModelProvider.notifier).getJobs(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 11),
        itemBuilder: (context, index) {
          final job = jobs[index];
          return JobCard(
            title: job.roleType.isEmpty ? 'Untitled job' : job.roleType,
            location: job.location.isEmpty
                ? 'Location not provided'
                : job.location,
            duration: job.shift.isEmpty ? 'Flexible shift' : job.shift,
            pay: '\$${_formatPay(job.pay)}',
            description: job.description,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
              );
            },
          );
        },
      ),
    );
  }

  String _formatPay(num pay) {
    return pay == pay.roundToDouble()
        ? pay.toInt().toString()
        : pay.toStringAsFixed(2);
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF18346F),
            side: const BorderSide(color: Color(0xFFB9C5DF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF18346F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: () {},
        padding: const EdgeInsets.all(15),
        icon: const Icon(
          Icons.chat_bubble_outline_rounded,
          color: Color(0xFF17191D),
          size: 23,
        ),
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _StatCircle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 29,
          backgroundColor: Colors.white,
          child: Icon(icon, color: const Color(0xFF18346F), size: 23),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FeedbackView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _FeedbackView({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF8C96AA)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF777C86)),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}
