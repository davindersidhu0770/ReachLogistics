import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/container_item_model.dart';
import '../../models/container_model.dart';
import '../../models/location_model.dart';
import '../../services/container_service.dart';
import 'qr_scanner_screen.dart';

class ContainerItemsScreen extends StatefulWidget {
  final ContainerModel container;
  final int conditionId;

  const ContainerItemsScreen({
    super.key,
    required this.container,
    required this.conditionId,
  });

  @override
  State<ContainerItemsScreen> createState() => _ContainerItemsScreenState();
}

class _ContainerItemsScreenState extends State<ContainerItemsScreen> {
  final ContainerService _service = ContainerService();
  late Future<List<ContainerItemModel>> _items;

  late Future<List<LocationModel>> _locationsFuture;
  List<LocationModel> _locations = [];
  LocationModel? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _items = _service.fetchContainerItems(
      widget.container.date,
      widget.container.id,
      widget.conditionId,
    );
    _locationsFuture = _service.fetchLocations();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
        title: Text(
          widget.container.containerNumber,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          /// PREMIUM HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 120,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF4D2D),
                  Color(0xFFFF7A59),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Container Items",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Tap item to scan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<List<LocationModel>>(
                  future: _locationsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    _locations = snapshot.data!;

                    // ✅ default select first
                    _selectedLocation ??= _locations.first;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<LocationModel>(
                            value: _selectedLocation,
                            isExpanded: true,
                            items: _locations.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(e.location),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          /// ITEMS LIST
          Expanded(
            child: FutureBuilder<List<ContainerItemModel>>(
              future: _items,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF4D2D),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Items Found",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                final items = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return GestureDetector(
                      onTap: () async {
                        if (_selectedLocation == null) return;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QRScannerScreen(
                              containerId: widget.container.id,
                              itemId: item.id,
                              itemName: item.name,
                              location: _selectedLocation!.location,
                              conditionId: widget.conditionId,
                              requiredQty: item.quantity,
                            ),
                          ),
                        );

// ✅ Refresh after successful submit
                        if (result == true) {
                          setState(() {
                            _items = _service.fetchContainerItems(
                              widget.container.date,
                              widget.container.id,
                              widget.conditionId,
                            );
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            /// ICON
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D2D).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.qr_code,
                                color: Color(0xFFFF4D2D),
                              ),
                            ),

                            const SizedBox(width: 15),

                            /// ITEM DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Quantity: ${item.quantity}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// SCAN BUTTON STYLE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D2D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Scan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
