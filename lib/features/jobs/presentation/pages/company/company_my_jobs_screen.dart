import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/job_details_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/state/job_state.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:hireasy_mobile/features/jobs/presentation/widgets/job_card.dart';

class CompanyMyJobsScreen extends ConsumerStatefulWidget {
  const CompanyMyJobsScreen({super.key});

  @override
  ConsumerState<CompanyMyJobsScreen> createState() =>
      _CompanyMyJobsScreenState();
}

class _CompanyMyJobsScreenState extends ConsumerState<CompanyMyJobsScreen> {
  final _searchController = TextEditingController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    Future.microtask(() => ref.read(jobViewModelProvider.notifier).getMyJobs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobViewModelProvider);
    final myJobs = state.jobs.where(_matchesSearch).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),
            const Text(
              'My Jobs',
              style: TextStyle(
                color: Color(0xFF111318),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search previous jobs...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF92959D),
                    fontSize: 13,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? const Icon(
                          Icons.search_rounded,
                          color: Colors.black,
                          size: 27,
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
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _fullDate(_selectedDate),
                  style: const TextStyle(
                    color: Color(0xFF252832),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _DateSelector(
              selectedDate: _selectedDate,
              onSelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _buildBody(jobs: myJobs, state: state),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSearch(JobEntity job) {
    final query = _searchController.text.trim().toLowerCase();
    return query.isEmpty ||
        job.roleType.toLowerCase().contains(query) ||
        job.location.toLowerCase().contains(query) ||
        job.description.toLowerCase().contains(query);
  }

  Widget _buildBody({required List<JobEntity> jobs, required JobState state}) {
    if (state.isFetchingJobs && state.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.jobs.isEmpty) {
      return _EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load your jobs',
        message: state.errorMessage!,
        buttonText: 'Try again',
        onPressed: () => ref.read(jobViewModelProvider.notifier).getMyJobs(),
      );
    }
    if (jobs.isEmpty) {
      return const _EmptyState(
        icon: Icons.work_outline_rounded,
        title: 'No jobs posted yet',
        message: 'Jobs you post will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(jobViewModelProvider.notifier).getMyJobs(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
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
            status: job.status.isEmpty ? 'open' : job.status,
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

  String _fullDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${_weekday(date.weekday)} ${months[date.month - 1]} ${date.year} ▼';
  }

  String _weekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  const _DateSelector({required this.selectedDate, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (index) => selectedDate.add(Duration(days: index - 3)),
    );

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          final date = dates[index];
          final selected = _sameDay(date, selectedDate);
          return InkWell(
            onTap: () => onSelected(date),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 71,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF203E7B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF203E7B)
                      : const Color(0xFFD5D8DF),
                ),
                boxShadow: selected
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _month(date.month),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF20242C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF20242C),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _weekday(date.weekday),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF20242C),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _weekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _EmptyState({
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
            Icon(icon, size: 46, color: const Color(0xFF7A8498)),
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
