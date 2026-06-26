import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

abstract interface class IJobRepository {
  Future<List<JobEntity>> getJobs();

  Future<String> applyForJob(String jobId);

  Future<JobEntity> createJob(JobEntity job);
}
