import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../api_service.dart';
import '../../models/sameday_ooh_location.dart';

class EasyboxMap extends StatefulWidget {
  final SamedayOohLocation? initialSelection;

  final ValueChanged<SamedayOohLocation> onSelected;

  const EasyboxMap({
    super.key,
    this.initialSelection,
    required this.onSelected,
  });

  @override
  State<EasyboxMap> createState() => _EasyboxMapState();
}

class _EasyboxMapState extends State<EasyboxMap> {
  // ==========================================================
  // GOOGLE MAP
  // ==========================================================

  GoogleMapController? _mapController;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(45.9432, 24.9668),
    zoom: 6.4,
  );

  bool _programmaticCameraMove = false;

  // ==========================================================
  // CLUSTERING
  // ==========================================================

  static const ClusterManagerId _easyboxClusterId = ClusterManagerId(
    'sameday_easyboxes',
  );

  late final Set<ClusterManager> _clusterManagers;

  // ==========================================================
  // SEARCH
  // ==========================================================

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  List<SamedayOohLocation> _searchResults = [];

  // ==========================================================
  // DATA
  // ==========================================================

  List<SamedayOohLocation> _easyboxes = [];

  List<SamedayOohLocation> _visibleEasyboxes = [];

  SamedayOohLocation? _selectedEasybox;

  bool _showSearchThisArea = false;

  bool _loading = true;

  String? _error;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _selectedEasybox = widget.initialSelection;

    _clusterManagers = {
      ClusterManager(
        clusterManagerId: _easyboxClusterId,
        onClusterTap: _onClusterTap,
      ),
    };

    _loadEasyboxes();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _mapController?.dispose();

    _searchController.dispose();

    _searchFocusNode.dispose();

    super.dispose();
  }

  // ==========================================================
  // NORMALIZE SEARCH
  // ==========================================================

  String _normalizeSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't')
        .trim();
  }

  // ==========================================================
  // SEARCH CHANGED
  // ==========================================================

  void _onSearchChanged(String value) {
    final query = _normalizeSearch(value);

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });

      return;
    }

    final results = _easyboxes
        .where((easybox) {
          final searchable = _normalizeSearch(
            [
              easybox.name,
              easybox.city,
              easybox.county,
              easybox.address,
              easybox.postalCode ?? '',
            ].join(' '),
          );

          return searchable.contains(query);
        })
        .take(8)
        .toList();

    setState(() {
      _searchResults = results;

      _showSearchThisArea = false;
    });
  }

  // ==========================================================
  // SELECT SEARCH RESULT
  // ==========================================================

  Future<void> _selectSearchResult(SamedayOohLocation easybox) async {
    _searchController.text = easybox.name;

    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );

    _searchFocusNode.unfocus();

    setState(() {
      _searchResults = [];

      _selectedEasybox = easybox;

      _showSearchThisArea = false;

      if (!_visibleEasyboxes.any((item) => item.oohId == easybox.oohId)) {
        _visibleEasyboxes = [..._visibleEasyboxes, easybox];
      }
    });

    await _moveToEasybox(easybox, zoom: 16);
  }

  // ==========================================================
  // SUBMIT SEARCH
  // ==========================================================

  Future<void> _submitSearch(String value) async {
    if (_searchResults.isEmpty) {
      return;
    }

    await _selectSearchResult(_searchResults.first);
  }

  // ==========================================================
  // CLEAR SEARCH
  // ==========================================================

  void _clearSearch() {
    _searchController.clear();

    _searchFocusNode.unfocus();

    setState(() {
      _searchResults = [];
    });
  }

  // ==========================================================
  // CLOSE SEARCH RESULTS
  // ==========================================================

  void _dismissSearchResults() {
    if (_searchResults.isEmpty && !_searchFocusNode.hasFocus) {
      return;
    }

    _searchFocusNode.unfocus();

    setState(() {
      _searchResults = [];
    });
  }

  // ==========================================================
  // LOAD EASYBOXES
  // ==========================================================

  Future<void> _loadEasyboxes() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final easyboxes = await ApiService.getAllSamedayEasyboxes();

      final filtered = easyboxes.where((easybox) {
        if (!easybox.isEasybox) {
          return false;
        }

        if (!easybox.isVisible) {
          return false;
        }

        if (easybox.lat == 0 || easybox.lng == 0) {
          return false;
        }

        return true;
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _easyboxes = filtered;

        _visibleEasyboxes = List<SamedayOohLocation>.from(filtered);
      });

      final initial = _selectedEasybox;

      if (initial != null) {
        await _moveToEasybox(initial, zoom: 16);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Nu am putut încărca Easybox-urile.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================
  // SEARCH THIS AREA
  // ==========================================================

  Future<void> _searchThisArea() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    try {
      final bounds = await controller.getVisibleRegion();

      final results = _easyboxes.where((easybox) {
        final lat = easybox.lat;

        final lng = easybox.lng;

        final insideLatitude =
            lat >= bounds.southwest.latitude &&
            lat <= bounds.northeast.latitude;

        final insideLongitude =
            lng >= bounds.southwest.longitude &&
            lng <= bounds.northeast.longitude;

        return insideLatitude && insideLongitude;
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _visibleEasyboxes = results;

        _showSearchThisArea = false;

        _searchResults = [];
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nu am găsit Easybox-uri în această zonă.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu am putut căuta în această zonă.')),
      );
    }
  }

  // ==========================================================
  // MARKERS
  // ==========================================================

  Set<Marker> get _markers {
    return _visibleEasyboxes.map((easybox) {
      final selected = _selectedEasybox?.oohId == easybox.oohId;

      return Marker(
        markerId: MarkerId(easybox.oohId.toString()),

        clusterManagerId: _easyboxClusterId,

        position: LatLng(easybox.lat, easybox.lng),

        zIndexInt: selected ? 10 : 1,

        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
        ),

        infoWindow: InfoWindow(
          title: easybox.name,

          snippet: easybox.fullAddress,
        ),

        onTap: () => _selectEasybox(easybox),
      );
    }).toSet();
  }

  // ==========================================================
  // MAP CREATED
  // ==========================================================

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    final selected = _selectedEasybox;

    if (selected != null) {
      await _moveToEasybox(selected, zoom: 16);
    }
  }

  // ==========================================================
  // CAMERA MOVE STARTED
  // ==========================================================

  void _onCameraMoveStarted() {
    _dismissSearchResults();

    if (_programmaticCameraMove) {
      return;
    }

    if (!_showSearchThisArea && mounted) {
      setState(() {
        _showSearchThisArea = true;
      });
    }
  }

  // ==========================================================
  // SELECT EASYBOX
  // ==========================================================

  Future<void> _selectEasybox(SamedayOohLocation easybox) async {
    _searchFocusNode.unfocus();

    setState(() {
      _selectedEasybox = easybox;

      _searchResults = [];
    });

    await _moveToEasybox(easybox, zoom: 16);
  }

  // ==========================================================
  // MOVE CAMERA
  // ==========================================================

  Future<void> _moveToEasybox(
    SamedayOohLocation easybox, {
    double zoom = 15,
  }) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    _programmaticCameraMove = true;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(easybox.lat, easybox.lng), zoom: zoom),
        ),
      );
    } finally {
      _programmaticCameraMove = false;
    }
  }

  // ==========================================================
  // CLUSTER TAP
  // ==========================================================

  Future<void> _onClusterTap(Cluster cluster) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    _programmaticCameraMove = true;

    try {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(cluster.bounds, 70),
        );
      } catch (_) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(cluster.position, 13),
        );
      }
    } finally {
      _programmaticCameraMove = false;
    }
  }

  // ==========================================================
  // CONFIRM
  // ==========================================================

  void _confirmSelection() {
    final selected = _selectedEasybox;

    if (selected == null) {
      return;
    }

    if (selected.isCapacityExceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acest Easybox nu este disponibil momentan.'),
        ),
      );

      return;
    }

    widget.onSelected(selected);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_easyboxes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nu există Easybox-uri disponibile.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // ====================================================
        // GOOGLE MAP
        // ====================================================

        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: _initialCameraPosition,

            mapType: MapType.normal,

            onMapCreated: _onMapCreated,

            onCameraMoveStarted: _onCameraMoveStarted,

            onTap: (_) {
              _dismissSearchResults();
            },

            markers: _markers,

            clusterManagers: _clusterManagers,

            compassEnabled: true,

            mapToolbarEnabled: false,

            zoomControlsEnabled: false,

            myLocationEnabled: false,

            myLocationButtonEnabled: false,

            buildingsEnabled: true,

            trafficEnabled: false,

            minMaxZoomPreference: const MinMaxZoomPreference(5, 20),

            padding: EdgeInsets.fromLTRB(
              0,
              76,
              0,
              _selectedEasybox != null ? 190 : 16,
            ),
          ),
        ),

        // ====================================================
        // SEARCH THIS AREA
        // ====================================================
        if (_showSearchThisArea &&
            !_searchFocusNode.hasFocus &&
            _searchResults.isEmpty)
          Positioned(
            top: 78,

            left: 0,

            right: 0,

            child: Center(
              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: _searchThisArea,

                  borderRadius: BorderRadius.circular(24),

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),

                    decoration: BoxDecoration(
                      color: colors.surface,

                      borderRadius: BorderRadius.circular(24),

                      border: Border.all(color: colors.outlineVariant),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),

                          blurRadius: 12,

                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        Icon(
                          Icons.search_rounded,

                          size: 19,

                          color: colors.primary,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          'Caută în această zonă',

                          style: TextStyle(
                            color: colors.onSurface,

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ====================================================
        // SELECTED EASYBOX
        // ====================================================
        if (_selectedEasybox != null)
          Positioned(
            left: 12,

            right: 12,

            bottom: 12,

            child: _buildSelectedCard(_selectedEasybox!),
          ),

        // ====================================================
        // SEARCH BAR
        // ====================================================
        Positioned(
          top: 12,

          left: 12,

          right: 12,

          child: Column(
            children: [
              Material(
                elevation: 5,

                borderRadius: BorderRadius.circular(16),

                child: TextField(
                  controller: _searchController,

                  focusNode: _searchFocusNode,

                  onChanged: _onSearchChanged,

                  onSubmitted: _submitSearch,

                  textInputAction: TextInputAction.search,

                  decoration: InputDecoration(
                    hintText: 'Caută oraș, stradă sau Easybox',

                    prefixIcon: const Icon(Icons.search_rounded),

                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: _clearSearch,

                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,

                    filled: true,

                    fillColor: colors.surface,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),

                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),

                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),

                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),

                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // ==============================================
              // SEARCH RESULTS
              // ==============================================
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),

                  constraints: const BoxConstraints(maxHeight: 310),

                  decoration: BoxDecoration(
                    color: colors.surface,

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: colors.outlineVariant),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),

                        blurRadius: 16,

                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: ListView.separated(
                    shrinkWrap: true,

                    padding: const EdgeInsets.symmetric(vertical: 6),

                    itemCount: _searchResults.length,

                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: colors.outlineVariant),

                    itemBuilder: (context, index) {
                      final easybox = _searchResults[index];

                      return ListTile(
                        leading: Container(
                          width: 40,

                          height: 40,

                          decoration: BoxDecoration(
                            color: colors.primaryContainer,

                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Icon(
                            Icons.inventory_2_outlined,

                            color: colors.primary,

                            size: 21,
                          ),
                        ),

                        title: Text(
                          easybox.name,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),

                        subtitle: Text(
                          easybox.fullAddress,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,
                        ),

                        trailing: const Icon(Icons.chevron_right_rounded),

                        onTap: () => _selectSearchResult(easybox),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SELECTED CARD
  // ==========================================================

  Widget _buildSelectedCard(SamedayOohLocation easybox) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final unavailable = easybox.isCapacityExceeded;

    return Material(
      color: Colors.transparent,

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: colors.surface,

          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),

              blurRadius: 20,

              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  width: 44,

                  height: 44,

                  decoration: BoxDecoration(
                    color: colors.primaryContainer,

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Icon(
                    Icons.inventory_2_outlined,

                    color: colors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        easybox.name,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        easybox.fullAddress,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                      if (unavailable) ...[
                        const SizedBox(height: 6),

                        const Text(
                          'Indisponibil momentan',

                          style: TextStyle(
                            color: Colors.red,

                            fontWeight: FontWeight.w700,

                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,

              height: 48,

              child: FilledButton.icon(
                onPressed: unavailable ? null : _confirmSelection,

                icon: const Icon(Icons.check_circle_outline),

                label: const Text('Alege acest Easybox'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.map_outlined, size: 60),

            const SizedBox(height: 16),

            Text(
              _error ?? 'Nu am putut încărca harta.',

              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: _loadEasyboxes,

              icon: const Icon(Icons.refresh),

              label: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }
}
