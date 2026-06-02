import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/conditions_model.dart';
import '../../models/container_model.dart';
import '../../services/container_service.dart';
import 'container_items_screen.dart';

class ContainersScreen extends StatefulWidget {
  final DateTime selectedDate;

  const ContainersScreen({super.key, required this.selectedDate});

  @override
  State<ContainersScreen> createState() => _ContainersScreenState();
}

class _ContainersScreenState extends State<ContainersScreen> {
  final ContainerService _service = ContainerService();
  late Future<List<ContainerModel>> _containers;
  late Future<List<ConditionModel>> _conditionsFuture;
  List<ConditionModel> _conditions = [];
  ConditionModel? _selectedCondition;

  @override
  void initState() {
    super.initState();
    _containers = _service.fetchContainers(widget.selectedDate);
    _conditionsFuture = _service.fetchConditions();
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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          "Containers",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                  "Selected Date",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                FutureBuilder<List<ConditionModel>>(
                  future: _conditionsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    _conditions = snapshot.data!;

                    // ✅ Default select first
                    _selectedCondition ??= _conditions.first;

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
                          child: DropdownButton<ConditionModel>(
                            value: _selectedCondition,
                            isExpanded: true,
                            items: _conditions.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Text(e.condition),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCondition = value;
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

          /// CONTAINER LIST
          Expanded(
            child: FutureBuilder<List<ContainerModel>>(
              future: _containers,
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
                      "No Containers Found",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }

                final containers = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: containers.length,
                  itemBuilder: (context, index) {
                    final container = containers[index];

                    return GestureDetector(
                      onTap: () {

                          if (_selectedCondition == null) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContainerItemsScreen(
                                    container: container,
                                    conditionId: _selectedCondition!
                                        .uid, // ✅ pass here
                                  ),
                            ),
                          );
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
                                color: const Color(0xFFFF4D2D)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: Color(0xFFFF4D2D),
                              ),
                            ),

                            const SizedBox(width: 15),

                            /// DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    container.containerNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tap to view items",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// STATUS BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: container.status == "Arrived"
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                container.status,
                                style: TextStyle(
                                  color:
                                  container.status == "Arrived"
                                      ? Colors.green
                                      : Colors.orange,
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