import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/debt_service.dart';
import '../models/debt_model.dart';
import 'person_details_screen.dart';

class TotalsScreen extends StatefulWidget {
  const TotalsScreen({super.key});

  @override
  State<TotalsScreen> createState() => _TotalsScreenState();
}

class _TotalsScreenState extends State<TotalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDebtType = 'Haqqim';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final currencyFormat = NumberFormat("#,###", "en_US");

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtService>(
      builder: (context, debtService, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Umumiy qarzlar',
              style: TextStyle(
                color: Color(0xFF1A1C1E),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF1A1C1E)),
                onPressed: () {},
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF3B82F6),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: 'To\'lanmaganlar'),
                Tab(text: 'To\'langanlar'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDebtList(debtService, isPaid: false),
              _buildDebtList(debtService, isPaid: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebtList(DebtService debtService, {required bool isPaid}) {
    // 1. Get all debts for the current payment status (Paid/Unpaid)
    final allDebts = debtService.debts.where((d) => d.isPaid == isPaid).toList();

    // 2. Group by name and calculate net balance
    final Map<String, List<Debt>> personGroups = {};
    for (var d in allDebts) {
      personGroups.update(d.name, (list) => [...list, d], ifAbsent: () => [d]);
    }

    final List<Map<String, dynamic>> netBalances = [];
    personGroups.forEach((name, personDebts) {
      double netSom = 0;
      double netUsd = 0;
      int records = 0;

      for (var d in personDebts) {
        final isHaqqim = d.type == 'Haqqim';
        final amount = isHaqqim ? d.amount : -d.amount;
        
        if (d.currency == 'UZS') netSom += amount;
        else netUsd += amount;
        records++;
      }

      // Filter by search query
      if (name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        // Determine if this person belongs to 'Haqqim' or 'Qarzim' tab based on net balance
        // If netSom and netUsd are 0, we use the type of the first debt to decide where to show them
        bool matchesType = false;
        if (_selectedDebtType == 'Haqqim') {
          matchesType = netSom > 0 || netUsd > 0 || (netSom == 0 && netUsd == 0 && personDebts.any((d) => d.type == 'Haqqim'));
        } else {
          matchesType = netSom < 0 || netUsd < 0 || (netSom == 0 && netUsd == 0 && personDebts.any((d) => d.type == 'Qarzim'));
        }

        if (matchesType) {
          netBalances.add({
            'name': name,
            'som': netSom,
            'usd': netUsd,
            'count': records,
          });
        }
      }
    });

    return Column(
      children: [
        _buildFilterSection(),
        // List of People
        Expanded(
          child: netBalances.isEmpty 
            ? Center(child: Text(isPaid ? 'To\'langanlar ro\'yxati bo\'sh' : 'To\'lanmaganlar ro\'yxati bo\'sh'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: netBalances.length,
                itemBuilder: (context, index) {
                  final data = netBalances[index];
                  final name = data['name'];
                  final som = data['som'] as double;
                  final usd = data['usd'] as double;
                  
                  return _buildPersonCard(
                    name, 
                    '${data['count']} ta yozuv', 
                    som: som != 0 ? '${som < 0 ? "-" : ""}${currencyFormat.format(som.abs())}' : null, 
                    usd: usd != 0 ? '${usd < 0 ? "-" : ""}${currencyFormat.format(usd.abs())}' : null,
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Dropdown
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDebtType,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: ['Haqqim', 'Qarzim'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1C1E))),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedDebtType = newValue!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search Field
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Ism bo\'yicha qidiring...',
                hintStyle: TextStyle(color: Color(0xFFA1A1A1), fontSize: 16),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'O\'chirish',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"$name" va uning barcha qarzlarini o\'chirishni xohlaysizmi? Bu amalni qaytarib bo\'lmaydi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Bekor qilish',
                            style: TextStyle(
                              color: Color(0xFF1A1C1E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            DebtService().deletePersonByName(name);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            foregroundColor: const Color(0xFFEF4444),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'O\'chirish',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonCard(String name, String recordCount, {String? som, String? usd}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonDetailsScreen(personName: name),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recordCount,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (som != null)
                    Text(
                      'SO\'M: $som',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  if (usd != null)
                    Text(
                      '\$: $usd',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                offset: const Offset(0, 40),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmationDialog(name);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'O\'chirish',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}




