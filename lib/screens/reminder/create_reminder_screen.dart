import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class CreateReminderScreen extends StatefulWidget {
  final int? editIndex;

  const CreateReminderScreen({super.key, this.editIndex});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController(text: 'Bayar tagihan listrik');
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedType;
  late bool _isRoutineEnabled;
  late bool _isLinkedToNote;
  late Set<int> _selectedWeekDays;

  final List<Map<String, dynamic>> _types = [
    {'name': 'Notifikasi', 'icon': Icons.notifications_rounded, 'color': AppTheme.primaryContainer},
    {'name': 'Alarm Keras', 'icon': Icons.volume_up_rounded, 'color': AppTheme.tertiary},
    {'name': 'Fullscreen Alert', 'icon': Icons.fullscreen_rounded, 'color': AppTheme.success},
    {'name': 'Fake Call', 'icon': Icons.call_rounded, 'color': AppTheme.danger},
  ];

  final List<Map<String, dynamic>> _weekDays = const [
    {'index': 0, 'label': 'M', 'full': 'Min'},
    {'index': 1, 'label': 'S', 'full': 'Sen'},
    {'index': 2, 'label': 'S', 'full': 'Sel'},
    {'index': 3, 'label': 'R', 'full': 'Rab'},
    {'index': 4, 'label': 'K', 'full': 'Kam'},
    {'index': 5, 'label': 'J', 'full': 'Jum'},
    {'index': 6, 'label': 'S', 'full': 'Sab'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize default values
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 20, minute: 0);
    _selectedType = 'Notifikasi';
    _isRoutineEnabled = false;
    _isLinkedToNote = true;
    _selectedWeekDays = {1, 2, 3, 4, 5};

    // If editing, load existing reminder data
    if (widget.editIndex != null) {
      final provider = context.read<AppProvider>();
      final reminder = provider.reminders[widget.editIndex!];
      
      _titleController.text = reminder['title'] as String? ?? '';
      _noteController.text = reminder['note'] as String? ?? '';
      _selectedType = reminder['type'] as String? ?? 'Notifikasi';
      _isLinkedToNote = reminder['linkedToNote'] as bool? ?? true;
      _isRoutineEnabled = reminder['repeatEnabled'] as bool? ?? false;
      
      // Parse date from date string
      final dateStr = reminder['date'] as String? ?? '';
      if (dateStr.isNotEmpty) {
        try {
          // Try to parse date like "12 Mei 2026 • 20:00"
          final parts = dateStr.split(' • ');
          if (parts.length >= 2) {
            final timeStr = parts[1];
            final timeParts = timeStr.split(':');
            _selectedTime = TimeOfDay(
              hour: int.tryParse(timeParts[0]) ?? 20,
              minute: int.tryParse(timeParts[1]) ?? 0,
            );
          }
        } catch (e) {
          // Keep default if parsing fails
        }
      }
      
      if (reminder['repeatDays'] is List) {
        _selectedWeekDays = Set<int>.from(reminder['repeatDays'] as List);
      }
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatTime(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _saveReminder() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon isi judul reminder', style: AppTheme.body)),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final reminderData = {
      'title': title,
      'type': _selectedType,
      'note': _isLinkedToNote ? _noteController.text.trim() : '',
      'date': '${_formatDate(_selectedDate)} • ${_formatTime(_selectedTime)}',
      'subtitle': '${_formatDate(_selectedDate)} • ${_formatTime(_selectedTime)}',
      'mode': _selectedType,
      'repeatEnabled': _isRoutineEnabled,
      'repeatDays': _selectedWeekDays.toList()..sort(),
      'linkedToNote': _isLinkedToNote,
      'icon': _iconForType(_selectedType),
      'status': 'menunggu',
    };

    if (widget.editIndex != null) {
      // Update existing reminder
      provider.updateReminder(widget.editIndex!, reminderData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder diperbarui', style: AppTheme.body)),
      );
    } else {
      // Add new reminder
      provider.addReminder(reminderData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder dibuat', style: AppTheme.body)),
      );
    }

    Navigator.pop(context);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Alarm Keras':
        return Icons.volume_up_rounded;
      case 'Fullscreen Alert':
        return Icons.fullscreen_rounded;
      case 'Fake Call':
        return Icons.call_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

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
        title: Text(widget.editIndex != null ? 'Edit Reminder' : 'Buat Reminder', style: AppTheme.h3),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: Text('Simpan', style: AppTheme.label.copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.surfaceContainerHigh.withValues(alpha: 0.95),
                    AppTheme.surfaceContainer.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Text(_formatDate(_selectedDate), style: AppTheme.label.copyWith(color: AppTheme.outline)),
                  const SizedBox(height: 8),
                  Text(_formatTime(_selectedTime), style: AppTheme.h1.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.event_rounded, size: 18),
                          label: Text('Ubah Tanggal', style: AppTheme.label.copyWith(color: AppTheme.onSurface)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_rounded, size: 18),
                          label: Text('Ubah Waktu', style: AppTheme.label.copyWith(color: AppTheme.onSurface)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Jenis Peringatan', style: AppTheme.h3),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: _types.map((type) {
                final isSelected = _selectedType == type['name'];
                final color = type['color'] as Color;

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? color : Colors.white.withValues(alpha: 0.04),
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: isSelected ? color : AppTheme.outline,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(type['icon'] as IconData, color: color),
                            ),
                            const SizedBox(height: 12),
                            Text(type['name'] as String, style: AppTheme.label.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleForType(type['name'] as String),
                              style: AppTheme.body.copyWith(color: AppTheme.outline, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Ulangi Rutin', style: AppTheme.h3),
                      ),
                      _InlineToggle(
                        value: _isRoutineEnabled,
                        onChanged: (value) => setState(() => _isRoutineEnabled = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _weekDays.map((day) {
                      final index = day['index'] as int;
                      final isSelected = _selectedWeekDays.contains(index);
                      return GestureDetector(
                        onTap: _isRoutineEnabled
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedWeekDays.remove(index);
                                  } else {
                                    _selectedWeekDays.add(index);
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryContainer : AppTheme.outlineVariant,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            day['label'] as String,
                            style: AppTheme.label.copyWith(
                              color: isSelected ? AppTheme.primary : AppTheme.outline,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Tautkan ke Catatan', style: AppTheme.h3)),
                      _InlineToggle(
                        value: _isLinkedToNote,
                        onChanged: (value) => setState(() => _isLinkedToNote = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    enabled: _isLinkedToNote,
                    maxLines: 2,
                    style: AppTheme.body,
                    decoration: const InputDecoration(
                      hintText: 'Catatan reminder',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: AppTheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Simpan Reminder', style: AppTheme.label.copyWith(color: AppTheme.onPrimaryContainer)),
                    const SizedBox(width: 8),
                    const Icon(Icons.notifications_active_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleForType(String type) {
    switch (type) {
      case 'Alarm Keras':
        return 'Suara maksimal';
      case 'Fullscreen Alert':
        return 'Muncul layar penuh';
      case 'Fake Call':
        return 'Simulasi panggilan';
      default:
        return 'Pesan masuk di layar';
    }
  }
}

class _InlineToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InlineToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppTheme.primaryContainer.withValues(alpha: 0.25) : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? AppTheme.primaryContainer : AppTheme.outlineVariant,
          ),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? AppTheme.primaryContainer : AppTheme.outline,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
