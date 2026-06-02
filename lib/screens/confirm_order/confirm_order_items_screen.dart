import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/confirm_delivery_item_model.dart';
import '../../services/confirm_order_service.dart';
import 'confirm_order_questions_screen.dart';

class ConfirmOrderItemsScreen extends StatefulWidget {
  final int manifestoId;
  final String manifestoDisplay;

  const ConfirmOrderItemsScreen({
    super.key,
    required this.manifestoId,
    required this.manifestoDisplay,
  });

  @override
  State<ConfirmOrderItemsScreen> createState() =>
      _ConfirmOrderItemsScreenState();
}

class _ConfirmOrderItemsScreenState extends State<ConfirmOrderItemsScreen> {
  final ConfirmOrderService _service = ConfirmOrderService();
  late Future<List<ConfirmDeliveryItemModel>> _items;

  @override
  void initState() {
    super.initState();
    _items = _service.fetchDeliveryItems(widget.manifestoId);
  }

  void _refresh() {
    setState(() {
      _items = _service.fetchDeliveryItems(widget.manifestoId);
    });
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
      body: FutureBuilder<List<ConfirmDeliveryItemModel>>(
        future: _items,
        builder: (context, snapshot) {
          return Column(
            children: [
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
                    colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(35)),
                ),
                child: const Column(
                  children: [
                    Text(
                      "Delivery Items",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Select an item to confirm",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6A1B9A)),
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

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Items Found",
                          style:
                              TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfirmOrderQuestionsScreen(
                                  orderId: item.orderId,
                                  orderItemId: item.orderItemId,
                                  description: item.description,
                                  personToDeliver: item.personToDeliver,
                                ),
                              ),
                            );
                            _refresh();
                          },
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
                                    color: const Color(0xFF6A1B9A)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_outlined,
                                    color: Color(0xFF6A1B9A),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productCode.isNotEmpty
                                            ? item.productCode
                                            : "Order #${item.orderId}",
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
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (item.personToDeliver
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline,
                                                size: 13,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 3),
                                            Text(
                                              item.personToDeliver,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF6A1B9A),
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
