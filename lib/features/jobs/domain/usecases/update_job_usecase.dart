import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

class UpdateJobParams {
  final String roleType;
  final int numberOfWorkers;
  final num pay;
  final String shift;
  final String location;
  final String jobDate;
  final List<String> photos;
  final String description;

  const UpdateJobParams({
    required this.roleType,
    required this.numberOfWorkers,
    required this.pay,
    required this.shift,
    required this.location,
    required this.jobDate,
    this.photos = const [],
    required this.description,
  });
}

final updateJobUsecaseProvider = Provider<UpdateJobUsecase>((ref) {
  return UpdateJobUsecase(jobRepository: ref.read(jobRepositoryProvider));
});

class UpdateJobUsecase {
  final IJobRepository jobRepository;

  const UpdateJobUsecase({required this.jobRepository});

  Future<JobEntity> call(String jobId, UpdateJobParams params) {
    return jobRepository.updateJob(
      jobId,
      JobEntity(
        roleType: params.roleType.trim(),
        numberOfWorkers: params.numberOfWorkers,
        pay: params.pay,
        shift: params.shift.trim(),
        location: params.location.trim(),
        jobDate: params.jobDate.trim(),
        photos: params.photos,
        description: params.description.trim(),
      ),
    );
  }
}
