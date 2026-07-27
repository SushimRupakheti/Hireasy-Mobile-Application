import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/presentation/pages/individual/job_details_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/state/job_state.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:hireasy_mobile/features/jobs/presentation/widgets/job_card.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  final bool isActive;

  const MyJobsScreen({super.key, this.isActive = true});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  final _searchController = TextEditingController();
  DateTime? _selectedDate;
  bool _hasLoadedApplications = false;
  bool _isLoadingApplications = false;
  bool _hasRequestedApplications = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      Future.microtask(_loadApplications);
    }
  }

  @override
  void didUpdateWidget(covariant MyJobsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _loadApplications();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobViewModelProvider);
    if (widget.isActive &&
        !_hasLoadedApplications &&
        !_hasRequestedApplications &&
        !_isLoadingApplications) {
      Future.microtask(_loadApplications);
    }
    final appliedJobs = (_hasLoadedApplications ? state.jobs : <JobEntity>[])
        .where(_matchesSelectedDate)
        .where(_matchesSearch)
        .toList();

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
                  _selectedDate == null
                      ? 'All posted jobs'
                      : _fullDate(_selectedDate!),
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
              child: _buildBody(jobs: appliedJobs, state: state),
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

  bool _matchesSelectedDate(JobEntity job) {
    final selectedDate = _selectedDate;
    if (selectedDate == null) return true;

    final jobDate = _parseJobDate(job.jobDate);
    if (jobDate == null) return false;
    return _sameDay(jobDate, selectedDate);
  }

  DateTime? _parseJobDate(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return null;
    return DateTime.tryParse(trimmedValue);
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<void> _loadApplications() async {
    if (!mounted || !widget.isActive || _isLoadingApplications) {
      return;
    }
    setState(() {
      _hasLoadedApplications = false;
      _isLoadingApplications = true;
      _hasRequestedApplications = true;
    });
    await ref.read(jobViewModelProvider.notifier).getMyApplications();
    if (!mounted) return;
    final hasError = ref.read(jobViewModelProvider).errorMessage != null;
    setState(() {
      _hasLoadedApplications = !hasError;
      _isLoadingApplications = false;
    });
  }

  Widget _buildBody({required List<JobEntity> jobs, required JobState state}) {
    if (!_hasLoadedApplications &&
        (state.isFetchingApplications || _isLoadingApplications)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && jobs.isEmpty) {
      return _RefreshableState(
        onRefresh: _loadApplications,
        child: _EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load your jobs',
          message: state.errorMessage!,
          buttonText: 'Try again',
          onPressed: _loadApplications,
        ),
      );
    }
    if (jobs.isEmpty) {
      return _RefreshableState(
        onRefresh: _loadApplications,
        child: const _EmptyState(
          icon: Icons.work_history_outlined,
          title: 'No applications found',
          message: 'Jobs you apply for will appear here.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final job = jobs[index];
          final status = state.applicationStatuses[job.id] ?? 'pending';
          return JobCard(
            title: job.roleType.isEmpty ? 'Untitled job' : job.roleType,
            location: job.location.isEmpty
                ? 'Location not provided'
                : job.location,
            duration: job.shift.isEmpty ? 'Flexible shift' : job.shift,
            pay: 'NPR ${_formatPay(job.pay)}',
            description: job.description,
            status: status,
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
  static const _primaryColor = Color(0xFF203E7B);

  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onSelected;

  const _DateSelector({required this.selectedDate, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final anchorDate = selectedDate ?? currentDate;
    final dates = List.generate(
      7,
      (index) => anchorDate.add(Duration(days: index - 3)),
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
          final selected =
              selectedDate != null && _sameDay(date, selectedDate!);
          final isToday = _sameDay(date, currentDate);
          final borderColor = selected || isToday
              ? _primaryColor
              : const Color(0xFFD5D8DF);
          final borderWidth = selected || isToday ? 1.5 : 1.0;
          return InkWell(
            onTap: () => onSelected(selected ? null : date),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 71,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: borderWidth),
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

class _RefreshableState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _RefreshableState({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
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
