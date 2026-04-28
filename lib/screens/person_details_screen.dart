import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';
import '../utils/formatters.dart';

import 'package:url_launcher/url_launcher.dart';

import 'main_navigation_screen.dart';

class PersonDetailsScreen extends StatefulWidget {
  final String personName;

  const PersonDetailsScreen({super.key, required this.personName});

  @override
  State<PersonDetailsScreen> createState() => _PersonDetailsScreenState();
}

class _PersonDetailsScreenState extends State<PersonDetailsScreen> {
  final currencyFormat = NumberFormat("#,###", "en_US");

  void _showSuccessDialog(double amount, String currency, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String actionText = '';
        if (type == 'payment') actionText = 'qisman to\'lov qo\'shildi';
        else if (type == 'add') actionText = 'qarz qo\'shildi';
        else if (type == 'full') actionText = 'barcha qarzlar to\'landi';

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F7F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 50),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Muvaﬀaqiyatli',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                ),
                const SizedBox(height: 8),
                Text(
                  type == 'full' 
                    ? 'Barcha qarzlar to\'langan deb belgilandi'
                    : '${currencyFormat.format(amount)} ${currency == 'UZS' ? "so'm" : "\$"} $actionText',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('OK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFullPaymentConfirmationDialog(List<Debt> unpaidDebts) async {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF5FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.info, color: Color(0xFF3B82F6), size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'To\'liq to\'lash',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                ),
                const SizedBox(height: 12),
                Text(
                  '"${widget.personName}" uchun barcha qarzni to\'langan deb belgilashni xohlaysizmi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF1A1C1E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final service = Provider.of<DebtService>(context, listen: false);
                            for (var d in unpaidDebts) {
                              service.togglePaid(d.id);
                            }
                            Navigator.pop(context);
                            _showSuccessDialog(0, '', 'full');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _showPartialPaymentDialog(double unpaidUZS, double unpaidUSD) async {
    String selectedCurrency = 'UZS';
    final amountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentUnpaid = selectedCurrency == 'UZS' ? unpaidUZS : unpaidUSD;
            String currencyLabel = selectedCurrency == 'UZS' ? 'SO\'M' : '\$';

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Qisman to\'lov',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Qolgan qarz:',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                    ),
                    Text(
                      '$currencyLabel: ${currencyFormat.format(currentUnpaid.abs())}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, width: 1),
                            ),
                            child: TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ThousandsSeparatorInputFormatter()],
                              decoration: const InputDecoration(
                                hintText: '1,000,000',
                                hintStyle: TextStyle(color: Color(0xFFA1A1A1)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCurrency,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3B82F6)),
                              items: const [
                                DropdownMenuItem(value: 'UZS', child: Text('so\'m', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'USD', child: Text('\$', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (val) {
                                setDialogState(() => selectedCurrency = val!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: const Color(0xFF1A1C1E),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                final amountStr = amountController.text.replaceAll(',', '');
                                final amount = double.tryParse(amountStr) ?? 0;
                                if (amount > 0) {
                                  final type = currentUnpaid >= 0 ? 'Haqqim' : 'Qarzi';
                                  Provider.of<DebtService>(context, listen: false).addPartialPayment(widget.personName, amount, selectedCurrency, type);
                                  Navigator.pop(context);
                                  _showSuccessDialog(amount, selectedCurrency, 'payment');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold)),
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
      },
    );
  }

  Future<void> _showAddDebtDialog(double unpaidUZS, double unpaidUSD) async {
    String selectedCurrency = 'UZS';
    String selectedType = 'Haqqim';
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentUnpaid = selectedCurrency == 'UZS' ? unpaidUZS : unpaidUSD;
            String currencyLabel = selectedCurrency == 'UZS' ? 'SO\'M' : '\$';

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Qarz qo\'shish',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Qolgan qarz:',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                      ),
                      Text(
                        '$currencyLabel: ${currencyFormat.format(currentUnpaid.abs())}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                      ),
                      const SizedBox(height: 24),
                      
                      // Type selection removed


                      // Amount & Currency Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsSeparatorInputFormatter()],
                                decoration: const InputDecoration(
                                  hintText: '1,000,000',
                                  hintStyle: TextStyle(color: Color(0xFFA1A1A1)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCurrency,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3B82F6)),
                                items: const [
                                  DropdownMenuItem(value: 'UZS', child: Text('so\'m', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 'USD', child: Text('\$', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                                ],
                                onChanged: (val) {
                                  setDialogState(() => selectedCurrency = val!);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Reason Input
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: TextField(
                          controller: reasonController,
                          decoration: const InputDecoration(
                            hintText: 'Sabab (masalan: Bozorlik)',
                            hintStyle: TextStyle(color: Color(0xFFA1A1A1)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF1A1C1E),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  final amountStr = amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
                                  final amount = double.tryParse(amountStr) ?? 0;
                                  if (amount > 0) {
                                    Provider.of<DebtService>(context, listen: false).addDebt(Debt(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      name: widget.personName,
                                      amount: amount,
                                      currency: selectedCurrency,
                                      type: selectedType,
                                      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                                      reason: reasonController.text.trim(),
                                    ));
                                    Navigator.pop(context);
                                    _showSuccessDialog(amount, selectedCurrency, 'add');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Tasdiqlash', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeButton({required String label, required bool isSelected, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtService>(
      builder: (context, debtService, _) {
        final allDebts = debtService.debts.where((d) => d.name == widget.personName).toList();
        final unpaidDebts = allDebts.where((d) => !d.isPaid).toList();
        
        double unpaidUZS = 0;
        double unpaidUSD = 0;
        double paidUZS = 0;
        double paidUSD = 0;
        
        for (var d in allDebts) {
          final isHaqqim = d.type == 'Haqqim';
          final amount = isHaqqim ? d.amount : -d.amount;
          if (d.isPaid) {
            if (d.currency == 'UZS') {
              paidUZS += amount.abs();
            } else {
              paidUSD += amount.abs();
            }
          } else {
            if (d.currency == 'UZS') {
              unpaidUZS += amount;
            } else {
              unpaidUSD += amount;
            }
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.personName,
              style: const TextStyle(
                color: Color(0xFF1A1C1E),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Summary Card (Styled like the image)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.personName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (unpaidUZS != 0) ...[
                            Text(
                              'SO\'M: ${unpaidUZS < 0 ? "-" : ""}${currencyFormat.format(unpaidUZS.abs())}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: unpaidUZS >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                          if (unpaidUSD != 0) ...[
                            Text(
                              '\$: ${unpaidUSD < 0 ? "-" : ""}${currencyFormat.format(unpaidUSD.abs())}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: unpaidUSD >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                          if (unpaidUZS == 0 && unpaidUSD == 0)
                            const Text(
                              'SO\'M: 0',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Qolgan qarz',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transaction List (Real data)
                    ...allDebts.map((debt) {
                      final isHaqqim = debt.type == 'Haqqim';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTransactionItem(
                          debt: debt,
                          title: isHaqqim ? 'Haqqim' : 'Qarzi',
                          subTitle: debt.reason?.isNotEmpty == true ? debt.reason : 'Qarz qo\'shildi',
                          date: debt.date,
                          amount: debt.currency == 'UZS' 
                              ? '${currencyFormat.format(debt.amount)} so\'m' 
                              : '\$ ${currencyFormat.format(debt.amount)}',
                          isPayment: debt.isPaid,
                        ),
                      );
                    }).toList(),

                    if (allDebts.isEmpty)
                      const Center(child: Text('Harakatlar mavjud emas')),
                  ],
                ),
              ),
              
              // Bottom Buttons (New Layout from Image)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // Row 1: Qarz qo'shish & Qisman to'lov
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            label: 'Qarz qo\'shish',
                            icon: Icons.add_circle_outline,
                            color: const Color(0xFF3B82F6),
                            onTap: () => _showAddDebtDialog(unpaidUZS, unpaidUSD),
                            height: 80,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            label: 'Qisman to\'lov',
                            icon: Icons.credit_card,
                            color: const Color(0xFFF59E0B),
                            onTap: () => _showPartialPaymentDialog(unpaidUZS, unpaidUSD),
                            height: 80,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: To'liq to'langan & SMS
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildActionCard(
                            label: 'To\'liq to\'langan deb belgilash',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF10B981),
                            onTap: () => _showFullPaymentConfirmationDialog(unpaidDebts),
                            height: 80,
                            isRow: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildActionCard(
                            label: 'SMS',
                            icon: Icons.chat_bubble_outline,
                            color: const Color(0xFF3B82F6),
                            onTap: () async {
                              final phoneDebt = allDebts.firstWhere(
                                (d) => d.phone != null && d.phone!.length > 4,
                                orElse: () => allDebts.first,
                              );
                              
                              if (phoneDebt.phone != null && phoneDebt.phone!.length > 4) {
                                final Uri smsLaunchUri = Uri(
                                  scheme: 'sms',
                                  path: phoneDebt.phone,
                                  queryParameters: <String, String>{
                                    'body': 'Salom ${widget.personName}, qarzlar haqida eslatma...',
                                  },
                                );
                                try {
                                  if (await canLaunchUrl(smsLaunchUri)) {
                                    await launchUrl(smsLaunchUri);
                                  }
                                } catch (e) {
                                  debugPrint('Error: $e');
                                }
                              }
                            },
                            height: 80,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  void _showDebtOptionsMenu(Debt debt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                title: const Text('Tahrirlash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDebtDialog(debt).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                title: const Text('O\'chirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDebtItemConfirmation(debt).then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Bekor qilish', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDebtItemConfirmation(Debt debt) async {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'O\'chirish',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ushbu tranzaksiyani o\'chirishni xohlaysizmi? Bu amalni qaytarib bo\'lmaydi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF1A1C1E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Provider.of<DebtService>(context, listen: false).deleteDebt(debt.id);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('O\'chirish', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _showEditDebtDialog(Debt debt) async {
    String selectedCurrency = debt.currency;
    String selectedType = debt.type;
    final amountController = TextEditingController(text: currencyFormat.format(debt.amount));
    final reasonController = TextEditingController(text: debt.reason ?? '');

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tahrirlash',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                      ),
                      const SizedBox(height: 24),
                      
                      // Type Selection (Haqqim/Qarzi)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              label: 'Haqqim',
                              isSelected: selectedType == 'Haqqim',
                              onTap: () => setDialogState(() => selectedType = 'Haqqim'),
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeButton(
                              label: 'Qarzi',
                              isSelected: selectedType == 'Qarzi',
                              onTap: () => setDialogState(() => selectedType = 'Qarzi'),
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Amount & Currency Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsSeparatorInputFormatter()],
                                decoration: const InputDecoration(
                                  hintText: '1,000,000',
                                  hintStyle: TextStyle(color: Color(0xFFA1A1A1)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCurrency,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3B82F6)),
                                items: const [
                                  DropdownMenuItem(value: 'UZS', child: Text('so\'m', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 'USD', child: Text('\$', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                                ],
                                onChanged: (val) => setDialogState(() => selectedCurrency = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Reason Input
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: TextField(
                          controller: reasonController,
                          decoration: const InputDecoration(
                            hintText: 'Sabab',
                            hintStyle: TextStyle(color: Color(0xFFA1A1A1)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF1A1C1E),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  final amountStr = amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
                                  final amount = double.tryParse(amountStr) ?? 0;
                                  
                                  if (amount > 0) {
                                    Provider.of<DebtService>(context, listen: false).updateDebt(Debt(
                                      id: debt.id,
                                      name: debt.name,
                                      amount: amount,
                                      currency: selectedCurrency,
                                      type: selectedType,
                                      date: debt.date,
                                      reason: reasonController.text.trim(),
                                      isPaid: debt.isPaid,
                                      phone: debt.phone,
                                    ));
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItem({
    required Debt debt,
    required String title,
    String? subTitle,
    required String amount,
    String? date,
    bool isPayment = false,
  }) {
    final isHaqqim = debt.type == 'Haqqim';
    final mainColor = isPayment 
        ? const Color(0xFF059669) 
        : (isHaqqim ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPayment ? const Color(0xFFF1FDF9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPayment ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    if (isPayment) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'To\'langan',
                          style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subTitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showDebtOptionsMenu(debt),
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double height = 110,
    bool isRow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isRow 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 1, 
        onTap: (index) {
          Navigator.of(context).pop();
          MainNavigationScreen.changeTab(index);
        },
        selectedItemColor: const Color(0xFF0056D2),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Qarz qo\'shish'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Umumiy qarzlar'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analitika'),
        ],
      ),
    );
  }
}
