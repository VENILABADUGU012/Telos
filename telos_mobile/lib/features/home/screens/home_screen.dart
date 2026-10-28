import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/task_provider.dart';
import '../../../core/providers/analytics_provider.dart';
import '../widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasksForDate(DateTime.now());
      context.read<AnalyticsProvider>().fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final selectedDate = taskProvider.selectedDate;

    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await taskProvider.fetchTasksForDate(selectedDate);
          await analyticsProvider.fetchAnalytics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. "Today" Section Heading & Date Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat('EEEE').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM d, y').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Calendar Date Picker Action
                  IconButton.filledTonal(
                    icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryLight),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        taskProvider.setSelectedDate(picked);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Interactive Horizontal Date Strip
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14,
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index - 3));
                    final isSelected = DateUtils.isSameDay(date, selectedDate);
                    final isCurrentDay = DateUtils.isSameDay(date, DateTime.now());

                    return GestureDetector(
                      onTap: () => taskProvider.setSelectedDate(date),
                      child: Container(
                        width: 54,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isCurrentDay
                                  ? AppColors.primary.withOpacity(0.12)
                                  : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : isCurrentDay
                                    ? AppColors.primaryLight.withOpacity(0.4)
                                    : AppColors.darkBorder,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date).substring(0, 1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),

              // 2. Today's Task List Heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scheduled Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${taskProvider.tasks.where((t) => t.isCompleted).length}/${taskProvider.tasks.length} Done',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentCyan),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (taskProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (taskProvider.tasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.done_all_rounded, size: 40, color: AppColors.emerald),
                      SizedBox(height: 12),
                      Text(
                        'No Tasks Scheduled',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap the "+" button below to add tasks or explore your active Tracks.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                ...taskProvider.tasks.map(
                  (task) => TaskCard(
                    task: task,
                    onToggle: () => taskProvider.toggleTaskStatus(task),
                  ),
                ),

              const SizedBox(height: 28),

              // 3. Analytics Section (Specification 5.4)
              _buildAnalyticsSection(context, analyticsProvider),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, AnalyticsProvider analytics) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Productivity Analytics',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              // Switcher: Weekly / Monthly / Yearly
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: ['weekly', 'monthly', 'yearly'].map((period) {
                    final isSel = analytics.selectedPeriod == period;
                    return GestureDetector(
                      onTap: () => analytics.setPeriod(period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          period[0].toUpperCase() + period.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 4-stat Metrics Grid
          Row(
            children: [
              _buildStatTile('Total Scheduled', '${analytics.totalScheduled}', Icons.assignment_outlined, AppColors.textLight),
              const SizedBox(width: 10),
              _buildStatTile('Completed', '${analytics.completedTasks}', Icons.check_circle_outline, AppColors.emerald),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatTile('Completion Rate', '${analytics.completionPercentage}%', Icons.trending_up, AppColors.accentCyan),
              const SizedBox(width: 10),
              _buildStatTile(
                analytics.selectedPeriod == 'weekly' ? 'Points (Week)' : analytics.selectedPeriod == 'monthly' ? 'Points (Month)' : 'Points (Year)',
                '+${analytics.pointsEarnedPeriod}',
                Icons.military_tech_outlined,
                AppColors.accentGold,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Completion Progress Bar
          const Text('Track Completion Progress', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: analytics.completionPercentage / 100,
              minHeight: 10,
              backgroundColor: AppColors.darkSurface,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 18),

          // Trend Mini-Bars
          if (analytics.trends.isNotEmpty) ...[
            const Text('Completion Trend', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: analytics.trends.map((t) {
                final count = t['completedCount'] as int? ?? 0;
                final height = (count * 12.0).clamp(6.0, 48.0);
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: height,
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.accentCyan : AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${t['label']}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
