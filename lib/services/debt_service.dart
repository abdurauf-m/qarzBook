import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt_model.dart';

class DebtService extends ChangeNotifier {
  // Singleton pattern
  static final DebtService _instance = DebtService._internal();
  factory DebtService() => _instance;
  DebtService._internal() {
    _loadDebts();
  }

  static const String _storageKey = 'qarzbook_debts';
  List<Debt> _debts = [];

  List<Debt> get debts => List.unmodifiable(_debts);

  Future<void> _loadDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? debtsJson = prefs.getString(_storageKey);
      if (debtsJson != null) {
        final List<dynamic> decoded = jsonDecode(debtsJson);
        _debts = decoded.map((item) => Debt.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading debts: $e');
    }
  }

  Future<void> _saveDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_debts.map((d) => d.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving debts: $e');
    }
  }

  void addDebt(Debt debt) {
    _debts.add(debt);
    _saveDebts();
    notifyListeners();
  }

  void togglePaid(String id) {
    final index = _debts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final old = _debts[index];
      _debts[index] = Debt(
        id: old.id,
        name: old.name,
        amount: old.amount,
        currency: old.currency,
        type: old.type,
        date: old.date,
        reason: old.reason,
        phone: old.phone,
        isPaid: !old.isPaid,
      );
      _saveDebts();
      notifyListeners();
    }
  }

  void addPartialPayment(String name, double amount, String currency, String type) {
    // Instead of splitting existing debts, we add a new "Payment" record 
    // of the opposite type. This way, the total balance (Haqqim - Qarzim) 
    // will be updated correctly, and the payment remains editable.
    
    final String oppositeType = (type == 'Haqqim') ? 'Qarzim' : 'Haqqim';
    
    _debts.add(Debt(
      id: DateTime.now().millisecondsSinceEpoch.toString() + "_p",
      name: name,
      amount: amount,
      currency: currency,
      type: oppositeType,
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      reason: 'To\'lov',
      isPaid: false, // Keep it unpaid so it contributes to the running balance
    ));
    
    _saveDebts();
    notifyListeners();
  }

  void deleteDebt(String id) {
    _debts.removeWhere((d) => d.id == id);
    _saveDebts();
    notifyListeners();
  }

  void updateDebt(Debt debt) {
    final index = _debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      _debts[index] = debt;
      _saveDebts();
      notifyListeners();
    }
  }

  void deletePersonByName(String name) {
    _debts.removeWhere((d) => d.name == name);
    _saveDebts();
    notifyListeners();
  }

  // Group by name for summary
  Map<String, List<Debt>> getGroupedDebts() {
    final Map<String, List<Debt>> grouped = {};
    for (var debt in _debts) {
      if (!grouped.containsKey(debt.name)) {
        grouped[debt.name] = [];
      }
      grouped[debt.name]!.add(debt);
    }
    return grouped;
  }
}
