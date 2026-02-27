import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/collection_type.dart';
import '../services/collection_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CollectionEvent> _events = [];
  CollectionEvent? _nextCollection;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
    _loadNextCollection();
  }

  Future<void> _loadEvents() async {
    final events = await CollectionService.getAllCollections();
    print('📅 ${events.length} événements chargés pour le calendrier');
    if (events.isNotEmpty) {
      print('📅 Premier événement: ${events.first.date} - ${events.first.type.name}');
      print('📅 Dernier événement: ${events.last.date} - ${events.last.type.name}');
    }
    setState(() {
      _events = events;
    });
  }

  Future<void> _loadNextCollection() async {
    final nextCollection = await CollectionService.getNextCollection();
    setState(() {
      _nextCollection = nextCollection;
    });
  }

  List<CollectionEvent> _getEventsForDay(DateTime day) {
    // Normaliser les dates pour la comparaison (ignorer l'heure)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final eventsForDay = _events
        .where((event) {
          // Normaliser la date de l'événement (convertir UTC en local si nécessaire)
          final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
          return eventDate.year == normalizedDay.year &&
              eventDate.month == normalizedDay.month &&
              eventDate.day == normalizedDay.day;
        })
        .toList();
    
    if (eventsForDay.isNotEmpty) {
      print('📅 ${eventsForDay.length} événement(s) trouvé(s) pour ${day.day}/${day.month}/${day.year}');
    }
    
    return eventsForDay;
  }

  Color _getColorForCollectionType(CollectionType type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NotiWaste'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
              // Prochaine collecte
            if (_nextCollection != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getColorForCollectionType(_nextCollection!.type),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prochaine collecte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _nextCollection!.type.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nextCollection!.type.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_nextCollection!.date.day}/${_nextCollection!.date.month}/${_nextCollection!.date.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              if (_nextCollection!.notes != null)
                                Text(
                                  _nextCollection!.notes!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Légende
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Légende',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children:
                        CollectionType.values.map((type) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getColorForCollectionType(type),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                type.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            // Calendrier
            Container(
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 7),
              child: TableCalendar<CollectionEvent>(
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2026, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: const Color.fromARGB(255, 53, 150, 66),
                    shape: BoxShape.circle,
                  ),
                  // Couleur de sélection
                  selectedDecoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // Vert principal
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  // Couleur au survol
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF4CAF50), // Vert plus clair
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;

                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            events.take(3).map((event) {
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColorForCollectionType(event.type),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Détails du jour sélectionné
            if (_selectedDay != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 7, 14, 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collectes du ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_getEventsForDay(_selectedDay!).isEmpty
                        ? [
                          const Text(
                            'Aucune collecte prévue ce jour',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ]
                        : _getEventsForDay(_selectedDay!).map((event) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getColorForCollectionType(event.type),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  event.type.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.type.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (event.notes != null)
                                        Text(
                                          event.notes!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
