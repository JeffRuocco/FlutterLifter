import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/theme_extensions.dart';

/// Screen for browsing and managing the program library.
///
/// Features two tabs:
/// - My Programs: Custom programs and used default programs
/// - Discover: All default programs and community programs
class ProgramLibraryScreen extends ConsumerStatefulWidget {
  const ProgramLibraryScreen({super.key});

  @override
  ConsumerState<ProgramLibraryScreen> createState() =>
      _ProgramLibraryScreenState();
}

class _ProgramLibraryScreenState extends ConsumerState<ProgramLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Library'),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: context.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Programs'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // My Programs Tab
          _buildMyProgramsTab(),
          // Discover Tab
          _buildDiscoverTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create program screen
        },
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: context.onPrimary,
        ),
      ),
    );
  }

  Widget _buildMyProgramsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedFolder01,
              size: 64,
              color: context.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'My Programs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your custom programs and programs you\'ve used will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 64,
              color: context.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Discover Programs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Browse default programs and community-shared programs.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
