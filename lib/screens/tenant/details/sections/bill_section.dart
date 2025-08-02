import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/tenant_model.dart';
import '../../../../models/bill_model.dart';
import '../../../../services/billing_service.dart';

class BillSection extends StatefulWidget {
  final TenantModel tenant;

  const BillSection({
    super.key,
    required this.tenant,
  });

  @override
  State<BillSection> createState() => _BillSectionState();
}

class _BillSectionState extends State<BillSection> {
  final BillingService _billingService = BillingService();
  List<BillModel> _bills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() async {
    setState(() {
      _isLoading = true;
    });

    final bills = await _billingService.getTenantBills(widget.tenant.id);
    setState(() {
      _bills = bills;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Generate Bill Card
        Card(
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
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Generate Monthly Bill',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showGenerateBillDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Current Bill Configuration
                _buildCurrentConfig(),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bills History
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bills History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _bills.isEmpty
                        ? _buildEmptyBillsState()
                        : _buildBillsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentConfig() {
    return Column(
      children: [
        // Room Rent (Always present)
        _buildConfigItem(
          icon: Icons.home,
          title: 'Room Rent',
          amount: widget.tenant.roomRent,
          color: Colors.deepPurple,
          isActive: true,
        ),
        
        const SizedBox(height: 8),
        
        // Water Bill
        _buildConfigItem(
          icon: Icons.water_drop,
          title: 'Water Bill',
          amount: widget.tenant.waterBillAmount,
          color: Colors.blue,
          isActive: widget.tenant.hasWaterBill,
        ),
        
        const SizedBox(height: 8),
        
        // Electricity Bill
        _buildConfigItem(
          icon: Icons.electric_bolt,
          title: 'Electricity Bill',
          amount: widget.tenant.electricityUnitFee,
          color: Colors.yellow.shade700,
          isActive: widget.tenant.hasElectricityBill,
          subtitle: widget.tenant.hasElectricityBill ? 'Per unit rate' : null,
        ),
        
        const SizedBox(height: 8),
        
        // Garbage Bill
        _buildConfigItem(
          icon: Icons.delete,
          title: 'Garbage Collection',
          amount: widget.tenant.garbageBillAmount,
          color: Colors.green,
          isActive: widget.tenant.hasGarbageBill,
        ),
      ],
    );
  }

  Widget _buildConfigItem({
    required IconData icon,
    required String title,
    required double? amount,
    required Color color,
    required bool isActive,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: isActive ? color : Colors.grey,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isActive && amount != null)
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          else
            Text(
              'Not included',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBillsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No Bills Generated',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generate your first bill to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList() {
    return Column(
      children: _bills.map((bill) => _buildBillCard(bill)).toList(),
    );
  }

  Widget _buildBillCard(BillModel bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBillStatusColor(bill.status).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bill for ${bill.formattedBillMonth}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBillStatusColor(bill.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bill.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getBillStatusColor(bill.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBillBreakdown(bill),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ₹${bill.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              if (bill.balanceAmount > 0)
                Text(
                  'Due: ₹${bill.balanceAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillBreakdown(BillModel bill) {
    return Column(
      children: [
        _buildBreakdownItem('Room Rent', bill.roomRent),
        if (bill.includeWater && bill.waterAmount != null)
          _buildBreakdownItem('Water Bill', bill.waterAmount!),
        if (bill.includeElectricity && bill.electricityAmount != null)
          _buildBreakdownItem(
            'Electricity Bill',
            bill.electricityAmount!,
          ),
        if (bill.includeGarbage && bill.garbageAmount != null)
          _buildBreakdownItem('Garbage Collection', bill.garbageAmount!),
      ],
    );
  }

  Widget _buildBreakdownItem(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBillStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showGenerateBillDialog() {
    showDialog(
      context: context,
      builder: (context) => GenerateBillDialog(
        tenant: widget.tenant,
        onBillGenerated: _loadBills,
      ),
    );
  }
}

class GenerateBillDialog extends StatefulWidget {
  final TenantModel tenant;
  final VoidCallback onBillGenerated;

  const GenerateBillDialog({
    super.key,
    required this.tenant,
    required this.onBillGenerated,
  });

  @override
  State<GenerateBillDialog> createState() => _GenerateBillDialogState();
}

class _GenerateBillDialogState extends State<GenerateBillDialog> {
  final BillingService _billingService = BillingService();
  final _formKey = GlobalKey<FormState>();
  
  DateTime _billDate = DateTime.now();
  final _currentReadingController = TextEditingController(); // For electricity amount
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _currentReadingController.dispose();
    super.dispose();
  }

  void _generateBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Calculate electricity amount using units * rate per unit
    double? electricityAmount;
    if (widget.tenant.hasElectricityBill && _currentReadingController.text.isNotEmpty) {
      electricityAmount = _calculateElectricityAmount();
    }

    final result = await _billingService.generateBill(
      tenant: widget.tenant,
      billDate: _billDate,
      includeWater: widget.tenant.hasWaterBill,
      waterAmount: widget.tenant.hasWaterBill ? widget.tenant.waterBillAmount : null,
      includeGarbage: widget.tenant.hasGarbageBill,
      garbageAmount: widget.tenant.hasGarbageBill ? widget.tenant.garbageBillAmount : null,
      includeElectricity: widget.tenant.hasElectricityBill,
      electricityAmount: electricityAmount,
    );

    setState(() {
      _isLoading = false;
    });

    if (result == 'success') {
      Navigator.pop(context);
      widget.onBillGenerated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill generated successfully!'),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.teal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Generate Bill',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          Text(
                            'For: ${widget.tenant.displayName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bill Date
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _billDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  _billDate = date;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bill Date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_billDate.day}/${_billDate.month}/${_billDate.year}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.edit, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Electricity Units Input (if enabled)
                        if (widget.tenant.hasElectricityBill) ...[
                          Container(
                            padding: EdgeInsets.only(left: 15),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: TextFormField(
                              controller: _currentReadingController,
                              decoration: InputDecoration(
                                labelText: 'Electricity units',
                                hintText: 'Enter units consumed',
                                border: InputBorder.none,
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (widget.tenant.hasElectricityBill && (value == null || value.isEmpty)) {
                                  return 'Please enter electricity units';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() {}); // Refresh to update bill summary
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Bill Summary
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bill Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Room Rent
                              _buildBillSummaryItem(
                                'Room Rent',
                                widget.tenant.roomRent,
                                Colors.deepPurple,
                              ),
                              
                              // Water Bill (if enabled)
                              if (widget.tenant.hasWaterBill)
                                _buildBillSummaryItem(
                                  'Water Bill',
                                  widget.tenant.waterBillAmount ?? 0,
                                  Colors.blue,
                                ),
                              
                              // Garbage Bill (if enabled)
                              if (widget.tenant.hasGarbageBill)
                                _buildBillSummaryItem(
                                  'Garbage Collection',
                                  widget.tenant.garbageBillAmount ?? 0,
                                  Colors.green,
                                ),
                              
                              // Electricity Bill (if enabled and units entered)
                              if (widget.tenant.hasElectricityBill && _currentReadingController.text.isNotEmpty)
                                _buildBillSummaryItem(
                                  'Electricity Bill',
                                  _calculateElectricityAmount(),
                                  Colors.orange,
                                ),
                              
                              const SizedBox(height: 16),
                              const Divider(thickness: 1),
                              const SizedBox(height: 8),
                              
                              // Total
                              Row(
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹${_calculateTotal().toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateBill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
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
                            : const Text(
                                'Generate Bill',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillSummaryItem(String title, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateElectricityAmount() {
    if (!widget.tenant.hasElectricityBill || 
        _currentReadingController.text.isEmpty ||
        widget.tenant.electricityUnitFee == null) {
      return 0.0;
    }
    
    final units = double.tryParse(_currentReadingController.text) ?? 0.0;
    final ratePerUnit = widget.tenant.electricityUnitFee ?? 0.0;
    return units * ratePerUnit;
  }

  double _calculateTotal() {
    double total = widget.tenant.roomRent;
    
    if (widget.tenant.hasWaterBill && widget.tenant.waterBillAmount != null) {
      total += widget.tenant.waterBillAmount!;
    }
    
    if (widget.tenant.hasGarbageBill && widget.tenant.garbageBillAmount != null) {
      total += widget.tenant.garbageBillAmount!;
    }
    
    if (widget.tenant.hasElectricityBill) {
      total += _calculateElectricityAmount();
    }
    
    return total;
  }
}