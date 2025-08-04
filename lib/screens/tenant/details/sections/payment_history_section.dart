import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/tenant_model.dart';
import '../../../../models/bill_model.dart';
import '../../../../models/payment_model.dart';
import '../../../../models/tenant_balance_model.dart';
import '../../../../services/billing_service.dart';

class PaymentHistorySection extends StatefulWidget {
  final TenantModel tenant;

  const PaymentHistorySection({
    super.key,
    required this.tenant,
  });

  @override
  State<PaymentHistorySection> createState() => _PaymentHistorySectionState();
}

class _PaymentHistorySectionState extends State<PaymentHistorySection> {
  final BillingService _billingService = BillingService();
  List<Map<String, dynamic>> _ledgerEntries = [];
  TenantBalanceModel? _tenantBalance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLedgerData();
  }

  void _loadLedgerData() async {
    setState(() {
      _isLoading = true;
    });

    final ledgerEntries = await _billingService.getTenantLedger(widget.tenant.id);
    final balance = await _billingService.getTenantBalance(widget.tenant.id);

    setState(() {
      _ledgerEntries = ledgerEntries;
      _tenantBalance = balance;
      _isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Payment Records',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.deepPurple.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary Cards
            _buildSummaryCards(),

            const SizedBox(height: 16),

            // Ledger Entries
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ledgerEntries.isEmpty
                    ? _buildEmptyState()
                    : _buildLedgerList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    double totalReceived = 0;
    double currentBalance = _tenantBalance?.currentBalance ?? 0.0;
    
    // Calculate total received from payments
    for (final entry in _ledgerEntries) {
      if (entry['type'] == 'payment') {
        final payment = entry['data'] as PaymentModel;
        totalReceived += payment.amount;
      }
    }

    // Determine due and advance amounts from current balance
    double totalDue = currentBalance > 0 ? currentBalance : 0.0;
    double advanceAmount = currentBalance < 0 ? currentBalance.abs() : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple,
            Colors.deepPurple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Row(
          children: [
            // Receive Money Section
            Expanded(
              child: _buildMoneySection(
                icon: Icons.account_balance_wallet,
                title: 'Money\nReceived',
                amount: totalReceived,
                color: Colors.green.shade400,
              ),
            ),
            
            // Elegant Divider
            Container(
              width: 2,
              height: 70,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            
            // Pending Money Section
            Expanded(
              child: _buildMoneySection(
                icon: Icons.schedule,
                title: 'Amount\nPending',
                amount: totalDue,
                color: Colors.orange.shade400,
              ),
            ),
            
            // Elegant Divider
            Container(
              width: 2,
              height: 70,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            
            // Advance Money Section
            Expanded(
              child: _buildMoneySection(
                icon: Icons.trending_up,
                title: 'Advance\nPayment',
                amount: advanceAmount,
                color: Colors.blue.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMoneySection({
    required IconData icon,
    required String title,
    required double amount,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bills generated and payments received',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        // Show only first 4 entries (excluding balance entry if it exists)
        ...(_ledgerEntries.where((entry) => entry['type'] != 'balance').take(4)).map((entry) => _buildLedgerItem(entry)),
        if (_ledgerEntries.where((entry) => entry['type'] != 'balance').length > 4) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _showAllTransactions(),
              icon: const Icon(Icons.history, size: 16),
              label: Text(
                'Show All ${_ledgerEntries.where((entry) => entry['type'] != 'balance').length} Records',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLedgerItem(Map<String, dynamic> entry) {
    final isPayment = entry['type'] == 'payment';
    final date = entry['date'] as DateTime;
    final amount = entry['amount'] as double;
    final status = entry['status'] as String;
    final description = entry['description'] as String;
    final balance = entry['balance'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getEntryStatusColor(status).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getEntryStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isPayment ? Icons.payment : Icons.receipt,
                  color: _getEntryStatusColor(status),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSimpleDescription(description, isPayment),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment ? 'Received' : 'Bill'} ₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPayment ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getEntryStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getSimpleStatus(status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getEntryStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (balance != 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: balance > 0 ? Colors.red.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    balance > 0 ? Icons.warning : Icons.account_balance_wallet,
                    size: 14,
                    color: balance > 0 ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    balance > 0
                        ? 'Still owes: ₹${balance.toStringAsFixed(0)}'
                        : 'Extra paid: ₹${(-balance).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: balance > 0 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No Payment Records Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate bills and record payments to see activity here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(
        tenant: widget.tenant,
        onPaymentAdded: _loadLedgerData,
      ),
    );
  }

  void _showAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPaymentHistoryScreen(
          tenant: widget.tenant,
          ledgerEntries: _ledgerEntries,
        ),
      ),
    );
  }

  String _getSimpleDescription(String description, bool isPayment) {
    if (isPayment) {
      return 'Payment Received';
    } else {
      // For bills, make it more understandable
      if (description.contains('Bill for')) {
        return description.replaceAll('Bill for', 'Monthly bill -');
      }
      return description;
    }
  }

  String _getSimpleStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Completed';
      case 'unpaid':
        return 'Pending';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      case 'due':
        return 'Due';
      case 'advance':
        return 'Advance';
      default:
        return status;
    }
  }

  Color _getEntryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'due':
        return Colors.red;
      case 'advance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class AddPaymentDialog extends StatefulWidget {
  final TenantModel tenant;
  final VoidCallback onPaymentAdded;

  const AddPaymentDialog({
    super.key,
    required this.tenant,
    required this.onPaymentAdded,
  });

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final BillingService _billingService = BillingService();
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String _paymentType = 'Cash';
  bool _isLoading = false;

  final List<String> _paymentMethods = ['Cash', 'Bank Transfer', 'eSewa'];

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _billingService.addPayment(
      tenant: widget.tenant,
      amount: double.parse(_amountController.text),
      paymentType: _paymentType,
      paymentDate: _paymentDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result == 'success') {
      Navigator.pop(context);
      widget.onPaymentAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Add New Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  'From: ${widget.tenant.displayName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 1. Payment Date
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _paymentDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _paymentDate = date;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.deepPurple),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Amount
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.currency_rupee, color: Colors.deepPurple),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null || double.parse(value) <= 0) {
                              return 'Please enter valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 3. Payment Method Dropdown
                        DropdownButtonFormField<String>(
                          value: _paymentType,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.payment, color: Colors.deepPurple),
                          ),
                          items: _paymentMethods.map((method) {
                            IconData icon;
                            Color color;
                            switch (method) {
                              case 'Cash':
                                icon = Icons.money;
                                color = Colors.green;
                                break;
                              case 'Bank Transfer':
                                icon = Icons.account_balance;
                                color = Colors.blue;
                                break;
                              case 'eSewa':
                                icon = Icons.phone_android;
                                color = Colors.purple;
                                break;
                              default:
                                icon = Icons.payment;
                                color = Colors.grey;
                            }
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Row(
                                children: [
                                  Icon(icon, color: color, size: 20),
                                  const SizedBox(width: 10),
                                  Text(method),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _paymentType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // 4. Notes (Optional)
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.note, color: Colors.deepPurple),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text('Save Payment'),
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
  }
}

// All Payment History Screen
class AllPaymentHistoryScreen extends StatelessWidget {
  final TenantModel tenant;
  final List<Map<String, dynamic>> ledgerEntries;

  const AllPaymentHistoryScreen({
    super.key,
    required this.tenant,
    required this.ledgerEntries,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out balance entries for the main list
    final filteredEntries = ledgerEntries.where((entry) => entry['type'] != 'balance').toList();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Payment History',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete payment and billing history (${filteredEntries.length} records)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // History list
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No History Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return _buildLedgerItem(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerItem(Map<String, dynamic> entry) {
    final isPayment = entry['type'] == 'payment';
    final date = entry['date'] as DateTime;
    final amount = entry['amount'] as double;
    final status = entry['status'] as String;
    final description = entry['description'] as String;
    final balance = entry['balance'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getEntryStatusColor(status).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getEntryStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isPayment ? Icons.payment : Icons.receipt,
                  color: _getEntryStatusColor(status),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSimpleDescription(description, isPayment),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPayment ? 'Received' : 'Bill'} ₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPayment ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getEntryStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getSimpleStatus(status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getEntryStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (balance != 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: balance > 0 ? Colors.red.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    balance > 0 ? Icons.warning : Icons.account_balance_wallet,
                    size: 14,
                    color: balance > 0 ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    balance > 0
                        ? 'Still owes: ₹${balance.toStringAsFixed(0)}'
                        : 'Extra paid: ₹${(-balance).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: balance > 0 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSimpleDescription(String description, bool isPayment) {
    if (isPayment) {
      return 'Payment Received';
    } else {
      // For bills, make it more understandable
      if (description.contains('Bill for')) {
        return description.replaceAll('Bill for', 'Monthly bill -');
      }
      return description;
    }
  }

  String _getSimpleStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Completed';
      case 'unpaid':
        return 'Pending';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      case 'due':
        return 'Due';
      case 'advance':
        return 'Advance';
      default:
        return status;
    }
  }

  Color _getEntryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'due':
        return Colors.red;
      case 'advance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}