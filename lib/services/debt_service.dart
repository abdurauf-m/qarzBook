import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import '../models/debt_model.dart';

class DebtService extends ChangeNotifier {
  // Singleton pattern
  static final DebtService _instance = DebtService._internal();
  factory DebtService() => _instance;
  DebtService._internal() {
    _loadDebts();
  }

  static const String _storageKey = 'qarzbook_debts';
  
  // BehaviorSubject through RxDart
  final _debtSubject = BehaviorSubject<List<Debt>>.seeded([]);
  
  // Expose as Stream
  Stream<List<Debt>> get debtStream => _debtSubject.stream;
  
  List<Debt> get debts => _debtSubject.value;

  Future<void> _loadDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? debtsJson = prefs.getString(_storageKey);
      if (debtsJson != null) {
        final List<dynamic> decoded = jsonDecode(debtsJson);
        final loadedDebts = decoded.map((item) => Debt.fromJson(item)).toList();
        _debtSubject.add(loadedDebts);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading debts: $e');
    }
  }

  Future<void> _saveDebts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(debts.map((d) => d.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving debts: $e');
    }
  }

  void addDebt(Debt debt) {
    final updatedDebts = [...debts, debt];
    _debtSubject.add(updatedDebts);
    _saveDebts();
    notifyListeners();
  }

  void togglePaid(String id) {
    final currentDebts = debts;
    final index = currentDebts.indexWhere((d) => d.id == id);
    if (index != -1) {
      currentDebts[index] = currentDebts[index].copyWith(isPaid: !currentDebts[index].isPaid);
      _debtSubject.add([...currentDebts]);
      _saveDebts();
      notifyListeners();
    }
  }

  void addPartialPayment(String name, double amount, String currency, String type, {List<Product>? products, String? groupId, String idSuffix = "_p"}) {
    final String oppositeType = (type == 'Haqqim') ? 'Qarzim' : 'Haqqim';
    
    final newDebt = Debt(
      id: DateTime.now().millisecondsSinceEpoch.toString() + idSuffix,
      name: name,
      amount: amount,
      currency: currency,
      type: oppositeType,
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      reason: products != null ? 'Tavar' : 'To\'lov',
      isPaid: false,
      products: products,
      groupId: groupId,
    );
    
    final updatedDebts = [...debts, newDebt];
    _debtSubject.add(updatedDebts);
    _saveDebts();
    notifyListeners();
  }

  void deleteDebt(String id) {
    final updatedDebts = debts.where((d) => d.id != id).toList();
    _debtSubject.add(updatedDebts);
    _saveDebts();
    notifyListeners();
  }

  void updateDebt(Debt debt) {
    final currentDebts = debts;
    final index = currentDebts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      currentDebts[index] = debt;
      _debtSubject.add([...currentDebts]);
      _saveDebts();
      notifyListeners();
    }
  }

  void deletePersonByName(String name) {
    final updatedDebts = debts.where((d) => d.name != name).toList();
    _debtSubject.add(updatedDebts);
    _saveDebts();
    notifyListeners();
  }

  Map<String, List<Debt>> getGroupedDebts() {
    final Map<String, List<Debt>> grouped = {};
    for (var debt in debts) {
      if (!grouped.containsKey(debt.name)) {
        grouped[debt.name] = [];
      }
      grouped[debt.name]!.add(debt);
    }
    return grouped;
  }

  @override
  void dispose() {
    _debtSubject.close();
    super.dispose();
  }
}
