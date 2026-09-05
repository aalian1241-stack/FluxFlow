import 'package:flutter/material.dart';

import 'models.dart';

// ============================================================================
// ONBOARDING
// ============================================================================
class OnboardingStep {
  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _page = 0;

  final List<OnboardingStep> _steps = const <OnboardingStep>[
    OnboardingStep(
      icon: Icons.spa_rounded,
      title: 'Small habits.\nBig momentum.',
      description:
          'Flux Flow gives you a simple place to build routines and stay consistent every day.',
    ),
    OnboardingStep(
      icon: Icons.track_changes_rounded,
      title: 'Track what\nmatters.',
      description:
          'Create habits, choose a category, mark them complete, and build your streak without clutter.',
    ),
    OnboardingStep(
      icon: Icons.insights_rounded,
      title: 'See your\nprogress.',
      description:
          'Use simple insights to see your completion rate, streaks, and habit categories at a glance.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }

    _finish();
  }

  void _skip() {
    _pageController.animateToPage(
      _steps.length - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name to continue.'),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(username: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                compact ? 12 : 22,
                22,
                16,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const _Brand(),
                      if (_page < _steps.length - 1)
                        TextButton(
                          onPressed: _skip,
                          child: const Text('Skip'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (int value) {
                        setState(() {
                          _page = value;
                        });
                      },
                      itemBuilder: (context, index) {
                        final OnboardingStep step = _steps[index];
                        final bool isLast = index == _steps.length - 1;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          child: Column(
                            children: <Widget>[
                              SizedBox(height: compact ? 12 : 34),
                              Container(
                                width: compact ? 112 : 136,
                                height: compact ? 112 : 136,
                                decoration: BoxDecoration(
                                  color: lightGreen,
                                  borderRadius: BorderRadius.circular(38),
                                  border: Border.all(color: softGreen),
                                ),
                                child: Icon(
                                  step.icon,
                                  color: primaryGreen,
                                  size: compact ? 52 : 64,
                                ),
                              ),
                              SizedBox(height: compact ? 25 : 34),
                              Text(
                                step.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: compact ? 30 : 36,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 560),
                                child: Text(
                                  step.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: mutedText,
                                    fontSize: 16,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              if (isLast) ...<Widget>[
                                const SizedBox(height: 28),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  child: TextField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _finish(),
                                    decoration: const InputDecoration(
                                      hintText: 'Your name',
                                      prefixIcon:
                                          Icon(Icons.person_outline_rounded),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      _steps.length,
                      (int index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? primaryGreen
                              : softGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _page == _steps.length - 1
                            ? 'Start using Flux Flow'
                            : 'Continue',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// HOME
// ============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.username,
    super.key,
  });

  final String username;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  String _selectedCategory = 'All';
  String _searchText = '';
  bool _loadingData = true;

  final List<Habit> _habits = <Habit>[
    Habit(
      name: 'Drink water',
      category: 'Health',
      iconIndex: 2,
      colorIndex: 2,
    ),
    Habit(
      name: 'Read for 20 minutes',
      category: 'Learning',
      iconIndex: 4,
      colorIndex: 4,
    ),
    Habit(
      name: 'Exercise',
      category: 'Fitness',
      iconIndex: 3,
      colorIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final Map<String, dynamic>? data = await LocalStore.read();

    if (!mounted) return;

    if (data != null) {
      final String savedName = '${data['username'] ?? ''}'.trim();

      final Object? rawHabits = data['habits'];
      final List<Habit> loadedHabits = <Habit>[];

      if (rawHabits is List) {
        for (final Object? item in rawHabits) {
          if (item is Map) {
            try {
              loadedHabits.add(
                Habit.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              );
            } catch (_) {
              // Skip malformed habit data.
            }
          }
        }
      }

      setState(() {
        _loadingData = false;

        if (savedName.isNotEmpty && savedName != widget.username) {
          // The username is immutable in this screen, so we only use the
          // stored habits here. The onboarding screen supplies the name.
        }

        if (loadedHabits.isNotEmpty || rawHabits is List) {
          _habits
            ..clear()
            ..addAll(loadedHabits);
        }
      });
    } else {
      setState(() {
        _loadingData = false;
      });
      await _saveData();
    }
  }

  Future<void> _saveData() async {
    await LocalStore.write(
      <String, dynamic>{
        'username': widget.username,
        'habits': _habits.map((Habit habit) => habit.toJson()).toList(),
      },
    );
  }

  int get completedToday =>
      _habits.where((Habit habit) => habit.doneToday).length;

  int get completionPercent {
    if (_habits.isEmpty) {
      return 0;
    }
    return ((completedToday / _habits.length) * 100).round();
  }

  int get bestStreak {
    if (_habits.isEmpty) {
      return 0;
    }

    return _habits
        .map((Habit habit) => habit.bestStreak)
        .reduce((int a, int b) => a > b ? a : b);
  }

  List<Habit> get visibleHabits {
    return _habits.where((Habit habit) {
      final bool matchesCategory = _selectedCategory == 'All' ||
          habit.category == _selectedCategory;

      final bool matchesSearch = _searchText.trim().isEmpty ||
          habit.name.toLowerCase().contains(_searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _createHabit() async {
    final HabitDraft? draft = await _showHabitEditor();

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      _habits.add(
        Habit(
          name: draft.name,
          category: draft.category,
          iconIndex: draft.iconIndex,
          colorIndex: draft.colorIndex,
        ),
      );
    });
    await _saveData();
  }

  Future<void> _editHabit(Habit habit) async {
    final HabitDraft? draft = await _showHabitEditor(
      existingName: habit.name,
      existingCategory: habit.category,
      existingIconIndex: habit.iconIndex,
      existingColorIndex: habit.colorIndex,
    );

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      habit.name = draft.name;
      habit.category = draft.category;
      habit.iconIndex = draft.iconIndex;
      habit.colorIndex = draft.colorIndex;
    });
    await _saveData();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete habit?',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Delete "${habit.name}"?',
            style: const TextStyle(color: mutedText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE68D83),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _habits.remove(habit);
    });
    await _saveData();
  }

  Future<void> _toggleHabit(Habit habit) async {
    setState(habit.toggleToday);
    await _saveData();
  }

  Future<HabitDraft?> _showHabitEditor({
    String? existingName,
    String? existingCategory,
    int? existingIconIndex,
    int? existingColorIndex,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: existingName);

    String selectedCategory =
        existingCategory ?? habitCategories.first;
    int selectedIconIndex = existingIconIndex ?? 0;
    int selectedColorIndex = existingColorIndex ?? 0;

    final HabitDraft? result = await showModalBottomSheet<HabitDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool editing = existingName != null;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        editing ? 'Edit habit' : 'Create a habit',
                        style: const TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose a clear name, category, icon, and color.',
                        style: TextStyle(color: mutedText),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Habit name',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        textCapitalization:
                            TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Read for 20 minutes',
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          prefixIcon:
                              Icon(Icons.category_outlined),
                        ),
                        items: habitCategories
                            .map(
                              (String category) =>
                                  DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }

                          setSheetState(() {
                            selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Icon',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List<Widget>.generate(
                          habitIcons.length,
                          (int index) => _IconOption(
                            icon: habitIcons[index],
                            selected: selectedIconIndex == index,
                            onTap: () {
                              setSheetState(() {
                                selectedIconIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Color',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: List<Widget>.generate(
                          habitColors.length,
                          (int index) => _ColorOption(
                            color: habitColors[index],
                            selected: selectedColorIndex == index,
                            onTap: () {
                              setSheetState(() {
                                selectedColorIndex = index;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            final String name =
                                controller.text.trim();

                            if (name.isEmpty) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              HabitDraft(
                                name: name,
                                category: selectedCategory,
                                iconIndex: selectedIconIndex,
                                colorIndex: selectedColorIndex,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            editing ? 'Save changes' : 'Create habit',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width >= 820;

    if (_loadingData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryGreen,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            if (wide)
              _SideNavigation(
                selectedIndex: _selectedTab,
                bestStreak: bestStreak,
                onChanged: (int index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
              ),
            Expanded(
              child: _selectedTab == 0
                  ? _HabitsPage(
                      username: widget.username,
                      habits: visibleHabits,
                      allHabitsCount: _habits.length,
                      completedCount: completedToday,
                      completionPercent: completionPercent,
                      selectedCategory: _selectedCategory,
                      searchText: _searchText,
                      onSearchChanged: (String value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      onCategoryChanged: (String value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      onToggle: _toggleHabit,
                      onEdit: _editHabit,
                      onDelete: _deleteHabit,
                    )
                  : _InsightsPage(
                      username: widget.username,
                      habits: _habits,
                      completionPercent: completionPercent,
                      completedCount: completedToday,
                      bestStreak: bestStreak,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _selectedTab,
              backgroundColor: Colors.white,
              indicatorColor: lightGreen,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline_rounded),
                  selectedIcon: Icon(
                    Icons.check_circle_rounded,
                    color: primaryGreen,
                  ),
                  label: 'Habits',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(
                    Icons.insights_rounded,
                    color: primaryGreen,
                  ),
                  label: 'Insights',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createHabit,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New habit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ============================================================================
// HABITS PAGE
// ============================================================================

class _HabitsPage extends StatelessWidget {
  const _HabitsPage({
    required this.username,
    required this.habits,
    required this.allHabitsCount,
    required this.completedCount,
    required this.completionPercent,
    required this.selectedCategory,
    required this.searchText,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final String username;
  final List<Habit> habits;
  final int allHabitsCount;
  final int completedCount;
  final int completionPercent;
  final String selectedCategory;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final Future<void> Function(Habit) onToggle;
  final ValueChanged<Habit> onEdit;
  final ValueChanged<Habit> onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
          children: <Widget>[
            _PageHeader(
              title: 'Good morning, $username',
              subtitle: 'Small actions become strong routines.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFFE8F8EF),
                    Color(0xFFDDF2E8),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFD4EBDE),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          allHabitsCount == 0
                              ? 'Start your first habit'
                              : '$completedCount of $allHabitsCount complete',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          allHabitsCount == 0
                              ? 'Create a habit and begin your routine.'
                              : '$completionPercent% complete today.',
                          style: const TextStyle(
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search habits',
                prefixIcon:
                    const Icon(Icons.search_rounded),
                suffixIcon: searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => onSearchChanged(''),
                        icon:
                            const Icon(Icons.clear_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: habitCategories.map(
                  (String category) {
                    final bool selected =
                        category == selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) =>
                            onCategoryChanged(category),
                        selectedColor: softGreen,
                        labelStyle: TextStyle(
                          color: selected
                              ? primaryGreen
                              : textDark,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: selected
                              ? softGreen
                              : borderColor,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'YOUR HABITS',
              style: TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (habits.isEmpty)
              const _EmptyHabits()
            else
              ...habits.map(
                (Habit habit) => _HabitCard(
                  habit: habit,
                  onToggle: () => onToggle(habit),
                  onEdit: () => onEdit(habit),
                  onDelete: () => onDelete(habit),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// INSIGHTS
// ============================================================================

class _InsightsPage extends StatelessWidget {
  const _InsightsPage({
    required this.username,
    required this.habits,
    required this.completionPercent,
    required this.completedCount,
    required this.bestStreak,
  });

  final String username;
  final List<Habit> habits;
  final int completionPercent;
  final int completedCount;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> categoryCounts = <String, int>{};

    for (final Habit habit in habits) {
      categoryCounts[habit.category] =
          (categoryCounts[habit.category] ?? 0) + 1;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 110),
          children: <Widget>[
            _PageHeader(
              title: 'Your insights',
              subtitle:
                  '$username, here is your progress today.',
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFD4EBDE),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'TODAY',
                    style: TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$completionPercent% completed',
                    style: const TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$completedCount of ${habits.length} habits completed',
                    style: const TextStyle(
                      color: mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: habits.isEmpty
                          ? 0
                          : completedCount / habits.length,
                      minHeight: 12,
                      color: primaryGreen,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    title: 'Habits',
                    value: '${habits.length}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Best streak',
                    value: '$bestStreak',
                    icon:
                        Icons.local_fire_department_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'LAST 7 DAYS',
              style: TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _SevenDayChart(habits: habits),
            const SizedBox(height: 26),
            const Text(
              'BY CATEGORY',
              style: TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (categoryCounts.isEmpty)
              const _EmptyHabits()
            else
              ...categoryCounts.entries.map(
                (MapEntry<String, int> entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.category_outlined,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            const Text(
              'HABIT STATUS',
              style: TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (habits.isEmpty)
              const _EmptyHabits()
            else
              ...habits.map(
                (Habit habit) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: habit.color.withAlpha(30),
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                        child: Icon(
                          habit.icon,
                          color: habit.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              habit.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${habit.category} • ${habit.currentStreak} day current streak',
                              style: const TextStyle(
                                color: mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        habit.doneToday ? 'Done' : 'Pending',
                        style: TextStyle(
                          color: habit.doneToday
                              ? primaryGreen
                              : mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SEVEN DAY CHART
// ============================================================================

class _SevenDayChart extends StatelessWidget {
  const _SevenDayChart({
    required this.habits,
  });

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    final List<int> values = List<int>.generate(7, (int index) {
      final DateTime day =
          today.subtract(Duration(days: 6 - index));

      return habits
          .where((Habit habit) => habit.isCompletedOn(day))
          .length;
    });

    final int maxValue = habits.isEmpty
        ? 1
        : habits.length;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: List<Widget>.generate(
          7,
          (int index) {
            final double factor =
                values[index] / maxValue;
            final DateTime day =
                today.subtract(Duration(days: 6 - index));
            final String label = const <String>[
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
              'S',
            ][day.weekday - 1];

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${values[index]}',
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor:
                              factor.clamp(0.05, 1.0),
                          child: Container(
                            width: 28,
                            decoration: BoxDecoration(
                              color: index == 6
                                  ? accentGreen
                                  : softGreen,
                              borderRadius:
                                  BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 11,
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
    );
  }
}

// ============================================================================
// HABIT CARD
// ============================================================================

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            13,
            10,
            13,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habit.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  habit.icon,
                  color: habit.color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      habit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: habit.doneToday
                            ? mutedText
                            : textDark,
                        fontWeight: FontWeight.w800,
                        decoration: habit.doneToday
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(
                            habit.category,
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${habit.currentStreak} day streak',
                          style: const TextStyle(
                            color: mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (String value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: habit.doneToday
                      ? accentGreen
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: habit.doneToday
                        ? accentGreen
                        : borderColor,
                    width: 2,
                  ),
                ),
                child: habit.doneToday
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: textDark,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SIDE NAV
// ============================================================================

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.selectedIndex,
    required this.bestStreak,
    required this.onChanged,
  });

  final int selectedIndex;
  final int bestStreak;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>[
      'Habits',
      'Insights',
    ];

    const List<IconData> icons = <IconData>[
      Icons.check_circle_rounded,
      Icons.insights_rounded,
    ];

    return Container(
      width: 228,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFFEEF6F1),
        border: Border(
          right: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const _Brand(),
          const SizedBox(height: 44),
          for (int i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selectedIndex == i
                    ? softGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          icons[i],
                          color: selectedIndex == i
                              ? primaryGreen
                              : mutedText,
                          size: 21,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          labels[i],
                          style: TextStyle(
                            color: selectedIndex == i
                                ? primaryGreen
                                : textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: accentGreen,
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: textDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$bestStreak day best streak',
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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

// ============================================================================
// SHARED COMPONENTS
// ============================================================================

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: softGreen),
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: primaryGreen,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'flux flow',
          style: TextStyle(
            color: textDark,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: softGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: primaryGreen,
          ),
        ),
      ],
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.spa_outlined,
            color: primaryGreen,
            size: 44,
          ),
          SizedBox(height: 12),
          Text(
            'No habits found',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a new habit or change your search/filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedText),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
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

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? lightGreen : background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primaryGreen
                  : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: selected
                ? primaryGreen
                : mutedText,
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? textDark
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HABIT DRAFT
// ===============================================