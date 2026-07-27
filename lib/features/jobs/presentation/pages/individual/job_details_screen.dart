import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/get_current_user.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';

final applicationUserProvider = FutureProvider.autoDispose<AuthEntity?>((ref) {
  return ref.read(getCurrentUserUsecaseProvider).call();
});

class JobDetailsScreen extends ConsumerStatefulWidget {
  final JobEntity job;
  final String? applicationStatus;

  const JobDetailsScreen({
    super.key,
    required this.job,
    this.applicationStatus,
  });

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  JobEntity get job => widget.job;

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobViewModelProvider);
    final isApplying = jobState.isApplying && jobState.applyingJobId == job.id;
    final hasApplied = widget.applicationStatus != null ||
        (job.id != null && jobState.appliedJobIds.contains(job.id));
    final applicationStatus = widget.applicationStatus ?? (job.id == null
        ? null
        : jobState.applicationStatuses[job.id]);
    final isVerified = ref.read(tokenServiceProvider).isVerified;
    final currentUser = ref.watch(applicationUserProvider);
    final isCheckingResume = currentUser.isLoading;
    final hasResume =
        currentUser.value?.document?.documentType.trim().toLowerCase() ==
        'resume';
    final isUnavailable = _unavailableStatuses.contains(
      job.status.trim().toLowerCase(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Job details',
          style: TextStyle(
            color: Color(0xFF17191D),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JobPhotoGallery(photoUrls: _photoUrls),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.roleType.isEmpty
                                ? 'Untitled job'
                                : _displayValue(job.roleType),
                            style: const TextStyle(
                              color: Color(0xFF17191D),
                              fontSize: 25,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'NPR ${_formatPay(job.pay)}',
                                style: const TextStyle(
                                  color: Color(0xFFFF3347),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: '/hr',
                                style: TextStyle(
                                  color: Color(0xFF8E929B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      text: job.location.isEmpty
                          ? 'Location not provided'
                          : _displayValue(job.location),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      text: job.shift.isEmpty
                          ? 'Flexible shift'
                          : _displayValue(job.shift),
                    ),
                    if (job.jobDate.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        text: _formatJobDate(job.jobDate),
                      ),
                    ],
                    if (job.status.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.info_outline_rounded,
                        text: _capitalize(_displayValue(job.status)),
                      ),
                    ],
                    if (hasApplied) ...[
                      const SizedBox(height: 24),
                      _ApplicationStatusCard(
                        status: applicationStatus ?? 'pending',
                      ),
                    ],
                    const SizedBox(height: 28),
                    const _SectionTitle('Description'),
                    const SizedBox(height: 10),
                    Text(
                      job.description.trim().isEmpty
                          ? 'No description was provided for this job.'
                          : job.description,
                      style: const TextStyle(
                        color: Color(0xFF686D77),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E4E9))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed:
                      isApplying ||
                          isUnavailable ||
                          hasApplied ||
                          !isVerified ||
                          isCheckingResume ||
                          !hasResume
                      ? null
                      : _applyForJob,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF18346F),
                    disabledBackgroundColor: const Color(0xFF9CA6BA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isApplying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _buttonLabel(
                            isUnavailable: isUnavailable,
                            hasApplied: hasApplied,
                            isVerified: isVerified,
                            isCheckingResume: isCheckingResume,
                            hasResume: hasResume,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _unavailableStatuses = {'closed', 'filled', 'cancelled'};

  String _buttonLabel({
    required bool isUnavailable,
    required bool hasApplied,
    required bool isVerified,
    required bool isCheckingResume,
    required bool hasResume,
  }) {
    if (hasApplied) {
      return 'Already applied';
    }
    if (isUnavailable) return 'Job unavailable';
    if (!isVerified) return 'Verification required';
    if (isCheckingResume) return 'Checking resume...';
    if (!hasResume) return 'Upload resume to apply';
    return 'Apply for this job';
  }

  Future<void> _applyForJob() async {
    final jobId = job.id;
    if (jobId == null || jobId.trim().isEmpty) {
      _showMessage('This job does not have a valid ID.', isError: true);
      return;
    }

    final applied = await ref
        .read(jobViewModelProvider.notifier)
        .applyForJob(jobId);
    if (!mounted) return;

    final state = ref.read(jobViewModelProvider);
    if (applied) {
      _showMessage(state.successMessage ?? 'Applied successfully');
    } else {
      _showMessage(
        state.errorMessage ?? 'Unable to apply for this job.',
        isError: true,
      );
    }
    ref.read(jobViewModelProvider.notifier).clearFeedback();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB42318)
              : const Color(0xFF237A45),
        ),
      );
  }

  List<String> get _photoUrls {
    return job.photos
        .map((photo) => photo.trim())
        .where((photo) => photo.isNotEmpty)
        .map(_resolvePhotoUrl)
        .toList();
  }

  String _resolvePhotoUrl(String photo) {
    final uri = Uri.tryParse(photo);
    if (uri != null && uri.hasScheme) return photo;

    final baseUri = Uri.parse(ApiEndpoints.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.authority}';
    final cleanPhoto = photo.replaceAll('\\', '/');

    if (cleanPhoto.startsWith('/api/')) return '$origin$cleanPhoto';
    if (cleanPhoto.startsWith('/')) return '$origin$cleanPhoto';
    if (cleanPhoto.startsWith('uploads/')) return '$origin/$cleanPhoto';
    return '$origin/uploads/$cleanPhoto';
  }

  String _formatPay(num pay) {
    return pay == pay.roundToDouble()
        ? pay.toInt().toString()
        : pay.toStringAsFixed(2);
  }

  String _formatJobDate(String value) {
    final date = DateTime.tryParse(value.trim());
    if (date == null) return value.trim();
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _displayValue(String value) {
    return value.replaceAll('[', '').replaceAll(']', '').trim();
  }

  String _capitalize(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) return cleanValue;
    return '${cleanValue[0].toUpperCase()}${cleanValue.substring(1)}';
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  final String status;

  const _ApplicationStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'accepted' => const Color(0xFF237A45),
      'rejected' => const Color(0xFFB42318),
      'completed' => const Color(0xFF435D95),
      _ => const Color(0xFFE09A22),
    };
    final icon = switch (normalized) {
      'accepted' => Icons.check_circle_outline_rounded,
      'rejected' => Icons.cancel_outlined,
      'completed' => Icons.task_alt_rounded,
      _ => Icons.schedule_rounded,
    };

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Application status: ${_label(normalized)}',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _label(String value) {
    if (value.isEmpty) return 'Pending';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _JobPhotoGallery extends StatefulWidget {
  final List<String> photoUrls;

  const _JobPhotoGallery({required this.photoUrls});

  @override
  State<_JobPhotoGallery> createState() => _JobPhotoGalleryState();
}

class _JobPhotoGalleryState extends State<_JobPhotoGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photoUrls = widget.photoUrls;

    if (photoUrls.isEmpty) {
      return const _JobImage(photoUrl: null);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: photoUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return _JobNetworkImage(photoUrl: photoUrls[index]);
              },
            ),
            if (photoUrls.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${photoUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JobImage extends StatelessWidget {
  final String? photoUrl;

  const _JobImage({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: photoUrl == null
            ? const _ImagePlaceholder()
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, _) {
                  if (kDebugMode) {
                    debugPrint('Could not load job photo: $photoUrl ($error)');
                  }
                  return const _ImagePlaceholder();
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(
                    color: Color(0xFFE9EDF5),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
      ),
    );
  }
}

class _JobNetworkImage extends StatelessWidget {
  final String photoUrl;

  const _JobNetworkImage({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, error, _) {
        if (kDebugMode) {
          debugPrint('Could not load job photo: $photoUrl ($error)');
        }
        return const _ImagePlaceholder();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFFE9EDF5),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9EDF5),
      child: Center(
        child: Icon(
          Icons.work_outline_rounded,
          color: Color(0xFF667899),
          size: 58,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF52617D)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF3A3D44),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF17191D),
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
