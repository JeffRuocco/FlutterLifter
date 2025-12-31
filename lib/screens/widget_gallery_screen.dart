import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/theme_utils.dart';
import '../core/theme/theme_provider.dart';
import '../widgets/animations/animate_on_load.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_button.dart';
import '../widgets/progress_ring.dart';

/// Widget Gallery Screen for showcasing all UI components
///
/// This screen serves as a living documentation of the design system.
/// When adding new components, update this gallery to showcase them.
class WidgetGalleryScreen extends ConsumerStatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  ConsumerState<WidgetGalleryScreen> createState() =>
      _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends ConsumerState<WidgetGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_GalleryTab> _tabs = const [
    _GalleryTab('Colors', HugeIcons.strokeRoundedPaintBrush01),
    _GalleryTab('Typography', HugeIcons.strokeRoundedTextFont),
    _GalleryTab('Buttons', HugeIcons.strokeRoundedCursor01),
    _GalleryTab('Inputs', HugeIcons.strokeRoundedEdit01),
    _GalleryTab('Cards', HugeIcons.strokeRoundedDashboardSquare01),
    _GalleryTab('Icons', HugeIcons.strokeRoundedImage01),
    _GalleryTab('Spacing', HugeIcons.strokeRoundedLayoutGrid),
    _GalleryTab('Animations', HugeIcons.strokeRoundedMotion01),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        title: const Text('Widget Gallery'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((tab) {
            return Tab(
              icon: HugeIcon(
                icon: tab.icon,
                color: context.onSurface,
                size: 20,
              ),
              text: tab.label,
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ColorsGallery(),
          _TypographyGallery(),
          _ButtonsGallery(),
          _InputsGallery(),
          _CardsGallery(),
          _IconsGallery(),
          _SpacingGallery(),
          _AnimationsGallery(),
        ],
      ),
    );
  }
}

class _GalleryTab {
  final String label;
  final IconData icon;

  const _GalleryTab(this.label, this.icon);
}

// ============================================
// Colors Gallery
// ============================================

class _ColorsGallery extends StatelessWidget {
  const _ColorsGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Primary Colors'),
        _ColorRow('Primary', context.primaryColor),
        _ColorRow('On Primary', context.onPrimary),
        _ColorRow('Primary Container', context.primaryContainer),
        VSpace.lg(),
        _SectionHeader('Secondary Colors'),
        _ColorRow('Secondary', context.secondaryColor),
        _ColorRow('On Secondary', context.onSecondary),
        VSpace.lg(),
        _SectionHeader('Surface Colors'),
        _ColorRow('Surface', context.surfaceColor),
        _ColorRow('Surface Variant', context.surfaceVariant),
        _ColorRow('On Surface', context.onSurface),
        _ColorRow('On Surface Variant', context.onSurfaceVariant),
        VSpace.lg(),
        _SectionHeader('Status Colors'),
        _ColorRow('Success', context.successColor),
        _ColorRow('Error', context.errorColor),
        _ColorRow('Warning', context.warningColor),
        _ColorRow('Info', context.infoColor),
        VSpace.lg(),
        _SectionHeader('Brand Colors (Static)'),
        _ColorRow('Primary Brand', AppColors.primary),
        _ColorRow('Secondary Brand', AppColors.secondary),
        _ColorRow('Cardio', AppColors.cardio),
        _ColorRow('Strength', AppColors.strength),
        _ColorRow('Flexibility', AppColors.flexibility),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorRow(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              border: Border.all(color: context.outlineColor),
            ),
          ),
          HSpace.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.titleSmall),
                Text(
                  '#${color.toHex().toUpperCase()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Typography Gallery
// ============================================

class _TypographyGallery extends StatelessWidget {
  const _TypographyGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Display Styles'),
        _TypographyItem('Display Large', AppTextStyles.displayLarge),
        _TypographyItem('Display Medium', AppTextStyles.displayMedium),
        _TypographyItem('Display Small', AppTextStyles.displaySmall),
        VSpace.lg(),
        _SectionHeader('Headline Styles'),
        _TypographyItem('Headline Large', AppTextStyles.headlineLarge),
        _TypographyItem('Headline Medium', AppTextStyles.headlineMedium),
        _TypographyItem('Headline Small', AppTextStyles.headlineSmall),
        VSpace.lg(),
        _SectionHeader('Title Styles'),
        _TypographyItem('Title Large', AppTextStyles.titleLarge),
        _TypographyItem('Title Medium', AppTextStyles.titleMedium),
        _TypographyItem('Title Small', AppTextStyles.titleSmall),
        VSpace.lg(),
        _SectionHeader('Body Styles'),
        _TypographyItem('Body Large', AppTextStyles.bodyLarge),
        _TypographyItem('Body Medium', AppTextStyles.bodyMedium),
        _TypographyItem('Body Small', AppTextStyles.bodySmall),
        VSpace.lg(),
        _SectionHeader('Label Styles'),
        _TypographyItem('Label Large', AppTextStyles.labelLarge),
        _TypographyItem('Label Medium', AppTextStyles.labelMedium),
        _TypographyItem('Label Small', AppTextStyles.labelSmall),
        VSpace.lg(),
        _SectionHeader('Custom Fitness Styles'),
        _TypographyItem('Exercise Name', AppTextStyles.exerciseName),
        _TypographyItem('Stat Number', AppTextStyles.statNumber),
        _TypographyItem('Stat Label', AppTextStyles.statLabel),
      ],
    );
  }
}

