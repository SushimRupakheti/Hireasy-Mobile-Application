import 'package:hireasy_mobile/features/jobs/data/job_api.dart';
import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_photo_upload.dart';

abstract interface class IJobRemoteDataSource {
  Future<GetJobsApiResponse> getJobs();

  Future<GetJobsApiResponse> getMyJobs();

  Future<GetAppliedJobsApiResponse> getMyApplications();

  Future<GetJobApplicantsApiResponse> getJobApplicants(String jobId);

  Future<ApplyJobApiResponse> applyForJob(String jobId);

  Future<CreateJobApiResponse> createJob(
    JobApiModel job, {
    List<JobPhotoUpload> photoUploads = const [],
  });

  Future<UpdateJobApiResponse> updateJob(
    String jobId,
    JobApiModel job, {
    List<JobPhotoUpload> photoUploads = const [],
  });

  Future<DeleteJobApiResponse> deleteJob(String jobId);
}
