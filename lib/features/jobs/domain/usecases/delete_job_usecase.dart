import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

final deleteJobUsecaseProvider = Provider<DeleteJobUsecase>((ref) {
  return DeleteJobUsecase(jobRepository: ref.read(jobRepositoryProvider));
});

class DeleteJobUsecase {
  final IJobRepository jobRepository;

  const DeleteJobUsecase({required this.jobRepository});

  Future<String> call(String jobId) {
    final cleanJobId = jobId.trim();
    if (cleanJobId.isEmpty) {
      throw const FormatException('This job does not have a valid ID.');
    }
    return jobRepository.deleteJob(cleanJobId);
  }
}