class _TypographyItem extends StatelessWidget {
  final String name;
  final TextStyle? style;

  const _TypographyItem(this.name, this.style);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.labelSmall.copyWith(
              color: context.textSecondary,
            ),
          ),
          Text(
            'The quick brown fox',
            style: style,
          ),
        ],
      ),
    );
  }
}

// ============================================
// Buttons Gallery
// ============================================

class _ButtonsGallery extends StatelessWidget {
  const _ButtonsGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Elevated Buttons'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(text: 'Default', onPressed: () {}),
            AppButton(text: 'Loading', onPressed: () {}, isLoading: true),
            const AppButton(text: 'Disabled', onPressed: null),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Outlined Buttons'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
                text: 'Default',
                onPressed: () {},
                type: AppButtonType.outlined),
            AppButton(
                text: 'Loading',
                onPressed: () {},
                isLoading: true,
                type: AppButtonType.outlined),
            const AppButton(
                text: 'Disabled',
                onPressed: null,
                type: AppButtonType.outlined),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Text Buttons'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
                text: 'Default', onPressed: () {}, type: AppButtonType.text),
            const AppButton(
                text: 'Disabled', onPressed: null, type: AppButtonType.text),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Icon Buttons'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.primaryColor,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit01,
                color: context.primaryColor,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                color: context.errorColor,
              ),
              onPressed: () {},
            ),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Floating Action Buttons'),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            FloatingActionButton.small(
              heroTag: 'fab1',
              onPressed: () {},
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.onPrimary,
              ),
            ),
            FloatingActionButton(
              heroTag: 'fab2',
              onPressed: () {},
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.onPrimary,
              ),
            ),
            FloatingActionButton.extended(
              heroTag: 'fab3',
              onPressed: () {},
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: context.onPrimary,
              ),
              label: const Text('Create'),
            ),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Segmented Button'),
        SegmentedButton<ThemeSelection>(
          segments: ThemeSelection.values.map((selection) {
            return ButtonSegment<ThemeSelection>(
              value: selection,
              label: Text(selection.label),
              icon: HugeIcon(
                icon: _getThemeIcon(selection),
                color: context.onSurface,
                size: 18,
              ),
            );
          }).toList(),
          selected: const {ThemeSelection.system},
          onSelectionChanged: (_) {},
        ),
        VSpace.lg(),
        _SectionHeader('Gradient Buttons'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            GradientButton(
              label: 'Primary Action',
              onPressed: () {},
            ),
            GradientButton(
              label: 'With Icon',
              icon: HugeIcons.strokeRoundedAdd01,
              onPressed: () {},
            ),
            GradientOutlineButton(
              label: 'Outline Style',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeSelection selection) {
    switch (selection) {
      case ThemeSelection.light:
        return HugeIcons.strokeRoundedSun01;
      case ThemeSelection.dark:
        return HugeIcons.strokeRoundedMoon01;
      case ThemeSelection.system:
        return HugeIcons.strokeRoundedSmartPhone01;
    }
  }
}

// ============================================
// Inputs Gallery
// ============================================

