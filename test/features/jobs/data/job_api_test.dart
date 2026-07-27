import 'package:flutter_test/flutter_test.dart';
import 'package:hireasy_mobile/features/jobs/data/job_api.dart';

void main() {
  group('GetAppliedJobsApiResponse', () {
    test('parses submitted jobs and their supported application statuses', () {
      final response = GetAppliedJobsApiResponse.fromJson({
        'applications': [
          for (final status in [
            'pending',
            'accepted',
            'rejected',
            'completed',
          ])
            {
              'status': status,
              'job': {
                '_id': 'job-$status',
                'roleType': 'Worker',
                'numberOfWorkers': 1,
                'pay': 1000,
                'shift': 'Day',
                'location': 'Kathmandu',
                'description': 'Test job',
              },
            },
        ],
      });

      expect(response.jobs, hasLength(4));
      expect(response.applicationStatuses, {
        'job-pending': 'pending',
        'job-accepted': 'accepted',
        'job-rejected': 'rejected',
        'job-completed': 'completed',
      });
    });

    test('normalizes API aliases and unknown statuses', () {
      final approved = GetAppliedJobsApiResponse.fromJson({
        'applications': [
          {
            'applicationStatus': 'approved',
            'job': {
              '_id': 'approved-job',
              'roleType': 'Worker',
              'numberOfWorkers': 1,
              'pay': 1000,
              'shift': 'Day',
              'location': 'Kathmandu',
              'description': 'Test job',
            },
          },
          {
            'applicationStatus': 'unexpected',
            'job': {
              '_id': 'unknown-job',
              'roleType': 'Worker',
              'numberOfWorkers': 1,
              'pay': 1000,
              'shift': 'Day',
              'location': 'Kathmandu',
              'description': 'Test job',
            },
          },
        ],
      });

      expect(approved.applicationStatuses['approved-job'], 'accepted');
      expect(approved.applicationStatuses['unknown-job'], 'pending');
    });
  });
}
