import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final getJobsUsecaseProvider = Provider<GetJobsUsecase>((ref) {
  return GetJobsUsecase(ref.read(jobRepositoryProvider));
});

class GetJobsUsecase {
  final IJobRepository _jobRepository;

  const GetJobsUsecase(this._jobRepository);

  Future<List<JobEntity>> call() => _jobRepository.getJobs();
}
