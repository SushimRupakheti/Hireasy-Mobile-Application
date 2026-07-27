import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/get_current_user.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/applied_jobs_result.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/apply_for_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/create_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/delete_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/get_jobs_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/get_my_applications_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/get_my_jobs_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/update_job_usecase.dart';
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
      final myApplications = await _getMyApplicationsForJobList();
      final userId = ref.read(tokenServiceProvider).userId;
      final serverAppliedJobIds = userId == null || userId.isEmpty
          ? <String>{}
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
      final serverApplicationStatuses = userId == null || userId.isEmpty
          ? <String, String>{}
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
      final appliedJobIds = {
        ...state.appliedJobIds,
        ...state.applicationStatuses.keys,
        ...serverAppliedJobIds,
        ...serverApplicationStatuses.keys,
        ...?myApplications?.jobs.map((job) => job.id).whereType<String>(),
        ...?myApplications?.applicationStatuses.keys,
      };
      final applicationStatuses = {
        ...state.applicationStatuses,
        ...serverApplicationStatuses,
        ...?myApplications?.applicationStatuses,
        for (final jobId in appliedJobIds)
          if (!state.applicationStatuses.containsKey(jobId) &&
              !serverApplicationStatuses.containsKey(jobId) &&
              !(myApplications?.applicationStatuses.containsKey(jobId) ??
                  false))
            jobId: 'pending',
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

  Future<AppliedJobsResult?> _getMyApplicationsForJobList() async {
    try {
      return await ref.read(getMyApplicationsUsecaseProvider).call();
    } catch (_) {
      // The public jobs list should still load if application status syncing
      // fails. Existing in-memory application state remains available.
      return null;
    }
  }

  Future<void> getMyJobs() async {
    state = state.copyWith(isFetchingJobs: true, clearFeedback: true);

    try {
      final jobs = await ref.read(getMyJobsUsecaseProvider).call();
      state = state.copyWith(
        isFetchingJobs: false,
        jobs: jobs,
        clearFeedback: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isFetchingJobs: false,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to load your jobs.',
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isFetchingJobs: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> getMyApplications() async {
    state = state.copyWith(
      isFetchingApplications: true,
      clearFeedback: true,
    );

    try {
      final result = await ref.read(getMyApplicationsUsecaseProvider).call();
      final appliedJobIds = result.jobs
          .map((job) => job.id)
          .whereType<String>()
          .toSet();
      state = state.copyWith(
        isFetchingApplications: false,
        jobs: result.jobs,
        appliedJobIds: {
          ...appliedJobIds,
          ...result.applicationStatuses.keys,
        },
        applicationStatuses: {
          ...result.applicationStatuses,
          for (final jobId in appliedJobIds)
            if (!result.applicationStatuses.containsKey(jobId))
              jobId: 'pending',
        },
        clearFeedback: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isFetchingApplications: false,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to load your applications.',
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isFetchingApplications: false,
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

  Future<JobEntity?> updateJob(String jobId, UpdateJobParams params) async {
    if (!ref.read(tokenServiceProvider).isVerified) {
      state = state.copyWith(
        errorMessage:
            'Account is pending. Only verified companies can edit jobs.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, clearFeedback: true);

    try {
      final updatedJob = await ref
          .read(updateJobUsecaseProvider)
          .call(jobId, params);
      state = state.copyWith(
        isLoading: false,
        jobs: state.jobs
            .map((job) => job.id == jobId ? updatedJob : job)
            .toList(),
        successMessage: 'Job updated successfully',
      );
      return updatedJob;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to update the job.',
        ),
      );
      return null;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is FormatException
            ? error.message
            : 'Unable to update the job.',
      );
      return null;
    }
  }

  Future<bool> deleteJob(String jobId) async {
    if (!ref.read(tokenServiceProvider).isVerified) {
      state = state.copyWith(
        errorMessage:
            'Account is pending. Only verified companies can delete jobs.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearFeedback: true);

    try {
      final message = await ref.read(deleteJobUsecaseProvider).call(jobId);
      state = state.copyWith(
        isLoading: false,
        jobs: state.jobs.where((job) => job.id != jobId).toList(),
        successMessage: message,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: apiErrorMessage(
          error,
          fallback: 'Unable to delete the job.',
        ),
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error is FormatException
            ? error.message
            : 'Unable to delete the job.',
      );
      return false;
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearFeedback: true);
  }
}
