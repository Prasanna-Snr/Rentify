import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tenant_model.dart';
import '../../services/tenant_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditTenantScreen extends StatefulWidget {
  final TenantModel tenant;

  const EditTenantScreen({
    super.key,
    required this.tenant,
  });

  @override
  State<EditTenantScreen> createState() => _EditTenantScreenState();
}

class _EditTenantScreenState extends State<EditTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final TenantService _tenantService = TenantService();
  
  // Controllers
  final _tenantNameController = TextEditingController();
  final _roomRentController = TextEditingController();
  final _waterBillController = TextEditingController();
  final _electricityUnitFeeController = TextEditingController();
  final _garbageBillController = TextEditingController();
  
  // Checkbox states
  bool _hasWaterBill = false;
  bool _hasElectricityBill = false;
  bool _hasGarbageBill = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  void _loadTenantData() {
    _tenantNameController.text = widget.tenant.tenantName;
    _roomRentController.text = widget.tenant.roomRent.toString();
    
    _hasWaterBill = widget.tenant.hasWaterBill;
    if (_hasWaterBill && widget.tenant.waterBillAmount != null) {
      _waterBillController.text = widget.tenant.waterBillAmount.toString();
    }
    
    _hasElectricityBill = widget.tenant.hasElectricityBill;
    if (_hasElectricityBill && widget.tenant.electricityUnitFee != null) {
      _electricityUnitFeeController.text = widget.tenant.electricityUnitFee.toString();
    }
    
    _hasGarbageBill = widget.tenant.hasGarbageBill;
    if (_hasGarbageBill && widget.tenant.garbageBillAmount != null) {
      _garbageBillController.text = widget.tenant.garbageBillAmount.toString();
    }
  }

  @override
  void dispose() {
    _tenantNameController.dispose();
    _roomRentController.dispose();
    _waterBillController.dispose();
    _electricityUnitFeeController.dispose();
    _garbageBillController.dispose();
    super.dispose();
  }

  void _updateTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTenant = widget.tenant.copyWith(
        tenantName: _tenantNameController.text.trim(),
        roomRent: double.parse(_roomRentController.text.trim()),
        hasWaterBill: _hasWaterBill,
        waterBillAmount: _hasWaterBill && _waterBillController.text.isNotEmpty
            ? double.parse(_waterBillController.text.trim())
            : null,
        hasElectricityBill: _hasElectricityBill,
        electricityUnitFee: _hasElectricityBill && _electricityUnitFeeController.text.isNotEmpty
            ? double.parse(_electricityUnitFeeController.text.trim())
            : null,
        hasGarbageBill: _hasGarbageBill,
        garbageBillAmount: _hasGarbageBill && _garbageBillController.text.isNotEmpty
            ? double.parse(_garbageBillController.text.trim())
            : null,
        updatedAt: DateTime.now(),
      );

      final result = await _tenantService.updateTenant(updatedTenant);

      setState(() {
        _isLoading = false;
      });

      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenant updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'Failed to update tenant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Tenant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tenant Name
                CustomTextField(
                  controller: _tenantNameController,
                  hintText: 'Tenant Name',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tenant name';
                    }
                    return null;
                  },
                ),

                // Room Rent (Required)
                CustomTextField(
                  controller: _roomRentController,
                  hintText: 'Room Rent (₹) *Required',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter room rent';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Bills Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Bills (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Water Bill
                      CheckboxListTile(
                        title: const Text('Water Bill'),
                        subtitle: const Text('Monthly water fee'),
                        value: _hasWaterBill,
                        onChanged: (value) {
                          setState(() {
                            _hasWaterBill = value ?? false;
                            if (!_hasWaterBill) {
                              _waterBillController.clear();
                            }
                          });
                        },
                        activeColor: Colors.deepPurple,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      if (_hasWaterBill) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _waterBillController,
                          hintText: 'Monthly Water Bill Amount (₹)',
                          prefixIcon: Icons.water_drop,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Electricity Bill
                      CheckboxListTile(
                        title: const Text('Electricity Bill'),
                        subtitle: const Text('Per unit electricity fee'),
                        value: _hasElectricityBill,
                        onChanged: (value) {
                          setState(() {
                            _hasElectricityBill = value ?? false;
                            if (!_hasElectricityBill) {
                              _electricityUnitFeeController.clear();
                            }
                          });
                        },
                        activeColor: Colors.deepPurple,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      if (_hasElectricityBill) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _electricityUnitFeeController,
                          hintText: 'Per Unit Electricity Fee (₹)',
                          prefixIcon: Icons.electric_bolt,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Garbage Bill
                      CheckboxListTile(
                        title: const Text('Garbage Bill'),
                        subtitle: const Text('Monthly garbage collection fee'),
                        value: _hasGarbageBill,
                        onChanged: (value) {
                          setState(() {
                            _hasGarbageBill = value ?? false;
                            if (!_hasGarbageBill) {
                              _garbageBillController.clear();
                            }
                          });
                        },
                        activeColor: Colors.deepPurple,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      if (_hasGarbageBill) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _garbageBillController,
                          hintText: 'Monthly Garbage Bill Amount (₹)',
                          prefixIcon: Icons.delete,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Update Button
                CustomButton(
                  text: 'Update Tenant',
                  onPressed: _updateTenant,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}