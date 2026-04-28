import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_text_field.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';
import '../utils/formatters.dart';

class OldiBerdiScreen extends StatefulWidget {
  const OldiBerdiScreen({super.key});

  @override
  State<OldiBerdiScreen> createState() => _OldiBerdiScreenState();
}

class _OldiBerdiScreenState extends State<OldiBerdiScreen> {
  String _selectedDebtType = 'Haqqim';
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'UZS';
  int _navIndex = 0;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: '+998');

  @override
  void initState() {
    super.initState();
    _updateDateController();
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0056D2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateController();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 50,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Muvaﬀaqiyatli',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Qarz qo\'shildi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Optionally clear fields
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Oldi-Berdi',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Qarz turi
                const Text(
                  'Qarz turi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDebtType,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.5),
                    ),
                  ),
                  items: ['Haqqim', 'Qarzim'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedDebtType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Sana
                CustomTextField(
                  label: 'Sana',
                  hintText: '21/04/2026',
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 24),

                // Ism
                CustomTextField(
                  label: 'Ism',
                  hintText: 'Ism',
                  controller: _nameController,
                ),
                const SizedBox(height: 24),

                // Miqdor
                CustomTextField(
                  label: 'Miqdor',
                  hintText: '1,000,000',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  suffixIcon: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (String value) {
                      setState(() => _selectedCurrency = value);
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'UZS',
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: _selectedCurrency == 'UZS' ? const Color(0xFFE8F0FF) : null,
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                'UZS (so\'m)',
                                style: TextStyle(
                                  color: _selectedCurrency == 'UZS' ? const Color(0xFF0056D2) : Colors.black,
                                  fontWeight: _selectedCurrency == 'UZS' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'USD',
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: _selectedCurrency == 'USD' ? const Color(0xFFE8F0FF) : null,
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                'USD (\$)',
                                style: TextStyle(
                                  color: _selectedCurrency == 'USD' ? const Color(0xFF0056D2) : Colors.black,
                                  fontWeight: _selectedCurrency == 'USD' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedCurrency == 'UZS' ? 'so\'m' : '\$',
                            style: const TextStyle(
                              color: Color(0xFF0056D2),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF0056D2)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sabab
                CustomTextField(
                  label: 'Sabab',
                  hintText: 'Sabab',
                  controller: _reasonController,
                ),
                const SizedBox(height: 24),

                // Telefon raqam
                CustomTextField(
                  label: 'Telefon raqam',
                  hintText: '+998',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                // Qo'shish Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '').trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Iltimos, ismni kiriting'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (amountStr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Iltimos, miqdorni kiriting'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountStr) ?? 0.0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Iltimos, to\'g\'ri miqdor kiriting'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      // Save data
                      final newDebt = Debt(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        amount: amount,
                        currency: _selectedCurrency,
                        type: _selectedDebtType,
                        date: _dateController.text,
                        reason: _reasonController.text.trim(),
                        phone: _phoneController.text.trim(),
                      );

                      Provider.of<DebtService>(context, listen: false).addDebt(newDebt);

                      // Show success
                      _showSuccessDialog();

                      // Clear fields (except date and phone prefix)
                      _nameController.clear();
                      _amountController.clear();
                      _reasonController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056D2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Qo\'shish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

