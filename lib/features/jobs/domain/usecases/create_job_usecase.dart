import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/features/jobs/data/repositories/job_repository.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_photo_upload.dart';
import 'package:hireasy_mobile/features/jobs/domain/repositories/job_repository.dart';

class CreateJobParams {
  final String roleType;
  final int numberOfWorkers;
  final num pay;
  final String shift;
  final String location;
  final String jobDate;
  final List<String> photos;
  final List<JobPhotoUpload> photoUploads;
  final String description;

  const CreateJobParams({
    required this.roleType,
    required this.numberOfWorkers,
    required this.pay,
    required this.shift,
    required this.location,
    required this.jobDate,
    this.photos = const [],
    this.photoUploads = const [],
    required this.description,
  });
}

final createJobUsecaseProvider = Provider<CreateJobUsecase>((ref) {
  return CreateJobUsecase(jobRepository: ref.read(jobRepositoryProvider));
});

class CreateJobUsecase {
  final IJobRepository jobRepository;

  const CreateJobUsecase({required this.jobRepository});

  Future<JobEntity> call(CreateJobParams params) {
    return jobRepository.createJob(
      JobEntity(
        roleType: params.roleType.trim(),
        numberOfWorkers: params.numberOfWorkers,
        pay: params.pay,
        shift: params.shift,
        location: params.location.trim(),
        jobDate: params.jobDate.trim(),
        photos: params.photos,
        description: params.description.trim(),
      ),
      photoUploads: params.photoUploads,
    );
  }
}
