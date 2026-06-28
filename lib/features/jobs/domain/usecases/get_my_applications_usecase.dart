import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/applied_jobs_result.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final getMyApplicationsUsecaseProvider = Provider<GetMyApplicationsUsecase>((
  ref,
) {
  return GetMyApplicationsUsecase(
    jobRepository: ref.read(jobRepositoryProvider),
  );
});

class GetMyApplicationsUsecase {
  final IJobRepository jobRepository;

  const GetMyApplicationsUsecase({required this.jobRepository});

  Future<AppliedJobsResult> call() {
    return jobRepository.getMyApplications();
  }
}
