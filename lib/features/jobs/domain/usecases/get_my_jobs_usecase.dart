import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final getMyJobsUsecaseProvider = Provider<GetMyJobsUsecase>((ref) {
  return GetMyJobsUsecase(ref.read(jobRepositoryProvider));
});

class GetMyJobsUsecase {
  final IJobRepository _jobRepository;

  const GetMyJobsUsecase(this._jobRepository);

  Future<List<JobEntity>> call() => _jobRepository.getMyJobs();
}
