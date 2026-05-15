import 'package:flutter/material.dart';
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
        if (type == 'payment') {
          actionText = 'qisman to\'lov qo\'shildi';
        } else if (type == 'add') {
          actionText = 'qarz qo\'shildi';
        } else if (type == 'full') {
          actionText = 'barcha qarzlar to\'landi';
        } else if (type == 'products') {
          actionText = 'mahsulotlar qo\'shildi';
        }

        String displayText;
        if (type == 'full') {
          displayText = 'Barcha qarzlar to\'langan deb belgilandi';
        } else if (type == 'products') {
          displayText = 'Mahsulotlar muvaffaqiyatli qo\'shildi';
        } else {
          displayText = '${currencyFormat.format(amount)} ${currency == 'UZS' ? "so'm" : "\$"} $actionText';
        }

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
                  displayText,
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
    final List<ProductEditRow> productRows = [];

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentUnpaid = selectedCurrency == 'UZS' ? unpaidUZS : unpaidUSD;
            String currencyLabel = selectedCurrency == 'UZS' ? 'SO\'M' : '\$';
            
            // Calculate total from products if any (grouped by currency)
            double productsTotalUZS = 0;
            double productsTotalUSD = 0;
            if (productRows.isNotEmpty) {
              for (var r in productRows) {
                r._updateTotal();
                if (r.currency == 'UZS') {
                  productsTotalUZS += r.total;
                } else {
                  productsTotalUSD += r.total;
                }
              }
              
              double productsTotal = selectedCurrency == 'UZS' ? productsTotalUZS : productsTotalUSD;
              String formatted = currencyFormat.format(productsTotal).replaceAll(',', ' ');
              if (amountController.text != formatted && productsTotal > 0) {
                amountController.text = formatted;
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Qisman to\'lov',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                        ),
                        Text(
                          'Qolgan qarzlar:',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMiniBalanceCard(
                              label: 'SO\'M',
                              amount: unpaidUZS,
                              color: unpaidUZS >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 12),
                            _buildMiniBalanceCard(
                              label: 'USD',
                              amount: unpaidUSD,
                              color: unpaidUSD >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Mahsulotlar Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mahsulotlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  productRows.add(ProductEditRow(name: '', quantity: 1, price: 0));
                                });
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Qo\'shish'),
                            ),
                          ],
                        ),

                        if (productRows.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...List.generate(productRows.length, (index) {
                            final row = productRows[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: row.nameController,
                                          decoration: const InputDecoration(
                                            hintText: 'Nomi',
                                            isDense: true,
                                            border: UnderlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                                        onPressed: () => setDialogState(() => productRows.removeAt(index)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: TextField(
                                          controller: row.quantityController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setDialogState(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Soni',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: row.priceController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                                          onChanged: (_) => setDialogState(() {}),
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            labelText: 'Narxi',
                                            labelStyle: const TextStyle(fontSize: 12),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        initialValue: row.currency,
                                        padding: EdgeInsets.zero,
                                        onSelected: (String value) {
                                          setDialogState(() {
                                            row.currency = value;
                                          });
                                        },
                                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'UZS',
                                            child: Text('UZS (so\'m)'),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'USD',
                                            child: Text('USD (\$)'),
                                          ),
                                        ],
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                          margin: const EdgeInsets.only(top: 12),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                row.currency == 'UZS' ? "so'm" : r'$',
                                                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 14),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: productRows.isNotEmpty ? Colors.grey.shade100 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                ),
                                child: TextField(
                                  controller: amountController,
                                  enabled: productRows.isEmpty,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  decoration: const InputDecoration(
                                    hintText: 'Summa',
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
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildCurrencyToggle('UZS', 'so\'m', selectedCurrency == 'UZS', (val) => setDialogState(() => selectedCurrency = val)),
                                  _buildCurrencyToggle('USD', '\$', selectedCurrency == 'USD', (val) => setDialogState(() => selectedCurrency = val)),
                                ],
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
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
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
                                      
                                      final products = productRows.map((r) => Product(
                                        name: r.nameController.text.trim(),
                                        quantity: double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 0,
                                        price: double.tryParse(r.priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                                        currency: r.currency,
                                      )).where((p) => p.name.isNotEmpty).toList();

                                      if (products.isNotEmpty) {
                                        final uzsProducts = products.where((p) => p.currency == 'UZS').toList();
                                        final usdProducts = products.where((p) => p.currency == 'USD').toList();
                                        final groupId = DateTime.now().millisecondsSinceEpoch.toString();

                                        if (uzsProducts.isNotEmpty) {
                                          final totalUZS = uzsProducts.fold(0.0, (sum, p) => sum + p.total);
                                          final type = unpaidUZS >= 0 ? 'Haqqim' : 'Qarzi';
                                          Provider.of<DebtService>(context, listen: false).addPartialPayment(
                                            widget.personName, totalUZS, 'UZS', type, products: uzsProducts, groupId: groupId, idSuffix: "_uzs");
                                        }

                                        if (usdProducts.isNotEmpty) {
                                          final totalUSD = usdProducts.fold(0.0, (sum, p) => sum + p.total);
                                          final type = unpaidUSD >= 0 ? 'Haqqim' : 'Qarzi';
                                          Provider.of<DebtService>(context, listen: false).addPartialPayment(
                                            widget.personName, totalUSD, 'USD', type, products: usdProducts, groupId: groupId, idSuffix: "_usd");
                                        }
                                        
                                        Navigator.pop(context);
                                        _showSuccessDialog(0, selectedCurrency, 'products');
                                      } else if (amount > 0) {
                                        final type = currentUnpaid >= 0 ? 'Haqqim' : 'Qarzi';
                                        Provider.of<DebtService>(context, listen: false).addPartialPayment(
                                          widget.personName, amount, selectedCurrency, type, products: null);
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
    final List<ProductEditRow> productRows = [];

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double currentUnpaid = selectedCurrency == 'UZS' ? unpaidUZS : unpaidUSD;
            String currencyLabel = selectedCurrency == 'UZS' ? 'SO\'M' : '\$';
            
            // Calculate total from products if any (grouped by currency)
            double productsTotalUZS = 0;
            double productsTotalUSD = 0;
            if (productRows.isNotEmpty) {
              for (var r in productRows) {
                r._updateTotal();
                if (r.currency == 'UZS') {
                  productsTotalUZS += r.total;
                } else {
                  productsTotalUSD += r.total;
                }
              }
              
              double productsTotal = selectedCurrency == 'UZS' ? productsTotalUZS : productsTotalUSD;
              String formatted = currencyFormat.format(productsTotal).replaceAll(',', ' ');
              if (amountController.text != formatted && productsTotal > 0) {
                amountController.text = formatted;
              } else if (productsTotal == 0 && amountController.text.isNotEmpty && productRows.isNotEmpty) {
                amountController.text = '';
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeButton(
                                label: 'Haqqim',
                                isSelected: selectedType == 'Haqqim',
                                color: const Color(0xFF3B82F6),
                                onTap: () => setDialogState(() => selectedType = 'Haqqim'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTypeButton(
                                label: 'Qarzi',
                                isSelected: selectedType == 'Qarzi',
                                color: const Color(0xFFEF4444),
                                onTap: () => setDialogState(() => selectedType = 'Qarzi'),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Qolgan qarzlar:',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMiniBalanceCard(
                              label: 'SO\'M',
                              amount: unpaidUZS,
                              color: unpaidUZS >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 12),
                            _buildMiniBalanceCard(
                              label: 'USD',
                              amount: unpaidUSD,
                              color: unpaidUSD >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Mahsulotlar Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mahsulotlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  productRows.add(ProductEditRow(name: '', quantity: 1, price: 0));
                                });
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Qo\'shish'),
                            ),
                          ],
                        ),
                        
                        if (productRows.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ...List.generate(productRows.length, (index) {
                            final row = productRows[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: row.nameController,
                                          decoration: const InputDecoration(
                                            hintText: 'Nomi',
                                            isDense: true,
                                            border: UnderlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                                        onPressed: () => setDialogState(() => productRows.removeAt(index)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: TextField(
                                          controller: row.quantityController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setDialogState(() {}),
                                          decoration: const InputDecoration(
                                            labelText: 'Soni',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextField(
                                          controller: row.priceController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                                          onChanged: (_) => setDialogState(() {}),
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            labelText: 'Narxi',
                                            labelStyle: const TextStyle(fontSize: 12),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        initialValue: row.currency,
                                        padding: EdgeInsets.zero,
                                        onSelected: (String value) {
                                          setDialogState(() {
                                            row.currency = value;
                                          });
                                        },
                                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'UZS',
                                            child: Text('UZS (so\'m)'),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'USD',
                                            child: Text('USD (\$)'),
                                          ),
                                        ],
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                          margin: const EdgeInsets.only(top: 12),
                                          decoration: BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                row.currency == 'UZS' ? "so'm" : r'$',
                                                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 14),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                        ],

                        // Amount & Currency Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: productRows.isNotEmpty ? Colors.grey.shade100 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                ),
                                child: TextField(
                                  controller: amountController,
                                  enabled: productRows.isEmpty,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  decoration: const InputDecoration(
                                    hintText: 'Summa',
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
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildCurrencyToggle('UZS', 'so\'m', selectedCurrency == 'UZS', (val) => setDialogState(() => selectedCurrency = val), activeColor: selectedType == 'Haqqim' ? const Color(0xFF3B82F6) : const Color(0xFFEF4444)),
                                  _buildCurrencyToggle('USD', '\$', selectedCurrency == 'USD', (val) => setDialogState(() => selectedCurrency = val), activeColor: selectedType == 'Haqqim' ? const Color(0xFF3B82F6) : const Color(0xFFEF4444)),
                                ],
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
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
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
                                      
                                      final products = productRows.map((r) => Product(
                                        name: r.nameController.text.trim(),
                                        quantity: double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 0,
                                        price: double.tryParse(r.priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                                        currency: r.currency,
                                      )).where((p) => p.name.isNotEmpty).toList();

                                      if (products.isNotEmpty) {
                                        // Group by currency
                                        final uzsProducts = products.where((p) => p.currency == 'UZS').toList();
                                        final usdProducts = products.where((p) => p.currency == 'USD').toList();

                                        if (uzsProducts.isNotEmpty) {
                                          final totalUZS = uzsProducts.fold(0.0, (sum, p) => sum + p.total);
                                          Provider.of<DebtService>(context, listen: false).addDebt(Debt(
                                            id: DateTime.now().millisecondsSinceEpoch.toString() + "_uzs",
                                            name: widget.personName,
                                            amount: totalUZS,
                                            date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                                            type: selectedType,
                                            currency: 'UZS',
                                            reason: reasonController.text.trim(),
                                            isPaid: false,
                                            products: uzsProducts,
                                          ));
                                        }

                                        if (usdProducts.isNotEmpty) {
                                          final totalUSD = usdProducts.fold(0.0, (sum, p) => sum + p.total);
                                          Provider.of<DebtService>(context, listen: false).addDebt(Debt(
                                            id: DateTime.now().millisecondsSinceEpoch.toString() + "_usd",
                                            name: widget.personName,
                                            amount: totalUSD,
                                            date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                                            type: selectedType,
                                            currency: 'USD',
                                            reason: reasonController.text.trim(),
                                            isPaid: false,
                                            products: usdProducts,
                                          ));
                                        }
                                        
                                        Navigator.pop(context);
                                        _showSuccessDialog(0, selectedCurrency, 'products');
                                      } else if (amount > 0) {
                                        Provider.of<DebtService>(context, listen: false).addDebt(Debt(
                                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                                          name: widget.personName,
                                          amount: amount,
                                          date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                                          type: selectedType,
                                          currency: selectedCurrency,
                                          reason: reasonController.text.trim(),
                                          isPaid: false,
                                          products: null,
                                        ));
                                        Navigator.pop(context);
                                        _showSuccessDialog(amount, selectedCurrency, 'add');
                                      }
                                    },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: selectedType == 'Haqqim' ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrencyToggle(String value, String label, bool isSelected, Function(String) onTap, {Color activeColor = const Color(0xFF3B82F6)}) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBalanceCard({required String label, required double amount, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          Text(
            currencyFormat.format(amount.abs()),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
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
        final allDebts = debtService.debts.where((d) => d.name == widget.personName).toList().reversed.toList();
        final unpaidDebts = allDebts.where((d) => !d.isPaid).toList();
        final productDebts = allDebts.where((d) => d.products != null && d.products!.isNotEmpty).toList();
        final hasProducts = productDebts.isNotEmpty;
        
        double unpaidUZS = 0;
        double unpaidUSD = 0;
        
        for (var d in allDebts) {
          final isHaqqim = d.type == 'Haqqim';
          final amount = isHaqqim ? d.amount : -d.amount;
          if (!d.isPaid) {
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
                    }),

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
                            height: 65,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            label: 'Qisman to\'lov',
                            icon: Icons.credit_card,
                            color: const Color(0xFFF59E0B),
                            onTap: () => _showPartialPaymentDialog(unpaidUZS, unpaidUSD),
                            height: 65,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Row 2: To'liq to'langan, Mahsulotlar & SMS (Conditional)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            label: 'To\'liq to\'langan',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF10B981),
                            onTap: () => _showFullPaymentConfirmationDialog(unpaidDebts),
                            height: 75,
                            isRow: false,
                          ),
                        ),
                        if (hasProducts) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionCard(
                              label: 'Mahsulotlar',
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFFF97316),
                              onTap: () => _showProductsBottomSheet(productDebts),
                              height: 75,
                              isRow: false,
                            ),
                          ),
                        ],
                        if (allDebts.any((d) => d.phone != null && d.phone!.length > 4)) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionCard(
                              label: 'SMS',
                              icon: Icons.chat_bubble_outline,
                              color: const Color(0xFF3B82F6),
                              onTap: () async {
                                final phoneDebt = allDebts.firstWhere(
                                  (d) => d.phone != null && d.phone!.length > 4,
                                );
                                
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
                              },
                              height: 75,
                              isRow: false,
                            ),
                          ),
                        ],
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
  }  Future<void> _showEditDebtDialog(Debt debt) async {
    if (debt.products != null && debt.products!.isNotEmpty) {
      return _showEditProductDebtDialog(debt);
    }

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
                                    Provider.of<DebtService>(context, listen: false).updateDebt(debt.copyWith(
                                      amount: amount,
                                      currency: selectedCurrency,
                                      type: selectedType,
                                      reason: reasonController.text.trim(),
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

  Future<void> _showEditProductDebtDialog(Debt debt) async {
    return showDialog(
      context: context,
      builder: (context) => _ProductEditDialog(
        debt: debt,
        currencyFormat: currencyFormat,
      ),
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
    final hasProducts = debt.products != null && debt.products!.isNotEmpty;

    // Default style for regular debts or payments
    final mainColor = isPayment 
        ? const Color(0xFF059669) 
        : (isHaqqim ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        fontSize: 14,
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
                          style: TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (hasProducts) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 9, color: Color(0xFFF97316)),
                            SizedBox(width: 4),
                            Text(
                              'Mahsulotlar',
                              style: TextStyle(fontSize: 9, color: Color(0xFFF97316), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subTitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showDebtOptionsMenu(debt),
                child: Icon(Icons.more_horiz, color: Colors.grey.shade400, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProductsBottomSheet(List<Debt> productDebts) {
    // Group debts by groupId or individual id if no groupId exists
    final Map<String, List<Debt>> groupedByTransaction = {};
    for (var debt in productDebts) {
      final key = debt.groupId ?? debt.id;
      if (!groupedByTransaction.containsKey(key)) {
        groupedByTransaction[key] = [];
      }
      groupedByTransaction[key]!.add(debt);
    }
    final transactionGroups = groupedByTransaction.values.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Barcha mahsulotlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: transactionGroups.length,
                  itemBuilder: (context, index) {
                    final group = transactionGroups[index];
                    final firstDebt = group.first;
                    final isHaqqim = firstDebt.type == 'Haqqim';
                    
                    // Collect all products from this group
                    final allProducts = group.expand((d) => d.products ?? []).toList();
                    
                    // Calculate totals by currency
                    final Map<String, double> totalsByCurrency = {};
                    for (var d in group) {
                      totalsByCurrency[d.currency] = (totalsByCurrency[d.currency] ?? 0) + d.amount;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isHaqqim ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHaqqim ? 'Tavar berish' : 'Tavar olish',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      firstDebt.date,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${allProducts.length} xil',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showDebtOptionsMenu(firstDebt);
                                      },
                                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Products List
                          ...allProducts.map((product) => Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isHaqqim ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart_outlined,
                                        color: isHaqqim ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1C1E),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${product.quantity} x ${currencyFormat.format(product.price).replaceAll(',', ' ')} ${product.currency == 'UZS' ? "so'm" : r'$'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${currencyFormat.format(product.total).replaceAll(',', ' ')} ${product.currency == 'UZS' ? "so'm" : "\$" }',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1C1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(color: Colors.grey.shade100, height: 1, indent: 16, endIndent: 16),
                            ],
                          )),
                          
                          // Footer with multiple totals if mixed
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50.withOpacity(0.5),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Guruh jami:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1C1E),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: totalsByCurrency.entries.map((e) => Text(
                                        e.key == 'UZS' 
                                            ? '${currencyFormat.format(e.value)} so\'m' 
                                            : '\$ ${currencyFormat.format(e.value)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF97316),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Yopish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                Icon(icon, color: Colors.white, size: 22),
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
                Icon(icon, color: Colors.white, size: 26),
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

class _ProductEditDialog extends StatefulWidget {
  final Debt debt;
  final NumberFormat currencyFormat;

  const _ProductEditDialog({
    required this.debt,
    required this.currencyFormat,
  });

  @override
  State<_ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<_ProductEditDialog> {
  late List<ProductEditRow> productRows;

  @override
  void initState() {
    super.initState();
    productRows = widget.debt.products!.map((p) => 
      ProductEditRow(name: p.name, quantity: p.quantity, price: p.price, currency: p.currency)
    ).toList();
  }

  @override
  void dispose() {
    for (var r in productRows) {
      r.dispose();
    }
    super.dispose();
  }

  double _calculateTotal() {
    double sum = 0;
    for (var r in productRows) {
      r._updateTotal();
      sum += r.total;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    double globalTotal = _calculateTotal();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mahsulotlarni tahrirlash',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...List.generate(productRows.length, (index) {
                      final row = productRows[index];
                      return Container(
                        key: ValueKey(row), // Stability improvement
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: row.nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Nomi',
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                                              const SizedBox(height: 16),
                                              const Text('Mahsulotni o\'chirish', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              const Text('Ushbu mahsulotni o\'chirmoqchimisiz?', textAlign: TextAlign.center),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextButton(
                                                      onPressed: () => Navigator.pop(ctx),
                                                      child: const Text('Bekor qilish'),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(ctx);
                                                        setState(() {
                                                          productRows.removeAt(index);
                                                        });
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.redAccent,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      ),
                                                      child: const Text('O\'chirish'),
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: row.quantityController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Soni',
                                      isDense: true,
                                      border: UnderlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: row.priceController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                                      onChanged: (_) => setState(() {}),
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Narxi',
                                        labelStyle: const TextStyle(fontSize: 12),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                        border: const UnderlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    margin: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      widget.debt.currency == 'UZS' ? "so'm" : r'$',
                                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                                child: Text(
                                  'Jami: ${widget.currencyFormat.format(row.total).replaceAll(',', ' ')} ${widget.debt.currency == 'UZS' ? "so'm" : r'$'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                                ),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          productRows.add(ProductEditRow(name: '', quantity: 1, price: 0, currency: widget.debt.currency));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Yangi mahsulot'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jami summa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${widget.currencyFormat.format(globalTotal).replaceAll(',', ' ')} ${widget.debt.currency == 'UZS' ? "so'm" : "\$"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0056D2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bekor qilish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedProducts = productRows.map((r) => Product(
                        name: r.nameController.text.trim(),
                        quantity: double.tryParse(r.quantityController.text.replaceAll(',', '.')) ?? 0,
                        price: double.tryParse(r.priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                        currency: widget.debt.currency,
                      )).toList();

                      Provider.of<DebtService>(context, listen: false).updateDebt(widget.debt.copyWith(
                        amount: globalTotal,
                        products: updatedProducts,
                      ));
                      
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Saqlash'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductEditRow {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  String currency;
  double total = 0;

  ProductEditRow({
    required String name,
    required double quantity,
    required double price,
    this.currency = 'UZS',
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity.toString()),
        priceController = TextEditingController(text: price == 0 ? '' : NumberFormat('#,###', 'en_US').format(price).replaceAll(',', ' ')) {
    _updateTotal();
  }

  void _updateTotal() {
    final q = double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;
    final p = double.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    total = q * p;
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