class _InputsGallery extends StatelessWidget {
  const _InputsGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Text Fields'),
        AppTextFormField(
          labelText: 'Default Input',
          hintText: 'Enter text...',
        ),
        VSpace.md(),
        AppTextFormField(
          labelText: 'With Prefix',
          hintText: 'Enter email...',
          prefixIcon: HugeIcon(
            icon: HugeIcons.strokeRoundedMail01,
            color: context.textSecondary,
          ),
        ),
        VSpace.md(),
        AppTextFormField(
          labelText: 'With Suffix',
          hintText: 'Enter password...',
          obscureText: true,
          suffixIcon: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedView,
              color: context.textSecondary,
            ),
            onPressed: () {},
          ),
        ),
        VSpace.md(),
        AppTextFormField(
          labelText: 'Dense Input',
          hintText: 'Compact...',
          isDense: true,
        ),
        VSpace.md(),
        AppTextFormField(
          labelText: 'Error State',
          hintText: 'Invalid input',
          // Note: Error styling is handled via form validation
        ),
        VSpace.md(),
        const AppTextFormField(
          labelText: 'Disabled',
          hintText: 'Cannot edit...',
          enabled: false,
        ),
        VSpace.lg(),
        _SectionHeader('Switches & Checkboxes'),
        SwitchListTile(
          title: const Text('Switch Option'),
          subtitle: const Text('Toggle this setting'),
          value: true,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          title: const Text('Checkbox Option'),
          subtitle: const Text('Select this option'),
          value: true,
          onChanged: (_) {},
        ),
        VSpace.lg(),
        _SectionHeader('Chips'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilterChip(
              label: const Text('Filter'),
              selected: true,
              onSelected: (_) {},
            ),
            FilterChip(
              label: const Text('Unselected'),
              selected: false,
              onSelected: (_) {},
            ),
            ActionChip(
              label: const Text('Action'),
              onPressed: () {},
            ),
            const InputChip(
              label: Text('Input'),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================
// Cards Gallery
// ============================================

class _CardsGallery extends StatelessWidget {
  const _CardsGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('AppCard Variants'),
        AppCard(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: const Text('Default Card'),
          ),
        ),
        VSpace.md(),
        AppCard(
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: const Text('Tappable Card'),
          ),
        ),
        VSpace.md(),
        AppCard(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: const Text('Elevated Card'),
          ),
        ),
        VSpace.lg(),
        _SectionHeader('Content Cards'),
        AppCard(
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedDumbbell01,
                color: context.primaryColor,
              ),
            ),
            title: const Text('Workout Card'),
            subtitle: const Text('3 exercises • 45 min'),
            trailing: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: context.textSecondary,
            ),
          ),
        ),
        VSpace.md(),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('Program Card'),
                subtitle: const Text('12 Week Strength Builder'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: context.surfaceVariant,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  '60% Complete',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// Icons Gallery
// ============================================

class _IconsGallery extends StatelessWidget {
  const _IconsGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Icon Sizes'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IconSizeDemo('Small', AppDimensions.iconSmall),
            _IconSizeDemo('Medium', AppDimensions.iconMedium),
            _IconSizeDemo('Large', AppDimensions.iconLarge),
            _IconSizeDemo('XLarge', AppDimensions.iconXLarge),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Navigation Icons'),
        _IconGrid([
          _IconItem(HugeIcons.strokeRoundedHome01, 'Home'),
          _IconItem(HugeIcons.strokeRoundedWorkoutGymnastics, 'Programs'),
          _IconItem(HugeIcons.strokeRoundedDumbbell01, 'Workout'),
          _IconItem(HugeIcons.strokeRoundedAnalytics01, 'Progress'),
          _IconItem(HugeIcons.strokeRoundedSettings01, 'Settings'),
          _IconItem(HugeIcons.strokeRoundedUser, 'Profile'),
        ]),
        VSpace.lg(),
        _SectionHeader('Action Icons'),
        _IconGrid([
          _IconItem(HugeIcons.strokeRoundedAdd01, 'Add'),
          _IconItem(HugeIcons.strokeRoundedEdit01, 'Edit'),
          _IconItem(HugeIcons.strokeRoundedDelete01, 'Delete'),
          _IconItem(HugeIcons.strokeRoundedSearch01, 'Search'),
          _IconItem(HugeIcons.strokeRoundedFilter, 'Filter'),
          _IconItem(HugeIcons.strokeRoundedShare01, 'Share'),
        ]),
        VSpace.lg(),
        _SectionHeader('Status Icons'),
        _IconGrid([
          _IconItem(HugeIcons.strokeRoundedCheckmarkCircle01, 'Success'),
          _IconItem(HugeIcons.strokeRoundedAlert01, 'Warning'),
          _IconItem(HugeIcons.strokeRoundedCancel01, 'Error'),
          _IconItem(HugeIcons.strokeRoundedInformationCircle, 'Info'),
        ]),
        VSpace.lg(),
        _SectionHeader('Fitness Icons'),
        _IconGrid([
          _IconItem(HugeIcons.strokeRoundedDumbbell01, 'Dumbbell'),
          _IconItem(HugeIcons.strokeRoundedWorkoutGymnastics, 'Gymnastics'),
          _IconItem(HugeIcons.strokeRoundedRunningShoes, 'Running'),
          _IconItem(HugeIcons.strokeRoundedTimer01, 'Timer'),
          _IconItem(HugeIcons.strokeRoundedCalendar01, 'Calendar'),
          _IconItem(HugeIcons.strokeRoundedMedal01, 'Trophy'),
        ]),
      ],
    );
  }
}

