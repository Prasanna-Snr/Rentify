import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/tenant_model.dart';
import '../../../../models/bill_model.dart';
import '../../../../models/payment_model.dart';
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
  List<BillModel> _unpaidBills = [];
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
    final bills = await _billingService.getTenantBills(widget.tenant.id);
    final unpaidBills = bills.where((bill) => bill.status != 'Paid').toList();

    setState(() {
      _ledgerEntries = ledgerEntries;
      _unpaidBills = unpaidBills;
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Payment Ledger',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    double totalPaid = 0;
    double totalDue = 0;
    double currentMonthPaid = 0;
    
    final now = DateTime.now();
    
    for (final entry in _ledgerEntries) {
      if (entry['type'] == 'payment') {
        final payment = entry['data'] as PaymentModel;
        totalPaid += payment.amount;
        
        if (payment.paymentDate.year == now.year && 
            payment.paymentDate.month == now.month) {
          currentMonthPaid += payment.amount;
        }
      } else if (entry['type'] == 'bill') {
        final bill = entry['data'] as BillModel;
        if (bill.status != 'Paid') {
          totalDue += bill.balanceAmount;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'This Month',
            amount: currentMonthPaid,
            color: Colors.green,
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Paid',
            amount: totalPaid,
            color: Colors.blue,
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Due',
            amount: totalDue,
            color: Colors.red,
            icon: Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._ledgerEntries.take(10).map((entry) => _buildLedgerItem(entry)),
        if (_ledgerEntries.length > 10) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _showAllTransactions(),
              child: Text(
                'View All ${_ledgerEntries.length} Transactions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
                      description,
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
                    '${isPayment ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPayment ? Colors.green : Colors.red,
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
                      status,
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
                        ? 'Due: ₹${balance.toStringAsFixed(0)}'
                        : 'Advance: ₹${(-balance).toStringAsFixed(0)}',
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
            'No Transaction History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bills and payments will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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
        unpaidBills: _unpaidBills,
        onPaymentAdded: _loadLedgerData,
      ),
    );
  }

  void _showAllTransactions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'All Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _ledgerEntries.length,
                  itemBuilder: (context, index) => _buildLedgerItem(_ledgerEntries[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final List<BillModel> unpaidBills;
  final VoidCallback onPaymentAdded;

  const AddPaymentDialog({
    super.key,
    required this.tenant,
    required this.unpaidBills,
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
  BillModel? _selectedBill;
  bool _isLoading = false;

  final List<String> _paymentTypes = ['Cash', 'Bank Transfer', 'UPI', 'Cheque'];

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
      billId: _selectedBill?.id,
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
          content: Text('Payment added successfully!'),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Payment for ${widget.tenant.displayName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Date
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Payment Date'),
                        subtitle: Text('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
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
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Amount
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Amount (₹)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter payment amount';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Type
                      DropdownButtonFormField<String>(
                        value: _paymentType,
                        decoration: const InputDecoration(
                          labelText: 'Payment Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        items: _paymentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _paymentType = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Bill Selection (Optional)
                      if (widget.unpaidBills.isNotEmpty) ...[
                        DropdownButtonFormField<BillModel>(
                          value: _selectedBill,
                          decoration: const InputDecoration(
                            labelText: 'Against Bill (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt),
                          ),
                          items: [
                            const DropdownMenuItem<BillModel>(
                              value: null,
                              child: Text('General Payment'),
                            ),
                            ...widget.unpaidBills.map((bill) {
                              return DropdownMenuItem<BillModel>(
                                value: bill,
                                child: Text(
                                  '${bill.formattedBillMonth} - ₹${bill.balanceAmount.toStringAsFixed(0)} due',
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBill = value;
                              if (value != null) {
                                _amountController.text = value.balanceAmount.toStringAsFixed(0);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Payment'),
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