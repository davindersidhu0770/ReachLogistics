import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_item_model.dart';
import '../../services/van_loading_service.dart';
import 'van_loading_scanner_screen.dart';

class VanLoadingOrderItemsScreen extends StatefulWidget {
  final int manifestoId;
  final String manifestoDisplay;

  const VanLoadingOrderItemsScreen({
    super.key,
    required this.manifestoId,
    required this.manifestoDisplay,
  });

  @override
  State<VanLoadingOrderItemsScreen> createState() =>
      _VanLoadingOrderItemsScreenState();
}

class _VanLoadingOrderItemsScreenState
    extends State<VanLoadingOrderItemsScreen> {
  final VanLoadingService _service = VanLoadingService();
  late Future<List<OrderItemModel>> _items;

  @override
  void initState() {
    super.initState();
    _items = _service.fetchOrderItems(widget.manifestoId);
  }

  void _refresh() {
    setState(() {
      _items = _service.fetchOrderItems(widget.manifestoId);
    });
  }

  Future<void> _openScanner(List<OrderItemModel> items) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VanLoadingScannerScreen(items: items),
      ),
    );
    if (result == true) _refresh();
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
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.manifestoDisplay.isNotEmpty
              ? widget.manifestoDisplay
              : "Manifesto #${widget.manifestoId}",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<OrderItemModel>>(
        future: _items,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          return Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 120,
                  left: 20,
                  right: 20,
                  bottom: 32,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF4DB6AC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Order Items",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Tap item or use Scan All",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (snapshot.hasData) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => _openScanner(items),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: Color(0xFF00695C), size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Scan All",
                                style: TextStyle(
                                  color: Color(0xFF00695C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// LIST
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00695C)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Items Found",
                          style: TextStyle(
                              fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return GestureDetector(
                          onTap: () => _openScanner(items),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00695C)
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFF00695C),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "#${item.orderItemId}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.productCode.isNotEmpty
                                            ? item.productCode
                                            : "—",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (item.description.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 13,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 2),
                                          Text(
                                            item.location.isNotEmpty
                                                ? item.location
                                                : "No location",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00695C)
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Qty ${item.quantity}",
                                    style: const TextStyle(
                                      color: Color(0xFF00695C),
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
          );
        },
      ),
    );
  }
}