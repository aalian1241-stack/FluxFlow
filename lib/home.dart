import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import 'data.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const presets = <HabitPreset>[
    HabitPreset(Icons.water_drop_rounded, Color(0xFF1687F8), 'Health', 'Water'),
    HabitPreset(Icons.menu_book_rounded, Color(0xFF7C4DFF), 'Study', 'Read'),
    HabitPreset(Icons.directions_run_rounded, Color(0xFFE85D75), 'Fitness', 'Exercise'),
    HabitPreset(Icons.self_improvement_rounded, Color(0xFF009688), 'Mind', 'Meditate'),
    HabitPreset(Icons.bedtime_rounded, Color(0xFF536DFE), 'Health', 'Sleep'),
    HabitPreset(Icons.code_rounded, Color(0xFFFF8A00), 'Work', 'Code'),
    HabitPreset(Icons.directions_walk_rounded, Color(0xFF2EAD63), 'Fitness', 'Walk'),
    HabitPreset(Icons.music_note_rounded, Color(0xFFFFB300), 'Personal', 'Music'),
    HabitPreset(Icons.favorite_rounded, Color(0xFFEF5350), 'Health', 'Self care'),
    HabitPreset(Icons.edit_note_rounded, Color(0xFF546E7A), 'Personal', 'Journal'),
    HabitPreset(Icons.park_rounded, Color(0xFF43A047), 'Personal', 'Outside'),
    HabitPreset(Icons.cleaning_services_rounded, Color(0xFF7E57C2), 'Personal', 'Tidy up'),
  ];

  final LocalStore _store = LocalStore();
  final TextEditingController _searchController = TextEditingController();

  List<Habit> _habits = <Habit>[];
  int _tab = 0;
  String _query = '';
  bool _showArchived = false;
  bool _loading = true;
  bool _saving = false;
  Future<void> _saveQueue = Future<void>.value();

  Map<String, int>? _cachedLevels;

  DateTime get _today => Habit.dateOnly(DateTime.now());

  List<Habit> get _active =>
      _habits.where((habit) => !habit.archived).toList(growable: false);

  List<Habit> get _archived =>
      _habits.where((habit) => habit.archived).toList(growable: false);

  int get _doneToday =>
      _active.where((habit) => habit.isCompleted(_today)).length;

  double get _todayProgress =>
      _active.isEmpty ? 0 : _doneToday / _active.length;

  String _getBreakpoint() {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 'mobile';
    if (width < 1024) return 'tablet';
    return 'desktop';
  }

  double _getMaxWidth() {
    final bp = _getBreakpoint();
    if (bp == 'mobile') return MediaQuery.of(context).size.width;
    if (bp == 'tablet') return 720.0;
    return 1024.0;
  }


  int get _totalCompletions => _habits.fold(
        0,
        (sum, habit) => sum + habit.completedDates.length,
      );

  int get _activeDays {
    final days = <String>{};

    for (final habit in _habits) {
      days.addAll(habit.completedDates);
    }

    return days.length;
  }

  int get _bestStreak {
    var result = 0;

    for (final habit in _habits) {
      final value = habit.bestStreak();
      if (value > result) result = value;
    }

    return result;
  }

  double get _weeklyConsistency {
    if (_active.isEmpty) return 0;

    var score = 0.0;

    for (final habit in _active) {
      score += habit.goalProgress(_today);
    }

    return score / _active.length;
  }

  List<Habit> get _filteredHabits {
    final query = _query.trim().toLowerCase();

    final source = _showArchived ? _archived : _active;

    return source.where((habit) {
      final queryMatch =
          query.isEmpty ||
          habit.name.toLowerCase().contains(query) ||
          habit.description.toLowerCase().contains(query);

      return queryMatch;
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_searchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_searchChanged)
      ..dispose();
    super.dispose();
  }

  void _searchChanged() {
    final query = _searchController.text;
    if (query == _query || !mounted) return;
    setState(() => _query = query);
  }

  Future<void> _load() async {
    final habits = await _store.loadHabits();

    if (!mounted) return;

    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  Future<void> _save() {
    final snapshot = _habits
        .map((habit) => Habit.fromJson(habit.toJson()))
        .toList(growable: false);

    final next = _saveQueue.then((_) async {
      if (mounted && !_saving) setState(() => _saving = true);
      try {
        await _store.saveHabits(snapshot);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });

    _saveQueue = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  Future<void> _toggle(Habit habit) async {
    setState(() {
      habit.toggle(_today);
      _cachedLevels = null;
    });
    await _save();
  }

  Future<void> _openEditor([Habit? old]) async {
    final result = await showModalBottomSheet<Habit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitEditor(
        existing: old,
        presets: presets,
      ),
    );

    if (result == null || !mounted) return;

    final list = List<Habit>.from(_habits);
    final index = list.indexWhere((habit) => habit.id == result.id);

    if (index == -1) {
      list.add(result);
    } else {
      list[index] = result;
    }

    setState(() {
      _habits = list;
      _cachedLevels = null;
    });
    await _save();
  }

  Future<void> _delete(Habit habit) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "${habit.name}" and its history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes != true || !mounted) return;

    setState(() {
      _habits = List<Habit>.from(_habits)
        ..removeWhere((item) => item.id == habit.id);
      _cachedLevels = null;
    });

    await _save();
  }

  Future<void> _archive(Habit habit) async {
    setState(() {
      habit.archived = !habit.archived;
      _cachedLevels = null;
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: FynoxFowApp.primary),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _todayPage(),
          _habitsPage(),
          _insightsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: FynoxFowApp.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _bottomNavBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 48;
        final itemWidth = availableWidth / 3;
        final indicatorWidth = itemWidth - 32;

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sliding Indicator Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.backOut,
                left: _tab * itemWidth + (itemWidth - indicatorWidth) / 2,
                child: Container(
                  width: indicatorWidth,
                  height: 48,
                  decoration: BoxDecoration(
                    color: FynoxFowApp.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // Active Dot Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.backOut,
                left: _tab * itemWidth + (itemWidth / 2) - 2,
                bottom: 10,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: FynoxFowApp.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(0, Icons.dashboard_rounded),
                  _navItem(1, Icons.checklist_rounded),
                  _navItem(2, Icons.bar_chart_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(int index, IconData icon) {
    final isSelected = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_tab != index) {
            HapticFeedback.lightImpact();
            setState(() => _tab = index);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isSelected ? 1.25 : 1.0,
            curve: Curves.backOut,
            child: TweenAnimationBuilder<Color>(
              duration: const Duration(milliseconds: 300),
              tween: ColorTween(
                begin: Colors.grey.shade400,
                end: isSelected ? FynoxFowApp.primary : Colors.grey.shade400,
              ),
              builder: (context, color, child) {
                return Icon(
                  icon,
                  color: color,
                  size: 26,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageBody({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _getMaxWidth()),
            child: child,
          ),
        );
      },
    );
  }

  Widget _sliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: FynoxFowApp.primary,
      centerTitle: false,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 32, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fynox Flow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: FynoxFowApp.primary,
              ),
            ),
            Text(
              'Small steps. Real flow.',
              style: TextStyle(
                color: FynoxFowApp.primary.withValues(alpha: .7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_saving)
          Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Center(
              child: SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation(FynoxFowApp.primary),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _todayPage() {
    return _pageBody(
      child: CustomScrollView(
        slivers: [
          _sliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _hero(),
                  const SizedBox(height: 20),
                  _summaryRow(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (_active.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: _empty(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _habitTile(_active[index]),
                  childCount: _active.length,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
            sliver: SliverToBoxAdapter(
              child: _activityCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    IconData progressIcon;
    String title;
    String subtitle;

    if (_active.isEmpty) {
      progressIcon = Icons.wb_sunny_outlined;
      title = 'Ready to start?';
      subtitle = 'Create your first habit';
    } else if (_todayProgress == 1) {
      progressIcon = Icons.local_fire_department_rounded;
      title = 'Perfect Day';
      subtitle = '$_doneToday of ${_active.length} habits completed';
    } else if (_todayProgress >= .75) {
      progressIcon = Icons.emoji_events;
      title = 'Almost There!';
      subtitle = '$_doneToday of ${_active.length} habits completed';
    } else if (_todayProgress >= .5) {
      progressIcon = Icons.trending_up_rounded;
      title = 'Great Momentum';
      subtitle = '$_doneToday of ${_active.length} habits completed';
    } else if (_todayProgress > 0) {
      progressIcon = Icons.eco;
      title = 'Keep Going!';
      subtitle = '$_doneToday of ${_active.length} habits completed';
    } else {
      progressIcon = Icons.grass;
      title = 'Start Your Flow';
      subtitle = 'No habits completed yet';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: FynoxFowApp.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FynoxFowApp.primary.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  progressIcon,
                  color: FynoxFowApp.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _todayProgress,
              minHeight: 8,
              backgroundColor: FynoxFowApp.primary.withValues(alpha: .1),
              valueColor: const AlwaysStoppedAnimation(FynoxFowApp.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _active.isEmpty
                    ? 'Your journey begins here.'
                    : '${(_todayProgress * 100).round()}% today',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_todayProgress > 0 && _todayProgress < 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Keep pushing!',
                      style: TextStyle(
                        color: FynoxFowApp.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.trending_up_rounded,
                      color: FynoxFowApp.primary,
                      size: 12,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _progressText() {
    if (_active.isEmpty) return 'Ready to start your flow?';
    if (_todayProgress == 1) return 'Absolute perfection!';
    if (_todayProgress >= .75) return 'Almost there, keep going!';
    if (_todayProgress >= .5) return 'Great momentum so far!';
    if (_todayProgress > 0) return 'Small steps lead to big change.';
    return 'One check-in at a time. You got this!';
  }

  Widget _summaryRow() {
    return Row(
      children: [
        Expanded(
          child: _miniMetric(
            value: '$_doneToday/${_active.length}',
            label: 'Today',
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniMetric(
            value: '$_bestStreak',
            label: 'Best streak',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniMetric(
            value: '$_activeDays',
            label: 'Active days',
            icon: Icons.calendar_month_rounded,
          ),
        ),
      ],
    );
  }

  Widget _miniMetric({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FynoxFowApp.primary, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: FynoxFowApp.darkPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitTile(Habit habit) {
    final color = Color(habit.colorValue);
    final complete = habit.isCompleted(_today);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggle(habit),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: .11),
                  child: Icon(
                    IconData(
                      habit.iconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          decoration: complete
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 13,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${habit.currentStreak(_today)} day streak',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            habit.targetFrequency == TargetFrequency.daily
                                ? 'Daily'
                                : '${habit.completionsForFrequency(_today)}/${habit.targetValue} ${habit.targetFrequency.name}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: complete ? color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: complete ? color : Colors.black26,
                          width: 2,
                        ),
                      ),
                      child: complete
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _openEditor(habit);
                    if (value == 'archive') _archive(habit);
                    if (value == 'delete') _delete(habit);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        habit.archived ? 'Restore' : 'Archive',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.spa_rounded,
            color: FynoxFowApp.primary,
            size: 52,
          ),
          const SizedBox(height: 12),
          const Text(
            'Start your flow',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create one small habit to begin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create habit'),
          ),
        ],
      ),
    );
  }

  Widget _habitsPage() {
    final filtered = _filteredHabits;
    final bp = _getBreakpoint();

    return _pageBody(
      child: CustomScrollView(
        slivers: [
          _sliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Habits',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Toggle archived',
                        onPressed: () {
                          setState(() => _showArchived = !_showArchived);
                        },
                        icon: Icon(
                          _showArchived
                              ? Icons.inventory_2_rounded
                              : Icons.archive_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _showArchived
                        ? '${_archived.length} archived'
                        : '${_active.length} active',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear_rounded, size: 20),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Category filter removed
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: _empty(),
              ),
            )
          else if (bp == 'mobile')
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _managementCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: bp == 'tablet' ? 2 : 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 3,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _managementCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 110),
          ),
        ],
      ),
    );
  }

  Widget _managementCard(Habit habit) {
    final color = Color(habit.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .11),
            child: Icon(
              IconData(
                habit.iconCodePoint,
                fontFamily: 'MaterialIcons',
              ),
              color: color,
            ),
          ),
          title: Text(
            habit.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            habit.description.isNotEmpty
                ? habit.description
                : '${habit.completedDates.length} completions',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _openEditor(habit);
              if (value == 'archive') _archive(habit);
              if (value == 'delete') _delete(habit);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(habit.archived ? 'Restore' : 'Archive'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _insightsPage() {
    return _pageBody(
      child: CustomScrollView(
        slivers: [
          _sliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insights',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Your numbers, without the noise.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statCard('$_totalCompletions', 'Completions'),
                      const SizedBox(width: 10),
                      _statCard('$_activeDays', 'Active days'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard('$_bestStreak', 'Best streak'),
                      const SizedBox(width: 10),
                      _statCard(
                        '${(_weeklyConsistency * 100).round()}%',
                        'Goal progress',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _goalsCard(),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
            sliver: SliverToBoxAdapter(
              child: _activityCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          if (_active.isEmpty)
            Text(
              'Create a habit to see goals.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _active.length > 6 ? 6 : _active.length,
              itemBuilder: (context, index) {
                final habit = _active[index];
                final progress = habit.goalProgress(_today);
                final count = habit.completionsForFrequency(_today);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            habit.targetFrequency == TargetFrequency.daily
                                ? 'Daily'
                                : '$count/${habit.targetValue}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: FynoxFowApp.darkPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFF5F5F5),
                          valueColor: AlwaysStoppedAnimation(
                            Color(habit.colorValue),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _activityCard() {
    final start = _today.subtract(const Duration(days: 90));
    final active = _active;

    // Memoization: Recalculate levels only if cache is empty
    if (_cachedLevels == null) {
      final levels = <String, int>{};
      for (var i = 0; i <= 90; i++) {
        final date = start.add(Duration(days: i));
        var completed = 0;

        for (final habit in active) {
          if (habit.isCompleted(date)) completed++;
        }

        final ratio = active.isEmpty ? 0.0 : completed / active.length;
        levels[Habit.dayKey(date)] = completed == 0
            ? 0
            : ratio < .25
                ? 1
                : ratio < .5
                    ? 2
                    : ratio < .75
                        ? 3
                        : 4;
      }
      _cachedLevels = levels;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 13 weeks',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(13, (column) {
                return Padding(
                  padding: EdgeInsets.only(right: column == 12 ? 0 : 3),
                  child: Column(
                    children: List.generate(7, (row) {
                      final date = start.add(Duration(days: column * 7 + row));
                      final level = _cachedLevels![Habit.dayKey(date)] ?? 0;

                      return Container(
                        width: 12,
                        height: 12,
                        margin: EdgeInsets.only(bottom: row == 6 ? 0 : 3),
                        decoration: BoxDecoration(
                          color: _activityColor(level),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Less', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              const SizedBox(width: 6),
              ...List.generate(5, (index) => Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: _activityColor(index),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
              const SizedBox(width: 6),
              Text('More', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Color _activityColor(int level) {
    const values = [
      Color(0xFFF3E5F5),
      Color(0xFFCE93D8),
      Color(0xFFBA68C8),
      Color(0xFF8E24AA),
      FynoxFowApp.darkPrimary,
    ];

    return values[level.clamp(0, 4)];
  }
}

class HabitEditor extends StatefulWidget {
  const HabitEditor({
    required this.existing,
    required this.presets,
    super.key,
  });

  final Habit? existing;
  final List<HabitPreset> presets;

  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late int _icon;
  late Color _color;
  late int _targetValue;
  late TargetFrequency _targetFrequency;

  HabitPreset? _presetForIcon(int codePoint) {
    for (final preset in widget.presets) {
      if (preset.icon.codePoint == codePoint) return preset;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final old = widget.existing;
    final first = widget.presets.first;

    _name = TextEditingController(text: old?.name ?? '');
    _description = TextEditingController(text: old?.description ?? '');
    _icon = old?.iconCodePoint ?? first.icon.codePoint;
    _color = old == null ? first.color : Color(old.colorValue);
    _targetFrequency = old?.targetFrequency ?? TargetFrequency.weekly;
    _targetValue = old?.targetValue ?? (_targetFrequency == TargetFrequency.daily ? 1 : 5);

    if (_targetFrequency == TargetFrequency.daily) {
      _targetValue = 1;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _choosePreset(HabitPreset preset) {
    setState(() {
      _icon = preset.icon.codePoint;
      _color = preset.color;
      if (_name.text.trim().isEmpty) _name.text = preset.title;
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a habit name.')),
      );
      return;
    }

    final old = widget.existing;
    Navigator.pop(
      context,
      Habit(
        id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        description: _description.text.trim(),
        category: 'Personal',
        iconCodePoint: _icon,
        colorValue: _color.toARGB32(),
        createdAt: old?.createdAt ?? DateTime.now(),
        targetValue: _targetValue,
        targetFrequency: _targetFrequency,
        archived: old?.archived ?? false,
        completedDates: old == null ? <String>{} : {...old.completedDates},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final selectedPreset = _presetForIcon(_icon);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.existing == null ? 'New habit' : 'Edit habit',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: FynoxFowApp.darkPrimary,
                          ),
                        ),
                      ),
                      if (selectedPreset != null)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: selectedPreset.color, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                selectedPreset.color.withValues(alpha: .12),
                            child: Icon(
                              selectedPreset.icon,
                              color: selectedPreset.color,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Habit name',
                      hintText: 'e.g. Read 20 minutes',
                      prefixIcon: const Icon(Icons.edit_rounded, color: FynoxFowApp.primary),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 3,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional',
                      prefixIcon: const Icon(Icons.notes_rounded, color: FynoxFowApp.primary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Suggested Habits',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 68,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (_, index) {
                        final preset = widget.presets[index];
                        final selected = preset.icon.codePoint == _icon;

                        return InkWell(
                          onTap: () => _choosePreset(preset),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 62,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? preset.color.withValues(alpha: .10)
                                  : const Color(0xFFF5F5FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? preset.color
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  preset.icon,
                                  color: preset.color,
                                  size: 22,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preset.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Repeat',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: TargetFrequency.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final freq = TargetFrequency.values[index];
                        final selected = _targetFrequency == freq;
                        final icon = {
                          TargetFrequency.daily: Icons.today_rounded,
                          TargetFrequency.weekly: Icons.calendar_view_week_rounded,
                          TargetFrequency.monthly: Icons.calendar_month_rounded,
                        }[freq];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _targetFrequency = freq;
                              if (freq == TargetFrequency.daily) {
                                _targetValue = 1;
                              } else if (widget.existing == null) {
                                _targetValue = freq == TargetFrequency.weekly ? 5 : 20;
                              } else {
                                int max = freq == TargetFrequency.weekly ? 7 : 31;
                                if (_targetValue > max) _targetValue = max;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? FynoxFowApp.primary.withValues(alpha: .1)
                                  : const Color(0xFFF5F5FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? FynoxFowApp.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon!,
                                  color: selected ? FynoxFowApp.primary : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  freq.name[0].toUpperCase() + freq.name.substring(1),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                    color: selected ? FynoxFowApp.darkPrimary : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_targetFrequency != TargetFrequency.daily) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withValues(alpha: .05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Target Value',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$_targetValue',
                                style: const TextStyle(
                                  color: FynoxFowApp.darkPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Slider(
                            value: _targetValue.toDouble(),
                            min: 1,
                            max: _targetFrequency == TargetFrequency.weekly ? 7.0 : 31.0,
                            divisions: _targetFrequency == TargetFrequency.weekly ? 6 : 30,
                            label: '$_targetValue',
                            onChanged: (value) => setState(
                              () => _targetValue = value.round(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: Icon(
                        widget.existing == null
                            ? Icons.add_rounded
                            : Icons.check_rounded,
                      ),
                      label: Text(
                        widget.existing == null
                            ? 'Create habit'
                            : 'Save changes',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: FynoxFowApp.primary,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HabitPreset {
  const HabitPreset(this.icon, this.color, this.category, this.title);

  final IconData icon;
  final Color color;
  final String category;
  final String title;
}
