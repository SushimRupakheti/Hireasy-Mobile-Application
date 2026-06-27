class JobApplicationEntity {
  final String workerId;
  final String status;

  const JobApplicationEntity({required this.workerId, this.status = 'pending'});
}

class JobEntity {
  final String? id;
  final String? companyId;
  final String roleType;
  final int numberOfWorkers;
  final num pay;
  final String shift;
  final String location;
  final String jobDate;
  final List<String> photos;
  final String description;
  final String status;
  final List<String> appliedWorkers;
  final List<JobApplicationEntity> applications;

  const JobEntity({
    this.id,
    this.companyId,
    required this.roleType,
    required this.numberOfWorkers,
    required this.pay,
    required this.shift,
    required this.location,
    this.jobDate = '',
    this.photos = const [],
    required this.description,
    this.status = 'open',
    this.appliedWorkers = const [],
    this.applications = const [],
  });
}
