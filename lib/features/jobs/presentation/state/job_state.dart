import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

class JobState {
  final bool isLoading;
  final bool isFetchingJobs;
  final bool isFetchingApplications;
  final bool isApplying;
  final String? applyingJobId;
  final Set<String> appliedJobIds;
  final Map<String, String> applicationStatuses;
  final List<JobEntity> jobs;
  final JobEntity? createdJob;
  final String? successMessage;
  final String? errorMessage;

  const JobState({
    this.isLoading = false,
    this.isFetchingJobs = false,
    this.isFetchingApplications = false,
    this.isApplying = false,
    this.applyingJobId,
    this.appliedJobIds = const {},
    this.applicationStatuses = const {},
    this.jobs = const [],
    this.createdJob,
    this.successMessage,
    this.errorMessage,
  });

  JobState copyWith({
    bool? isLoading,
    bool? isFetchingJobs,
    bool? isFetchingApplications,
    bool? isApplying,
    String? applyingJobId,
    Set<String>? appliedJobIds,
    Map<String, String>? applicationStatuses,
    List<JobEntity>? jobs,
    JobEntity? createdJob,
    String? successMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearApplyingJobId = false,
  }) {
    return JobState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingJobs: isFetchingJobs ?? this.isFetchingJobs,
      isFetchingApplications:
          isFetchingApplications ?? this.isFetchingApplications,
      isApplying: isApplying ?? this.isApplying,
      applyingJobId: clearApplyingJobId
          ? null
          : applyingJobId ?? this.applyingJobId,
      appliedJobIds: appliedJobIds ?? this.appliedJobIds,
      applicationStatuses: applicationStatuses ?? this.applicationStatuses,
      jobs: jobs ?? this.jobs,
      createdJob: createdJob ?? this.createdJob,
      successMessage: clearFeedback
          ? null
          : successMessage ?? this.successMessage,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }
}