class _IconSizeDemo extends StatelessWidget {
  final String label;
  final double size;

  const _IconSizeDemo(this.label, this.size);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedDumbbell01,
          color: context.primaryColor,
          size: size,
        ),
        VSpace.xs(),
        Text(label, style: AppTextStyles.labelSmall),
        Text('${size.toInt()}', style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _IconItem {
  final IconData icon;
  final String label;

  const _IconItem(this.icon, this.label);
}

class _IconGrid extends StatelessWidget {
  final List<_IconItem> icons;

  const _IconGrid(this.icons);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: icons.map((item) {
        return SizedBox(
          width: 80,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusSmall),
                ),
                child: HugeIcon(
                  icon: item.icon,
                  color: context.onSurface,
                  size: AppDimensions.iconMedium,
                ),
              ),
              VSpace.xs(),
              Text(
                item.label,
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================
// Spacing Gallery
// ============================================

class _SpacingGallery extends StatelessWidget {
  const _SpacingGallery();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Spacing Scale (8dp Grid)'),
        _SpacingItem('xs', AppSpacing.xs, '4'),
        _SpacingItem('sm', AppSpacing.sm, '8'),
        _SpacingItem('md', AppSpacing.md, '16'),
        _SpacingItem('lg', AppSpacing.lg, '24'),
        _SpacingItem('xl', AppSpacing.xl, '32'),
        _SpacingItem('xxl', AppSpacing.xxl, '48'),
        VSpace.lg(),
        _SectionHeader('Border Radius'),
        _RadiusItem('Small', AppDimensions.borderRadiusSmall),
        _RadiusItem('Medium', AppDimensions.borderRadiusMedium),
        _RadiusItem('Large', AppDimensions.borderRadiusLarge),
        _RadiusItem('XLarge', AppDimensions.borderRadiusXLarge),
        _RadiusItem('Round', AppDimensions.borderRadiusRound),
        VSpace.lg(),
        _SectionHeader('VSpace / HSpace Widgets'),
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: context.outlineColor),
            borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          child: Row(
            children: [
              _SpacingBox(context),
              HSpace.xs(),
              _SpacingBox(context),
              HSpace.sm(),
              _SpacingBox(context),
              HSpace.md(),
              _SpacingBox(context),
              HSpace.lg(),
              _SpacingBox(context),
            ],
          ),
        ),
        VSpace.md(),
        Text(
          'HSpace.xs() → HSpace.lg()',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SpacingItem extends StatelessWidget {
  final String name;
  final double value;
  final String px;

  const _SpacingItem(this.name, this.value, this.px);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(name, style: AppTextStyles.titleSmall),
          ),
          Container(
            width: value,
            height: 24,
            color: context.primaryColor,
          ),
          HSpace.sm(),
          Text(
            '${px}dp',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusItem extends StatelessWidget {
  final String name;
  final double value;

  const _RadiusItem(this.name, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(value),
            ),
          ),
          HSpace.md(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.titleSmall),
              Text(
                '${value.toInt()}dp',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpacingBox extends StatelessWidget {
  final BuildContext context;

  const _SpacingBox(this.context);

  @override
  Widget build(BuildContext _) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ============================================
// Shared Components
// ============================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================
// Animations Gallery
// ============================================

class _AnimationsGallery extends ConsumerStatefulWidget {
  const _AnimationsGallery();

  @override
  ConsumerState<_AnimationsGallery> createState() => _AnimationsGalleryState();
}

class _AnimationsGalleryState extends ConsumerState<_AnimationsGallery> {
  int _counterValue = 0;
  double _progressValue = 0.3;
  bool _showSkeletons = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionHeader('Progress Rings'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                ProgressRing(
                  progress: 0.75,
                  size: 60,
                  strokeWidth: 6,
                  progressColor: context.primaryColor,
                  child: Text('75%', style: AppTextStyles.labelMedium),
                ),
                VSpace.sm(),
                Text('Static', style: AppTextStyles.labelSmall),
              ],
            ),
            Column(
              children: [
                AnimatedProgressRing(
                  progress: _progressValue,
                  size: 60,
                  strokeWidth: 6,
                  progressColor: context.successColor,
                  child: Text(
                    '${(_progressValue * 100).toInt()}%',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
                VSpace.sm(),
                Text('Animated', style: AppTextStyles.labelSmall),
              ],
            ),
            Column(
              children: [
                MiniProgressRing(
                  progress: 0.5,
                  color: context.secondaryColor,
                ),
                VSpace.sm(),
                Text('Mini', style: AppTextStyles.labelSmall),
              ],
            ),
          ],
        ),
        VSpace.sm(),
        Slider(
          value: _progressValue,
          onChanged: (value) => setState(() => _progressValue = value),
        ),
        VSpace.lg(),
        _SectionHeader('Animated Counter'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _counterValue -= 10),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMinusSign,
                color: context.primaryColor,
              ),
            ),
            AnimatedCounter(
              value: _counterValue,
              style: AppTextStyles.displayMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _counterValue += 10),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Entrance Animations'),
        StaggeredList(
          staggerDelay: const Duration(milliseconds: 100),
          children: [
            _AnimationDemoCard('FadeInWidget', 'Smooth opacity transition'),
            _AnimationDemoCard(
                'SlideInWidget', 'Slide + fade from any direction'),
            _AnimationDemoCard(
                'PulseWidget', 'Subtle attention-grabbing pulse'),
          ],
        ),
        VSpace.lg(),
        _SectionHeader('Skeleton Loaders'),
        SwitchListTile(
          title: const Text('Show Skeletons'),
          subtitle: const Text('Toggle to see skeleton vs content'),
          value: _showSkeletons,
          onChanged: (value) => setState(() => _showSkeletons = value),
        ),
        VSpace.sm(),
        if (_showSkeletons) ...[
          const SkeletonCard(height: 80),
          VSpace.sm(),
          const SkeletonExerciseCard(),
          VSpace.sm(),
          Row(
            children: [
              const SkeletonAvatar(),
              HSpace.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 150, height: 16),
                    VSpace.xs(),
                    SkeletonText(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: const Text('Loaded content appears here'),
            ),
          ),
          VSpace.sm(),
          AppCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: context.primaryColor,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDumbbell01,
                  color: context.onPrimary,
                ),
              ),
              title: const Text('Bench Press'),
              subtitle: const Text('3 sets × 10 reps'),
            ),
          ),
          VSpace.sm(),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.secondaryColor,
                child: const Text('JD'),
              ),
              HSpace.md(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('John Doe', style: AppTextStyles.titleSmall),
                  Text('Premium Member',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.textSecondary,
                      )),
                ],
              ),
            ],
          ),
        ],
        VSpace.lg(),
        _SectionHeader('Empty States'),
        SizedBox(
          height: 300,
          child: EmptyState.noWorkouts(
            onCreateWorkout: () {},
          ),
        ),
        VSpace.md(),
        SizedBox(
          height: 250,
          child: EmptyState.noResults(
            searchTerm: 'burpees',
            onClearSearch: () {},
          ),
        ),
        VSpace.xxl(),
      ],
    );
  }
}

class _AnimationDemoCard extends StatelessWidget {
  final String title;
  final String description;

  const _AnimationDemoCard(this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMotion01,
              color: context.primaryColor,
            ),
          ),
          title: Text(title),
          subtitle: Text(description),
        ),
      ),
    );
  }
}

/// Extension to convert Color to hex string
extension ColorHex on Color {
  String toHex() {
    final r = (this.r * 255.0).round() & 0xff;
    final g = (this.g * 255.0).round() & 0xff;
    final b = (this.b * 255.0).round() & 0xff;
    return '${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}
