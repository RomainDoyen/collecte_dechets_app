import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_type.dart';
import '../services/collection_service.dart';
import '../widgets/rounded_sheet_body.dart';

class MonthEditorScreen extends StatefulWidget {
  final int year;
  final int month;

  const MonthEditorScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<MonthEditorScreen> createState() => _MonthEditorScreenState();
}

class _MonthEditorScreenState extends State<MonthEditorScreen> {
  // Map: day number -> list of collection types for that day
  final Map<int, Set<CollectionType>> _selectedDays = {};
  // Existing events from Firestore (to know what to delete/add)
  final Map<int, Set<CollectionType>> _originalDays = {};
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;

  static const List<String> _monthNames = [
    '', 'Janvier', 'Février', 'Mars', 'Avril',
    'Mai', 'Juin', 'Juillet', 'Août',
    'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const List<String> _dayHeaders = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void initState() {
    super.initState();
    _loadExistingEvents();
  }

  int get _daysInMonth {
    return DateTime(widget.year, widget.month + 1, 0).day;
  }

  int get _firstWeekday {
    // 1 = Monday ... 7 = Sunday
    return DateTime(widget.year, widget.month, 1).weekday;
  }

  Future<void> _loadExistingEvents() async {
    setState(() => _loading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('collections')
          .get();

      _selectedDays.clear();
      _originalDays.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        if (date.year != widget.year || date.month != widget.month) continue;

        final typeName = data['type'] as String?;
        if (typeName == null) continue;

        final type = _parseCollectionType(typeName);
        if (type == null) continue;

        _selectedDays.putIfAbsent(date.day, () => {}).add(type);
        _originalDays.putIfAbsent(date.day, () => {}).add(type);
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  CollectionType? _parseCollectionType(String name) {
    for (final type in CollectionType.values) {
      if (type.name == name) return type;
    }
    return null;
  }

  Future<void> _editDay(int day) async {
    final monthName = _monthNames[widget.month];
    final draft = Set<CollectionType>.from(_selectedDays[day] ?? {});

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$day $monthName ${widget.year}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cochez les collectes de ce jour.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ...CollectionType.values.map((type) {
                    final selected = draft.contains(type);
                    final color = _getColorForType(type);
                    return CheckboxListTile(
                      value: selected,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: color,
                      secondary: Icon(type.icon, color: color),
                      title: Text(
                        type.name,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? color : Colors.black87,
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            draft.add(type);
                          } else {
                            draft.remove(type);
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          child: const Text('Valider'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      if (draft.isEmpty) {
        _selectedDays.remove(day);
      } else {
        _selectedDays[day] = draft;
      }
      _hasChanges = !_areEqual(_selectedDays, _originalDays);
    });
  }

  bool _areEqual(Map<int, Set<CollectionType>> a, Map<int, Set<CollectionType>> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!a[key]!.containsAll(b[key]!) || !b[key]!.containsAll(a[key]!)) return false;
    }
    return true;
  }

  Color _getColorForType(CollectionType type) {
    switch (type) {
      case CollectionType.orduresMenageres:
        return Colors.grey[600]!;
      case CollectionType.collecteSelective:
        return Colors.yellow[700]!;
      case CollectionType.dechetsVerts:
        return Colors.green[600]!;
      case CollectionType.encombrants:
        return Colors.red[600]!;
      case CollectionType.dechetsMetalliques:
        return Colors.blue[600]!;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 1. Delete all existing events for this month
      final snapshot = await firestore.collection('collections').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        if (date.year == widget.year && date.month == widget.month) {
          batch.delete(doc.reference);
        }
      }

      // 2. Add all selected events
      for (final entry in _selectedDays.entries) {
        final day = entry.key;
        final types = entry.value;
        final date = DateTime(widget.year, widget.month, day);

        for (final type in types) {
          final docRef = firestore.collection('collections').doc();
          batch.set(docRef, {
            'date': date.toIso8601String(),
            'type': type.name,
            'notes': null,
            'isHoliday': false,
            'isCatchUp': false,
          });
        }
      }

      await batch.commit();

      // Invalidate the cache so calendar refreshes
      CollectionService.clearCache();

      // Update original to match current
      _originalDays.clear();
      for (final entry in _selectedDays.entries) {
        _originalDays[entry.key] = Set.from(entry.value);
      }

      if (mounted) {
        setState(() {
          _saving = false;
          _hasChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collectes enregistrées !'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      Navigator.of(context).pop(!_areEqual(_selectedDays, _originalDays));
      return false;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text('Voulez-vous enregistrer avant de quitter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Abandonner'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _save();
      if (mounted) Navigator.of(context).pop(true);
    } else if (result == 'discard') {
      if (mounted) Navigator.of(context).pop(false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_monthNames[widget.month]} ${widget.year}'),
          centerTitle: true,
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _saving ? 'Enregistrement...' : 'Enregistrer',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: RoundedSheetBody(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(child: _buildCalendarGrid()),
                    _buildSummaryBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Day headers
          Row(
            children: _dayHeaders.map((header) {
              return Expanded(
                child: Center(
                  child: Text(
                    header,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Day cells
          Expanded(
            child: _buildDayCells(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCells() {
    final totalSlots = _firstWeekday - 1 + _daysInMonth;
    final rows = (totalSlots / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Expanded(
          child: Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final day = index - (_firstWeekday - 1) + 1;

              if (day < 1 || day > _daysInMonth) {
                return const Expanded(child: SizedBox());
              }

              return Expanded(child: _buildDayCell(day));
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(int day) {
    final types = _selectedDays[day] ?? {};
    final hasCollections = types.isNotEmpty;
    final today = DateTime.now();
    final isToday = today.year == widget.year &&
        today.month == widget.month &&
        today.day == day;

    return GestureDetector(
      onTap: () => _editDay(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: hasCollections ? Colors.grey[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? const Color(0xFF2E7D32)
                : hasCollections
                    ? Colors.grey[400]!
                    : Colors.grey[300]!,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
            if (types.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: types.take(3).map((type) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _getColorForType(type),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    int totalEvents = 0;
    for (final types in _selectedDays.values) {
      totalEvents += types.length;
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalEvents collecte${totalEvents > 1 ? 's' : ''} ce mois',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_hasChanges)
                  const Text(
                    'Modifications non enregistrées',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (_hasChanges)
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
            ),
        ],
      ),
    );
  }
}
