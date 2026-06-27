import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final getJobApplicantsUsecaseProvider = Provider<GetJobApplicantsUsecase>((
  ref,
) {
  return GetJobApplicantsUsecase(
    jobRepository: ref.read(jobRepositoryProvider),
  );
});

class GetJobApplicantsUsecase {
  final IJobRepository _jobRepository;

  const GetJobApplicantsUsecase({required IJobRepository jobRepository})
    : _jobRepository = jobRepository;

  Future<List<JobApplicationEntity>> call(String jobId) {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) return Future.value(const []);
    return _jobRepository.getJobApplicants(cleanJobId);
  }
}
