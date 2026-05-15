import 'package:flutter/material.dart';
import 'oldi_berdi_screen.dart';
import 'totals_screen.dart';
import '../widgets/menu_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Bosh sahifa',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Qaysi bo\'lim bilan ishlashni tanlang',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 40),
                
                // First Row: Oldi-Berdi and Market
                Row(
                  children: [
                    Expanded(
                      child: MenuCard(
                        title: 'Oldi-Berdi',
                        icon: Icons.swap_horiz,
                        iconColor: const Color(0xFF0056D2),
                        iconBackgroundColor: const Color(0xFFE8F0FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OldiBerdiScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: MenuCard(
                        title: 'Market',
                        icon: Icons.store_outlined,
                        iconColor: const Color(0xFFE67E22),
                        iconBackgroundColor: const Color(0xFFFFF4E8),
                        onTap: () {
                          // Navigate to Market
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Second Row: Harajatlar
                MenuCard(
                  title: 'Harajatlar',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF006B5B),
                  iconBackgroundColor: const Color(0xFFE6F5F0),
                  onTap: () {
                    // Navigate to Harajatlar
                  },
                ),
                const SizedBox(height: 20),

                // Third Row: Umumiy qarzlar
                MenuCard(
                  title: 'Umumiy qarzlar',
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TotalsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF0056D2),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Bosh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Sozlamalar',
          ),
        ],
      ),
    );
  }
}
