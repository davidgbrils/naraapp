import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reminder', style: AppTheme.h3),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryContainer),
            onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.outline),
                  const SizedBox(height: 16),
                  Text('Belum ada reminder', style: AppTheme.body.copyWith(color: AppTheme.outline)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Buat Reminder', style: AppTheme.label),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.reminders.length,
            itemBuilder: (context, index) {
              final reminder = provider.reminders[index];
              final title = reminder['title'] as String? ?? '-';
              final date = reminder['date'] as String? ?? '-';
              final isDone = reminder['status'] == 'selesai';
              return Dismissible(
                key: ValueKey('${reminder['title']}-$index'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => provider.removeReminderAt(index),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                ),
                child: GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.alarm_rounded, color: AppTheme.tertiary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTheme.label.copyWith(
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                color: isDone ? AppTheme.outline : AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: AppTheme.body.copyWith(color: AppTheme.outline, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: isDone,
                        onChanged: (_) => provider.toggleReminderStatus(index),
                        activeColor: AppTheme.success,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-reminder'),
        backgroundColor: AppTheme.primaryContainer,
        child: const Icon(Icons.add_rounded, color: AppTheme.onPrimaryContainer),
      ),
    );
  }
}
