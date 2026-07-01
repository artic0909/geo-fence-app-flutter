import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'admin_drawer.dart';
import '../widgets/admin_loader.dart';


class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getTransactions();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _transactions = data['transactions'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF9F1CC);

    return Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 16)),
          backgroundColor: bgDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: goldMain),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_open, color: goldMain),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        endDrawer: const AdminDrawer(currentRoute: 'Transactions'),
        body: _isLoading
            ? const AdminLoader()
            : RefreshIndicator(
                color: bgDark,
                backgroundColor: goldMain,
                onRefresh: _loadTransactions,
                child: _transactions.isEmpty
                    ? _buildEmptyState(goldMain)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          return _buildTransactionCard(tx, cardDark, goldMain, goldLight);
                        },
                      ),
              ),
      );
  }

  Widget _buildEmptyState(Color accentColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
      children: [
        Icon(Icons.receipt_long_outlined, size: 80, color: accentColor.withValues(alpha: 0.3)),
        const SizedBox(height: 20),
        const Text(
          "NO TRANSACTIONS",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "You haven't made any subscription payments yet.",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, Color cardColor, Color accentColor, Color textColor) {
    final bool isSuccess = tx['is_success'] == true;
    final Color statusColor = isSuccess ? Colors.greenAccent : Colors.redAccent;
    final String amount = double.parse((tx['amount'] ?? '0').toString()).toStringAsFixed(2);
    final String planName = tx['plan_name'] ?? 'Custom Plan';
    final String txId = tx['razorpay_payment_id'] ?? tx['id'].toString();
    final String date = tx['created_at'] ?? 'Unknown Date';
    final String statusText = (tx['status'] ?? 'Unknown').toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName.toUpperCase(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: $txId",
                      style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[300])),
                ],
              ),
              Text(
                "₹$amount",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
