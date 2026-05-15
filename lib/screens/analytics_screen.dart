import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/debt_service.dart';
import '../models/debt_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Analitika',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Debt>>(
        stream: Provider.of<DebtService>(context).debtStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDebts = snapshot.data!;
          // Group by person to calculate net balance
          final Map<String, List<Debt>> personGroups = {};
          for (var d in allDebts) {
            if (!d.isPaid) {
              personGroups.update(d.name, (list) => [...list, d], ifAbsent: () => [d]);
            }
          }

          double totalHaqqimUzs = 0;
          double totalHaqqimUsd = 0;
          int haqqimPeopleCount = 0;

          double totalQarzimUzs = 0;
          double totalQarzimUsd = 0;
          int qarzimPeopleCount = 0;

          personGroups.forEach((name, debts) {
            double netSom = 0;
            double netUsd = 0;

            for (var d in debts) {
              final amount = d.type == 'Haqqim' ? d.amount : -d.amount;
              if (d.currency == 'UZS') {
                netSom += amount;
              } else {
                netUsd += amount;
              }
            }

            if (netSom > 0 || netUsd > 0) {
              if (netSom > 0) totalHaqqimUzs += netSom;
              if (netUsd > 0) totalHaqqimUsd += netUsd;
              haqqimPeopleCount++;
            }
            if (netSom < 0 || netUsd < 0) {
              if (netSom < 0) totalQarzimUzs += netSom.abs();
              if (netUsd < 0) totalQarzimUsd += netUsd.abs();
              qarzimPeopleCount++;
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatCard(
                  title: 'Qarzim',
                  titleColor: const Color(0xFF0056D2),
                  uzsTotal: totalQarzimUzs,
                  usdTotal: totalQarzimUsd,
                  peopleCount: qarzimPeopleCount,
                ),
                const SizedBox(height: 20),
                _buildStatCard(
                  title: 'Haqqim',
                  titleColor: const Color(0xFF0056D2),
                  uzsTotal: totalHaqqimUzs,
                  usdTotal: totalHaqqimUsd,
                  peopleCount: haqqimPeopleCount,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required Color titleColor,
    required double uzsTotal,
    required double usdTotal,
    required int peopleCount,
  }) {
    final format = NumberFormat('#,###', 'uz_UZ');
    
    String formatAmount(double amount) {
      if (amount == 0) return '0';
      return format.format(amount).replaceAll(',', ' ');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildRow('UZS', formatAmount(uzsTotal)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          _buildRow('USD', formatAmount(usdTotal)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),
          _buildRow('Qarzdorlar', '$peopleCount'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1E),
          ),
        ),
      ],
    );
  }
}
