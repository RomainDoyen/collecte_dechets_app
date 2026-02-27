import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'month_editor_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedYear = DateTime.now().year;
  Map<int, int> _eventCounts = {};
  bool _loading = true;

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
    _loadEventCounts();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des collectes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _loadEventCounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur d'année
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

          // Grille des mois
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
                                  count > 0 ? '$count collecte${count > 1 ? 's' : ''}' : 'Aucune',
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
      ),
    );
  }
}
