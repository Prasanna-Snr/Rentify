import 'package:flutter/material.dart';
import '../../../models/tenant_model.dart';
import 'sections/personal_details_section.dart';
import 'sections/rental_information_section.dart';
import 'sections/bill_section.dart';
import 'sections/payment_history_section.dart';

class TenantDetailsScreen extends StatefulWidget {
  final TenantModel tenant;

  const TenantDetailsScreen({
    super.key,
    required this.tenant,
  });

  @override
  State<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends State<TenantDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TenantModel _tenant;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tenant = widget.tenant;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _tenant.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bills'),
            Tab(text: 'Payments'),
            Tab(text: 'Rental'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bills Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BillSection(tenant: _tenant),
          ),
          
          // Payment History Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PaymentHistorySection(tenant: _tenant),
          ),
          
          // Rental Information Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RentalInformationSection(tenant: _tenant),
          ),
          
          // Personal Details Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PersonalDetailsSection(tenant: _tenant),
          ),
        ],
      ),
    );
  }
}