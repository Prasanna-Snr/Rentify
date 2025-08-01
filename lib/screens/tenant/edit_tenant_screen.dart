import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tenant_model.dart';
import '../../models/property_model.dart';
import '../../services/tenant_service.dart';
import '../../services/property_service.dart';
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
  final PropertyService _propertyService = PropertyService();
  
  // Controllers
  final _tenantNameController = TextEditingController();
  final _roomRentController = TextEditingController();
  final _waterBillController = TextEditingController();
  final _electricityUnitFeeController = TextEditingController();
  final _garbageBillController = TextEditingController();
  
  // Property selection
  List<PropertyModel> _properties = [];
  PropertyModel? _selectedProperty;
  bool _showPropertySelection = false;
  
  // Checkbox states
  bool _hasWaterBill = false;
  bool _hasElectricityBill = false;
  bool _hasGarbageBill = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPropertiesAndTenantData();
  }

  void _loadPropertiesAndTenantData() async {
    // Load properties
    List<PropertyModel> properties = await _propertyService.getUserProperties();
    
    setState(() {
      _properties = properties;
      _showPropertySelection = properties.length > 1;
      
      // Find selected property if tenant has one
      if (widget.tenant.propertyId != null) {
        _selectedProperty = properties.firstWhere(
          (property) => property.id == widget.tenant.propertyId,
          orElse: () => properties.isNotEmpty ? properties.first : null as PropertyModel,
        );
      }
    });
    
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
      // Validate property selection if multiple properties exist
      if (_showPropertySelection && _selectedProperty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a property'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final updatedTenant = widget.tenant.copyWith(
        tenantName: _tenantNameController.text.trim(),
        roomRent: double.parse(_roomRentController.text.trim()),
        propertyId: _selectedProperty?.id ?? (_properties.isNotEmpty ? _properties.first.id : null),
        propertyName: _selectedProperty?.displayName ?? (_properties.isNotEmpty ? _properties.first.displayName : null),
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

                // Property Selection (only show if multiple properties)
                if (_showPropertySelection) ...[
                  const SizedBox(height: 16),
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
                        Row(
                          children: [
                            Icon(
                              Icons.home_work,
                              color: Colors.deepPurple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Select Property',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PropertyModel>(
                          value: _selectedProperty,
                          decoration: InputDecoration(
                            hintText: 'Choose a property',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.deepPurple),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          items: _properties.map((property) {
                            return DropdownMenuItem<PropertyModel>(
                              value: property,
                              child: Text(
                                '${property.displayName} (${property.numberOfFlights} flights, ${property.totalRooms} rooms)',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (PropertyModel? value) {
                            setState(() {
                              _selectedProperty = value;
                            });
                          },
                          validator: _showPropertySelection ? (value) {
                            if (value == null) {
                              return 'Please select a property';
                            }
                            return null;
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ],

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