import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/datasources/job_datasource.dart';
import 'package:hireasy_mobile/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:hireasy_mobile/features/jobs/data/models/job_api_model.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final jobRepositoryProvider = Provider<IJobRepository>((ref) {
  return JobRepository(remoteDataSource: ref.read(jobRemoteDataSourceProvider));
});

class JobRepository implements IJobRepository {
  final IJobRemoteDataSource remoteDataSource;

  const JobRepository({required this.remoteDataSource});

  @override
  Future<List<JobEntity>> getJobs() async {
    final response = await remoteDataSource.getJobs();
    return response.jobs.map((job) => job.toEntity()).toList();
  }

  @override
  Future<List<JobEntity>> getMyJobs() async {
    final response = await remoteDataSource.getMyJobs();
    return response.jobs.map((job) => job.toEntity()).toList();
  }

  @override
  Future<List<JobApplicationEntity>> getJobApplicants(String jobId) async {
    final response = await remoteDataSource.getJobApplicants(jobId);
    return response.applicants;
  }

  @override
  Future<String> applyForJob(String jobId) async {
    final response = await remoteDataSource.applyForJob(jobId);
    return response.message;
  }

  @override
  Future<JobEntity> createJob(JobEntity job) async {
    final model = JobApiModel.fromEntity(job);
    final response = await remoteDataSource.createJob(model);
    return response.job.toEntity();
  }

  @override
  Future<JobEntity> updateJob(String jobId, JobEntity job) async {
    final model = JobApiModel.fromEntity(job);
    final response = await remoteDataSource.updateJob(jobId, model);
    return response.job.toEntity();
  }

  @override
  Future<String> deleteJob(String jobId) async {
    final response = await remoteDataSource.deleteJob(jobId);
    return response.message;
  }
}
