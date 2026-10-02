import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../models/drop_off_point.dart';
import '../services/drop_off_service.dart';
import '../widgets/rounded_sheet_body.dart';

class DropOffMapScreen extends StatefulWidget {
  const DropOffMapScreen({super.key});

  @override
  State<DropOffMapScreen> createState() => _DropOffMapScreenState();
}

class _DropOffMapScreenState extends State<DropOffMapScreen> {
  static const _cirestCenter = LatLng(-21.05, 55.70);
  final _service = DropOffService();
  final _mapController = MapController();

  List<DropOffPoint> _all = [];
  DropOffCategory? _filter;
  LatLng? _myPosition;
  bool _loading = true;
  bool _locating = false;
  String? _error;
  final _searchController = TextEditingController();

  List<DropOffPoint> get _visible {
    final filtered = _filter == null
        ? List<DropOffPoint>.from(_all)
        : _all.where((point) => point.matches(_filter!)).toList();

    final here = _myPosition;
    if (here != null) {
      filtered.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    } else {
      filtered.sort((a, b) {
        final byCity = a.city.toLowerCase().compareTo(b.city.toLowerCase());
        if (byCity != 0) return byCity;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });
    }
    return filtered;
  }

  double _distanceTo(DropOffPoint point) {
    final here = _myPosition;
    if (here == null) return double.infinity;
    return Geolocator.distanceBetween(
      here.latitude,
      here.longitude,
      point.latitude,
      point.longitude,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final points = await _service.loadPoints(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _all = points;
        _loading = false;
        if (points.isEmpty) {
          _error = 'Aucun point de collecte trouvé pour le CIREST.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger la carte. Réessaie plus tard.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux'),
        centerTitle: true,
      ),
      body: RoundedSheetBody(
        child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _cirestCenter,
                    initialZoom: 11,
                    minZoom: 9,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.collecte_dechets_app',
                    ),
                    MarkerLayer(
                      markers: _visible
                          .map((point) {
                            final category =
                                _filter ?? point.primaryCategory();
                            return Marker(
                              point: LatLng(point.latitude, point.longitude),
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () => _showPoint(point),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    category.icon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    if (_myPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myPosition!,
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x661565C0),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap'),
                        TextSourceAttribution(
                          'Que faire de mes objets & déchets — ADEME',
                        ),
                      ],
                    ),
                  ],
                ),
                if (_loading)
                  const ColoredBox(
                    color: Color(0x66FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_loading && _error != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Material(
                        color: Colors.white,
                        elevation: 3,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 72,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          _myPosition == null
                              ? '${_visible.length} lieu${_visible.length > 1 ? 'x' : ''} sur le CIREST'
                              : '${_visible.length} lieu${_visible.length > 1 ? 'x' : ''} les plus proches',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Material(
                        color: const Color(0xFF2E7D32),
                        elevation: 3,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Autour de moi',
                          onPressed: _locating ? null : _locateMe,
                          icon: _locating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.white,
                        elevation: 3,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Actualiser',
                          onPressed: _loading
                              ? null
                              : () => _load(forceRefresh: true),
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: _filter == null
                            ? Colors.white
                            : const Color(0xFF2E7D32),
                        elevation: 3,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Filtrer',
                          onPressed: _loading ? null : _showPlacesList,
                          icon: Icon(
                            Icons.filter_list,
                            color: _filter == null
                                ? const Color(0xFF2E7D32)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showMessage('Active le GPS du téléphone pour te localiser.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          'Autorise la localisation pour voir les lieux autour de toi.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final here = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _myPosition = here);
      _fitToNearby(here);
    } catch (_) {
      _showMessage('Impossible de récupérer ta position.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _fitToNearby(LatLng here) {
    final nearby = _visible.take(6).toList();
    if (nearby.isEmpty) {
      _mapController.move(here, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [
          here,
          ...nearby.map((point) => LatLng(point.latitude, point.longitude)),
        ],
        padding: const EdgeInsets.all(48),
        maxZoom: 15,
      ),
    );
  }

  List<DropOffPoint> _placesMatching(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _visible;
    return _visible.where((point) {
      return point.displayName.toLowerCase().contains(q) ||
          point.city.toLowerCase().contains(q) ||
          point.address.toLowerCase().contains(q) ||
          point.postalCode.contains(q) ||
          point.wasteLabels.any((label) => label.toLowerCase().contains(q));
    }).toList();
  }

  void _showPlacesList() {
    _searchController.clear();
    final nearby = _myPosition != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final places = _placesMatching(_searchController.text);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                          nearby
                              ? 'Les plus proches'
                              : 'Lieux de dépôt',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un lieu, une ville…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Effacer',
                                    onPressed: () {
                                      _searchController.clear();
                                      setSheetState(() {});
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          children: [
                            _chip(
                              label: 'Tous',
                              icon: Icons.map_outlined,
                              color: const Color(0xFF2E7D32),
                              selected: _filter == null,
                              onTap: () {
                                setState(() => _filter = null);
                                setSheetState(() {});
                              },
                            ),
                            ...DropOffCategory.values.map(
                              (category) => _chip(
                                label: category.label,
                                icon: category.icon,
                                color: category.color,
                                selected: _filter == category,
                                onTap: () {
                                  setState(() => _filter = category);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: Text(
                          '${places.length} lieu${places.length > 1 ? 'x' : ''}${_filter == null ? '' : ' · ${_filter!.label}'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(
                        child: places.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucun lieu trouvé.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.paddingOf(context).bottom + 12,
                                ),
                                itemCount: places.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final point = places[index];
                                  final category =
                                      _filter ?? point.primaryCategory();
                                  final distance = nearby
                                      ? _formatDistance(_distanceTo(point))
                                      : null;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: category.color,
                                      foregroundColor: Colors.white,
                                      child: Icon(category.icon, size: 20),
                                    ),
                                    title: Text(
                                      point.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: point.city.isEmpty
                                        ? null
                                        : Text(point.city),
                                    trailing: distance == null
                                        ? null
                                        : Text(
                                            distance,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                    onTap: () async {
                                      Navigator.of(sheetContext).pop();
                                      _mapController.move(
                                        LatLng(
                                          point.latitude,
                                          point.longitude,
                                        ),
                                        15,
                                      );
                                      await Future<void>.delayed(
                                        const Duration(milliseconds: 80),
                                      );
                                      if (!mounted) return;
                                      _showPoint(point);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: color,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _showPoint(DropOffPoint point) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final labels = point.wasteLabels;
        final preview = labels.take(12).toList();
        final extra = labels.length - preview.length;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (point.fullAddress.isNotEmpty)
                _infoRow(Icons.place_outlined, point.fullAddress),
              if (point.hours != null)
                _infoRow(Icons.schedule, point.hours!),
              if (point.accessNotes != null)
                _infoRow(Icons.info_outline, point.accessNotes!),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'On peut y déposer',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...preview.map(
                      (label) => Chip(
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFFE8F5E9),
                        side: BorderSide.none,
                      ),
                    ),
                    if (extra > 0)
                      Chip(
                        label: Text('+$extra'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _chooseItinerary(context, point),
                icon: const Icon(Icons.directions),
                label: const Text('Itinéraire'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (point.phone != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _call(point.phone!),
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Source : Que faire de mes objets & déchets — ADEME',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }

  Future<void> _chooseItinerary(
    BuildContext sheetContext,
    DropOffPoint point,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: sheetContext,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ouvrir l\'itinéraire avec',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const _GoogleMapsIcon(),
                  title: const Text('Google Maps'),
                  onTap: () => Navigator.pop(context, 'google'),
                ),
                ListTile(
                  leading: const _WazeIcon(),
                  title: const Text('Waze'),
                  onTap: () => Navigator.pop(context, 'waze'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == 'google') {
      await _openExternal(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
        ),
      );
    } else if (choice == 'waze') {
      final wazeApp = Uri.parse(
        'waze://?ll=${point.latitude},${point.longitude}&navigate=yes',
      );
      if (await canLaunchUrl(wazeApp)) {
        await launchUrl(wazeApp, mode: LaunchMode.externalApplication);
      } else {
        await _openExternal(
          Uri.parse(
            'https://waze.com/ul?ll=${point.latitude},${point.longitude}&navigate=yes',
          ),
        );
      }
    }
  }

  Future<void> _openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _GoogleMapsIcon extends StatelessWidget {
  const _GoogleMapsIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _GoogleMapsPainter()),
    );
  }
}

class _GoogleMapsPainter extends CustomPainter {
  const _GoogleMapsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF1A73E8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white,
    );

    final pin = Path()
      ..moveTo(size.width * 0.5, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.52,
        size.width * 0.5,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.52,
        size.width * 0.5,
        size.height * 0.78,
      )
      ..close();
    canvas.drawPath(pin, Paint()..color = const Color(0xFFEA4335));
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.11,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WazeIcon extends StatelessWidget {
  const _WazeIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _WazePainter()),
    );
  }
}

class _WazePainter extends CustomPainter {
  const _WazePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF33CCFF));

    final face = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.52),
      size.width * 0.28,
      face,
    );
    final eye = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.46), 2.4, eye);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.46), 2.4, eye);
    final smile = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.52),
        width: size.width * 0.28,
        height: size.height * 0.22,
      ),
      0.3,
      2.5,
      false,
      smile,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
