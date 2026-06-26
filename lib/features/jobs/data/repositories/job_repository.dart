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
  final IJobRemoteDataSource _remoteDataSource;

  const JobRepository({required IJobRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<List<JobEntity>> getJobs() async {
    final response = await _remoteDataSource.getJobs();
    return response.jobs.map((job) => job.toEntity()).toList();
  }

  @override
  Future<String> applyForJob(String jobId) async {
    final response = await _remoteDataSource.applyForJob(jobId);
    return response.message;
  }

  @override
  Future<JobEntity> createJob(JobEntity job) async {
    final model = JobApiModel.fromEntity(job);
    final response = await _remoteDataSource.createJob(model);
    return response.job.toEntity();
  }
}
