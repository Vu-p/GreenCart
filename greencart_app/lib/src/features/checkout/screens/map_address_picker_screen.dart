import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPresetLocation {
  const MapPresetLocation({
    required this.title,
    required this.subtitle,
    required this.latLng,
  });

  final String title;
  final String subtitle;
  final LatLng latLng;
}

class MapAddressPickerScreen extends StatefulWidget {
  const MapAddressPickerScreen({
    super.key,
    this.initialAddress,
  });

  final String? initialAddress;

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  final MapController _mapController = MapController();
  final Dio _dio = Dio();
  final TextEditingController _detailController = TextEditingController();

  LatLng _selectedLatLng = const LatLng(10.7953, 106.7218); // Landmark 81 HCMC
  String _addressText = 'Landmark 81, 720A Điện Biên Phủ, Phường 22, Bình Thạnh, TP. Hồ Chí Minh';
  bool _isLoadingAddress = false;

  final List<MapPresetLocation> _presets = const [
    MapPresetLocation(
      title: '🏢 Landmark 81 Tower',
      subtitle: 'Phường 22, Bình Thạnh, TP.HCM',
      latLng: LatLng(10.7953, 106.7218),
    ),
    MapPresetLocation(
      title: '🌳 Vinhomes Central Park',
      subtitle: '208 Nguyễn Hữu Cảnh, Bình Thạnh',
      latLng: LatLng(10.7925, 106.7214),
    ),
    MapPresetLocation(
      title: '🎓 ĐH KHTN / ĐHQG TP.HCM',
      subtitle: '227 Nguyễn Văn Cừ, Quận 5',
      latLng: LatLng(10.7628, 106.6825),
    ),
    MapPresetLocation(
      title: '🌆 Bitexco Financial Tower',
      subtitle: '2 Hải Triều, Bến Nghé, Quận 1',
      latLng: LatLng(10.7716, 106.7044),
    ),
    MapPresetLocation(
      title: '🛍 KĐT Mới Thủ Thiêm',
      subtitle: 'An Khánh, TP. Thủ Đức',
      latLng: LatLng(10.7719, 106.7196),
    ),
    MapPresetLocation(
      title: '🏡 Khu Thảo Điền Pearl',
      subtitle: '12 Quốc Hương, Thảo Điền, TP. Thủ Đức',
      latLng: LatLng(10.8033, 106.7331),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _detailController.text = widget.initialAddress!;
    } else {
      _detailController.text = _addressText;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressFromCoordinates(LatLng point) async {
    setState(() {
      _selectedLatLng = point;
      _isLoadingAddress = true;
    });

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': point.latitude,
          'lon': point.longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'GreenCartApp/1.0 (contact@greencart.vn)',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          setState(() {
            _addressText = _formatVietnamAddress(displayName);
            _detailController.text = _addressText;
          });
        }
      }
    } catch (e) {
      // Fallback if offline or API limit
      setState(() {
        _addressText = 'Tọa độ: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)} (TP. Hồ Chí Minh)';
        _detailController.text = _addressText;
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  String _formatVietnamAddress(String raw) {
    final parts = raw.split(',').map((p) => p.trim()).toList();
    if (parts.length > 5) {
      return parts.sublist(0, parts.length - 2).join(', ');
    }
    return raw;
  }

  void _onSelectPreset(MapPresetLocation preset) {
    _mapController.move(preset.latLng, 16.5);
    setState(() {
      _selectedLatLng = preset.latLng;
      _addressText = '${preset.title} - ${preset.subtitle}';
      _detailController.text = _addressText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺 Chọn Địa chỉ Giao hàng trên Bản đồ'),
        backgroundColor: const Color(0xFF006A38),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Quick presets banner
          Container(
            color: const Color(0xFFE9F5EE),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '⚡ Điểm giao hàng phổ biến tại TP.HCM (Chọn nhanh):',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006A38),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      final isSelected = _selectedLatLng.latitude == preset.latLng.latitude &&
                          _selectedLatLng.longitude == preset.latLng.longitude;
                      return ActionChip(
                        backgroundColor: isSelected ? const Color(0xFF006A38) : Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF006A38),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                        label: Text(preset.title),
                        onPressed: () => _onSelectPreset(preset),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Interactive Map Area
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLatLng,
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) => _fetchAddressFromCoordinates(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.greencart.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLatLng,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 46,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 16, color: Color(0xFF006A38)),
                        SizedBox(width: 6),
                        Text(
                          'Chạm vào điểm bất kỳ để ghim vị trí',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF006A38)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Address Detail Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
              ],
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_city, color: Color(0xFF006A38)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLoadingAddress ? 'Đang định danh vị trí từ tọa độ...' : 'Địa chỉ đã ghim trên bản đồ:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isLoadingAddress)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detailController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ chi tiết (Có thể bổ sung số phòng/căn hộ)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF006A38), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A38),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      final finalAddress = _detailController.text.trim();
                      if (finalAddress.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(finalAddress);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'Xác nhận địa chỉ giao hàng này',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
