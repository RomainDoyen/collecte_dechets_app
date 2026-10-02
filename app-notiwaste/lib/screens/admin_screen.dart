import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'month_editor_screen.dart';
import '../services/notifications.dart';
import '../services/reminder_settings.dart';
import '../widgets/rounded_sheet_body.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _selectedYear = DateTime.now().year;
  Map<int, int> _eventCounts = {};
  bool _loading = true;
  ReminderSettings _reminder = const ReminderSettings();
  ReminderSettings _savedReminder = const ReminderSettings();
  bool _reminderSaving = false;

  bool get _hasReminderChanges =>
      _reminder.hour != _savedReminder.hour ||
      _reminder.minute != _savedReminder.minute;

  static const List<String> _monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril',
    'Mai', 'Juin', 'Juillet', 'Août',
    'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const List<IconData> _monthIcons = [
    Icons.ac_unit, Icons.water_drop, Icons.eco, Icons.local_florist,
    Icons.wb_sunny, Icons.beach_access, Icons.wb_sunny, Icons.park,
    Icons.forest, Icons.cloud, Icons.umbrella, Icons.celebration,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _loadEventCounts();
    _loadReminderTime();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadReminderTime() async {
    final settings = await ReminderSettings.load();
    if (!mounted) return;
    setState(() {
      _reminder = settings;
      _savedReminder = settings;
    });
  }

  Future<void> _pickReminderTime() async {
    if (_reminderSaving) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
      helpText: 'Heure de rappel (veille)',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _reminder = ReminderSettings(hour: picked.hour, minute: picked.minute);
    });
  }

  Future<void> _saveReminderChanges() async {
    if (_reminderSaving || !_hasReminderChanges) return;

    setState(() => _reminderSaving = true);
    try {
      await _reminder.save();
      await Notifications.scheduleAll();
      if (!mounted) return;
      setState(() => _savedReminder = _reminder);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rappels enregistrés à ${_reminder.formatted}'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _reminderSaving = false);
      }
    }
  }

  Future<void> _loadEventCounts() async {
    setState(() => _loading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('collections')
          .get();

      final counts = <int, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null || date.year != _selectedYear) continue;

        counts[date.month] = (counts[date.month] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _eventCounts = counts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openMonthEditor(int month) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MonthEditorScreen(
          year: _selectedYear,
          month: month,
        ),
      ),
    );

    if (result == true) {
      _loadEventCounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReminderTab = _tabs.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion'),
        centerTitle: true,
        actions: [
          if (!isReminderTab)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              onPressed: _loadEventCounts,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active), text: 'Rappels'),
            Tab(icon: Icon(Icons.edit_calendar), text: 'Collectes'),
          ],
        ),
      ),
      body: RoundedSheetBody(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildReminderTab(),
            _buildCollectionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        const Text(
          'Heure de rappel',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'La notification est envoyée la veille de chaque collecte, à l\'heure choisie.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        Material(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _pickReminderTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Touchez pour modifier',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reminder.formatted,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _hasReminderChanges && !_reminderSaving
              ? _saveReminderChanges
              : null,
          icon: _reminderSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            _reminderSaving
                ? 'Enregistrement...'
                : 'Enregistrer les modifications',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() => _selectedYear--);
                  _loadEventCounts();
                },
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() => _selectedYear++);
                  _loadEventCounts();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final count = _eventCounts[month] ?? 0;
                    final hasEvents = count > 0;

                    return Material(
                      borderRadius: BorderRadius.circular(16),
                      color: hasEvents
                          ? const Color(0xFF2E7D32).withOpacity(0.1)
                          : Colors.grey[100],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openMonthEditor(month),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasEvents
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[300]!,
                              width: hasEvents ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _monthIcons[index],
                                size: 28,
                                color: hasEvents
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[500],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _monthNames[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: hasEvents
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                count > 0
                                    ? '$count collecte${count > 1 ? 's' : ''}'
                                    : 'Aucune',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasEvents
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
