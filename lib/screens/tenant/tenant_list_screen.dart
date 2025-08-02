import 'package:flutter/material.dart';
import '../../models/tenant_model.dart';
import '../../models/property_model.dart';
import '../../services/tenant_service.dart';
import '../../services/property_service.dart';
import 'add_tenant_screen.dart';
import 'edit_tenant_screen.dart';
import 'details/tenant_details_screen.dart';
import '../property/property_list_screen.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  final TenantService _tenantService = TenantService();
  final PropertyService _propertyService = PropertyService();
  List<TenantModel> _tenants = [];
  List<PropertyModel> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  void _loadTenants() async {
    setState(() {
      _isLoading = true;
    });

    // Load both tenants and properties
    List<TenantModel> tenants = await _tenantService.getUserTenants();
    List<PropertyModel> properties = await _propertyService.getUserProperties();
    
    setState(() {
      _tenants = tenants;
      _properties = properties;
      _isLoading = false;
    });
  }

  void _navigateToAddTenant() async {
    // Check if properties exist before allowing tenant addition
    if (_properties.isEmpty) {
      _showNoPropertiesDialog();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTenantScreen(),
      ),
    );

    if (result == true) {
      _loadTenants();
    }
  }

  void _showNoPropertiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('No Properties Found'),
          ],
        ),
        content: const Text(
          'You need to add at least one property before you can add tenants. Would you like to add a property now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PropertyListScreen(),
                ),
              ).then((_) => _loadTenants());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Property'),
          ),
        ],
      ),
    );
  }

  void _navigateToTenantDetails(TenantModel tenant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TenantDetailsScreen(tenant: tenant),
      ),
    );

    if (result == true) {
      _loadTenants();
    }
  }

  void _navigateToEditTenant(TenantModel tenant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTenantScreen(tenant: tenant),
      ),
    );

    if (result == true) {
      _loadTenants();
    }
  }

  void _deleteTenant(TenantModel tenant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tenant'),
        content: Text('Are you sure you want to delete "${tenant.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _tenantService.deleteTenant(tenant.id);
      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tenant deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTenants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'Failed to delete tenant'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Tenants',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add, 
              color: _properties.isEmpty ? Colors.grey : Colors.white,
            ),
            onPressed: _navigateToAddTenant,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : _properties.isEmpty
              ? _buildNoPropertiesState()
              : _tenants.isEmpty
                  ? _buildEmptyState()
                  : _buildTenantList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTenant,
        backgroundColor: _properties.isEmpty ? Colors.grey : Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoPropertiesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to add at least one property before you can manage tenants.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PropertyListScreen(),
                  ),
                ).then((_) => _loadTenants());
              },
              icon: const Icon(Icons.add_home),
              label: const Text('Add Property First'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tenants Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first tenant to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddTenant,
            icon: const Icon(Icons.add),
            label: const Text('Add Tenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tenants.length,
      itemBuilder: (context, index) {
        final tenant = _tenants[index];
        return _buildTenantCard(tenant);
      },
    );
  }

  Widget _buildTenantCard(TenantModel tenant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _navigateToTenantDetails(tenant),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header with avatar and name
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.deepPurple,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tenant.phoneNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (tenant.propertyName != null) ...[
                        Text(
                          'Property: ${tenant.propertyName}',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        'Room Rent: ₹${tenant.roomRent.toStringAsFixed(0)}/month',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bills section
            if (tenant.hasWaterBill || tenant.hasElectricityBill || tenant.hasGarbageBill) ...[
              Text(
                'Additional Services:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (tenant.hasWaterBill)
                    _buildClassicBillChip(
                      Icons.water_drop,
                      'Water',
                      Colors.blue,
                    ),
                  if (tenant.hasElectricityBill)
                    _buildClassicBillChip(
                      Icons.electric_bolt,
                      'Electricity',
                      Colors.yellow.shade700,
                    ),
                  if (tenant.hasGarbageBill)
                    _buildClassicBillChip(
                      Icons.delete,
                      'Garbage',
                      Colors.green,
                    ),
                ],
              ),
            ] else ...[
              Text(
                'No additional services',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _navigateToTenantDetails(tenant),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _navigateToEditTenant(tenant),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteTenant(tenant),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassicBillChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}