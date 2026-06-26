import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final applyForJobUsecaseProvider = Provider<ApplyForJobUsecase>((ref) {
  return ApplyForJobUsecase(ref.read(jobRepositoryProvider));
});

class ApplyForJobUsecase {
  final IJobRepository _jobRepository;

  const ApplyForJobUsecase(this._jobRepository);

  Future<String> call(String jobId) {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw const FormatException('This job does not have a valid ID.');
    }
    return _jobRepository.applyForJob(cleanJobId);
  }
}
