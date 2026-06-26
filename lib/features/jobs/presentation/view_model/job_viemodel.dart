import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/get_current_user.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/apply_for_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/create_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/get_jobs_usecase.dart';
import 'package:hireasy_mobile/features/jobs/presentation/state/job_state.dart';

final jobViewModelProvider = NotifierProvider<JobViewModel, JobState>(
  JobViewModel.new,
);

class JobViewModel extends Notifier<JobState> {
  @override
  JobState build() => const JobState();

  Future<bool> applyForJob(String jobId) async {
    if (!ref.read(tokenServiceProvider).isVerified) {
      state = JobState(
        jobs: state.jobs,
        appliedJobIds: state.appliedJobIds,
        applicationStatuses: state.applicationStatuses,
        errorMessage:
            'Account is pending. Only verified accounts can apply for jobs.',
      );
      return false;
    }

    try {
      final user = await ref.read(getCurrentUserUsecaseProvider).call();
      final hasResume =
          user?.document?.documentType.trim().toLowerCase() == 'resume';
      if (!hasResume) {
        state = JobState(
          jobs: state.jobs,
          appliedJobIds: state.appliedJobIds,
          applicationStatuses: state.applicationStatuses,
          errorMessage:
              'Upload your resume from the Profile screen before applying.',
        );
        return false;
      }
    } on DioException catch (error) {
      state = JobState(
        jobs: state.jobs,
        appliedJobIds: state.appliedJobIds,
        applicationStatuses: state.applicationStatuses,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to verify your resume.',
        ),
      );
      return false;
    }

    state = state.copyWith(
      isApplying: true,
      applyingJobId: jobId,
      clearFeedback: true,
    );

    try {
      final message = await ref.read(applyForJobUsecaseProvider).call(jobId);
      state = state.copyWith(
        isApplying: false,
        appliedJobIds: {...state.appliedJobIds, jobId},
        applicationStatuses: {...state.applicationStatuses, jobId: 'pending'},
        successMessage: message,
        clearApplyingJobId: true,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isApplying: false,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to apply for this job.',
        ),
        clearApplyingJobId: true,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isApplying: false,
        errorMessage: error is FormatException
            ? error.message
            : 'Unable to apply for this job.',
        clearApplyingJobId: true,
      );
      return false;
    }
  }

  Future<void> getJobs() async {
    state = state.copyWith(isFetchingJobs: true, clearFeedback: true);

    try {
      final jobs = await ref.read(getJobsUsecaseProvider).call();
      final userId = ref.read(tokenServiceProvider).userId;
      final appliedJobIds = userId == null || userId.isEmpty
          ? state.appliedJobIds
          : jobs
                .where(
                  (job) =>
                      job.appliedWorkers.contains(userId) ||
                      job.applications.any(
                        (application) => application.workerId == userId,
                      ),
                )
                .map((job) => job.id)
                .whereType<String>()
                .toSet();
      final applicationStatuses = userId == null || userId.isEmpty
          ? state.applicationStatuses
          : <String, String>{
              for (final job in jobs)
                if (job.id != null)
                  for (final application in job.applications)
                    if (application.workerId == userId)
                      job.id!: application.status,
              for (final job in jobs)
                if (job.id != null &&
                    job.appliedWorkers.contains(userId) &&
                    !job.applications.any(
                      (application) => application.workerId == userId,
                    ))
                  job.id!: 'pending',
            };
      state = state.copyWith(
        isFetchingJobs: false,
        jobs: jobs,
        appliedJobIds: appliedJobIds,
        applicationStatuses: applicationStatuses,
        clearFeedback: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isFetchingJobs: false,
        errorMessage: apiErrorMessage(error, fallback: 'Unable to load jobs.'),
      );
    } catch (error) {
      state = state.copyWith(
        isFetchingJobs: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> createJob(CreateJobParams params) async {
    if (!ref.read(tokenServiceProvider).isVerified) {
      state = JobState(
        jobs: state.jobs,
        appliedJobIds: state.appliedJobIds,
        applicationStatuses: state.applicationStatuses,
        errorMessage:
            'Account is pending. Only verified accounts can post jobs.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearFeedback: true);

    try {
      final job = await ref.read(createJobUsecaseProvider).call(params);
      state = JobState(
        jobs: state.jobs,
        appliedJobIds: state.appliedJobIds,
        applicationStatuses: state.applicationStatuses,
        createdJob: job,
        successMessage: 'Job posted successfully',
      );
      return true;
    } on DioException catch (error) {
      state = JobState(
        jobs: state.jobs,
        appliedJobIds: state.appliedJobIds,
        applicationStatuses: state.applicationStatuses,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to post the job.',
        ),
      );
      return false;
    } catch (error) {
      state = JobState(
        jobs: state.jobs,
        appliedJobIds: state.appliedJobIds,
        applicationStatuses: state.applicationStatuses,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearFeedback: true);
  }
}
