import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';

class AppliedJobsResult {
  final List<JobEntity> jobs;
  final Map<String, String> applicationStatuses;
  final AppliedJobsPagination? pagination;

  const AppliedJobsResult({
    required this.jobs,
    required this.applicationStatuses,
    this.pagination,
  });
}

class AppliedJobsPagination {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;
  final bool? hasNextPage;
  final bool? hasPreviousPage;

  const AppliedJobsPagination({
    this.page,
    this.limit,
    this.total,
    this.totalPages,
    this.hasNextPage,
    this.hasPreviousPage,
  });
}
