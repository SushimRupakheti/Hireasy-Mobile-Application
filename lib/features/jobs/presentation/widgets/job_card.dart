import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String location;
  final String duration;
  final String description;
  final String pay;
  final VoidCallback? onTap;
  final String? status;

  const JobCard({
    super.key,
    required this.title,
    required this.location,
    required this.duration,
    required this.description,
    required this.pay,
    this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 15, 16, 15),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9DDE5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _cleanDisplayValue(title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF15171C),
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _cleanDisplayValue(pay),
                    style: const TextStyle(
                      color: Color(0xFFFF3347),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '/hr',
                      style: TextStyle(color: Color(0xFF8E929B), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: _cleanDisplayValue(location),
              ),
              const SizedBox(height: 7),
              _InfoRow(
                icon: Icons.schedule_rounded,
                text: _cleanDisplayValue(duration),
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        _cleanDisplayValue(description),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF92959D),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 10),
                      _StatusBadge(status: status!),
                    ],
                  ],
                ),
              ] else if (status != null) ...[
                const SizedBox(height: 11),
                Align(
                  alignment: Alignment.centerRight,
                  child: _StatusBadge(status: status!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = _cleanDisplayValue(status).toLowerCase();
    final color = switch (normalized) {
      'accepted' => const Color(0xFF38C95B),
      'open' => const Color(0xFF38C95B),
      'opened' => const Color(0xFF38C95B),
      'verified' => const Color(0xFF38C95B),
      'completed' => const Color(0xFF435D95),
      'pending' => const Color(0xFFD5D91C),
      'closed' => const Color(0xFF8E929B),
      'rejected' => const Color(0xFFE90012),
      _ => const Color(0xFFD5D91C),
    };
    final icon = switch (normalized) {
      'accepted' => Icons.check_rounded,
      'open' => Icons.check_rounded,
      'opened' => Icons.check_rounded,
      'verified' => Icons.verified_rounded,
      'completed' => Icons.task_alt_rounded,
      'closed' => Icons.lock_outline_rounded,
      'rejected' => Icons.close_rounded,
      _ => Icons.schedule_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _label(normalized),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _label(String value) {
    if (value.isEmpty || value == 'pending') return 'Pending';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

String _cleanDisplayValue(String value) {
  return value.replaceAll('[', '').replaceAll(']', '').trim();
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF25272C)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF2C2E33), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
