import 'package:flutter/material.dart';

import '../../widgets/worker_category_card.dart';

class CompanyHomeScreen extends StatelessWidget {
  final ValueChanged<String?>? onPostJobRequested;

  const CompanyHomeScreen({super.key, this.onPostJobRequested});

  static const _primaryBlue = Color(0xFF3F7CF4);
  static const _navyBlue = Color(0xFF18346F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: Column(
        children: [
          _buildHeader(context),
          const _SectionTitle(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                WorkerCategoryCard(
                  title: 'Warehouse Associates',
                  imagePath: 'assets/images/warehouse.jpg',
                  onTap: () =>
                      _openPostJobScreen(context, 'Warehouse Associates'),
                ),
                WorkerCategoryCard(
                  title: 'Factory Workers',
                  imagePath: 'assets/images/factory.jpg',
                  onTap: () => _openPostJobScreen(context, 'Factory Workers'),
                ),
                WorkerCategoryCard(
                  title: 'Labors',
                  imagePath: 'assets/images/labors.jpg',
                  onTap: () => _openPostJobScreen(context, 'Labors'),
                ),
                WorkerCategoryCard(
                  title: 'Handyman',
                  imagePath: 'assets/images/handyman.jpg',
                  onTap: () => _openPostJobScreen(context, 'Handyman'),
                ),
                WorkerCategoryCard(
                  title: 'Painters',
                  imagePath: 'assets/images/painter.jpg',
                  onTap: () => _openPostJobScreen(context, 'Painters'),
                ),
                WorkerCategoryCard(
                  title: 'Cleaners',
                  imagePath: 'assets/images/cleaner.jpg',
                  onTap: () => _openPostJobScreen(context, 'Cleaners'),
                ),
                WorkerCategoryCard(
                  title: 'Waiters',
                  imagePath: 'assets/images/waiter.jpg',
                  onTap: () => _openPostJobScreen(context, 'Waiters'),
                ),
                WorkerCategoryCard(
                  title: 'Movers',
                  imagePath: 'assets/images/mover.jpg',
                  onTap: () => _openPostJobScreen(context, 'Movers'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPostJobScreen(BuildContext context, String roleType) {
    onPostJobRequested?.call(roleType);
  }

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                backgroundImage: AssetImage('assets/images/client.png'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daraz Nepal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _MessageButton(onPressed: () {}),
            ],
          ),
          const SizedBox(height: 34),
          TextField(
            style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
            decoration: InputDecoration(
              hintText: 'Search ...',
              hintStyle: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 15,
              ),
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.black,
                size: 28,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatWidget(title: 'Stats 1'),
              _StatWidget(title: 'Stats 2'),
              _StatWidget(title: 'Stats 3'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MessageButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF161616),
                size: 25,
              ),
              Positioned(
                right: 16,
                top: 16,
                child: CircleAvatar(
                  radius: 3.5,
                  backgroundColor: Color(0xFFFF001D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String title;

  const _StatWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.bar_chart_rounded,
            color: Color(0xFF121212),
            size: 24,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 34,
      alignment: Alignment.center,
      color: Colors.white,
      child: const Text(
        'Search for workers',
        style: TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
