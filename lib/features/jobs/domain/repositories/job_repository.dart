import 'package:hireasy_mobile/features/jobs/domain/entities/applied_jobs_result.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_photo_upload.dart';

abstract interface class IJobRepository {
  Future<List<JobEntity>> getJobs();

  Future<List<JobEntity>> getMyJobs();

  Future<AppliedJobsResult> getMyApplications();

  Future<List<JobApplicationEntity>> getJobApplicants(String jobId);

  Future<String> applyForJob(String jobId);

  Future<JobEntity> createJob(
    JobEntity job, {
    List<JobPhotoUpload> photoUploads = const [],
  });

  Future<JobEntity> updateJob(
    String jobId,
    JobEntity job, {
    List<JobPhotoUpload> photoUploads = const [],
  });

  Future<String> deleteJob(String jobId);
}
