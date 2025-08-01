import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService();
  
  // Controllers
  final _houseNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _numberOfFlightsController = TextEditingController();
  
  List<TextEditingController> _roomControllers = [];
  int _numberOfFlights = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _houseNumberController.dispose();
    _locationController.dispose();
    _numberOfFlightsController.dispose();
    for (var controller in _roomControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFlightNumberChanged(String value) {
    final flights = int.tryParse(value) ?? 0;
    if (flights != _numberOfFlights && flights > 0 && flights <= 10) {
      setState(() {
        _numberOfFlights = flights;
        
        // Dispose old controllers
        for (var controller in _roomControllers) {
          controller.dispose();
        }
        
        // Create new controllers for each flight
        _roomControllers = List.generate(
          flights,
          (index) => TextEditingController(),
        );
      });
    } else if (flights == 0) {
      setState(() {
        _numberOfFlights = 0;
        for (var controller in _roomControllers) {
          controller.dispose();
        }
        _roomControllers.clear();
      });
    }
  }

  void _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_numberOfFlights == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter number of flights'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate room numbers
    List<int> roomsPerFlight = [];
    for (int i = 0; i < _roomControllers.length; i++) {
      final roomCount = int.tryParse(_roomControllers[i].text.trim());
      if (roomCount == null || roomCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter valid room count for Flight ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      roomsPerFlight.add(roomCount);
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final property = PropertyModel(
        id: '',
        houseNumber: _houseNumberController.text.trim(),
        location: _locationController.text.trim(),
        numberOfFlights: _numberOfFlights,
        roomsPerFlight: roomsPerFlight,
        ownerId: '',
        createdAt: DateTime.now(),
      );

      final result = await _propertyService.addProperty(property);

      setState(() {
        _isLoading = false;
      });

      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result ?? 'Failed to add property'),
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
          'Add Property',
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
                // House Number
                CustomTextField(
                  controller: _houseNumberController,
                  hintText: 'House Number',
                  prefixIcon: Icons.home,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter house number';
                    }
                    return null;
                  },
                ),

                // Location
                CustomTextField(
                  controller: _locationController,
                  hintText: 'Location',
                  prefixIcon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),

                // Number of Flights
                CustomTextField(
                  controller: _numberOfFlightsController,
                  hintText: 'Number of Flights (1-10)',
                  prefixIcon: Icons.layers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter number of flights';
                    }
                    final flights = int.tryParse(value);
                    if (flights == null || flights < 1 || flights > 10) {
                      return 'Please enter a valid number (1-10)';
                    }
                    return null;
                  },
                  onChanged: _onFlightNumberChanged,
                ),

                // Room inputs for each flight
                if (_numberOfFlights > 0) ...[
                  const SizedBox(height: 20),
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
                          'Rooms per Flight',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(_numberOfFlights, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomTextField(
                              controller: _roomControllers[index],
                              hintText: 'Number of rooms in Flight ${index + 1}',
                              prefixIcon: Icons.room,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final rooms = int.tryParse(value);
                                if (rooms == null || rooms < 1) {
                                  return 'Enter valid number';
                                }
                                return null;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Save Button
                CustomButton(
                  text: 'Add Property',
                  onPressed: _saveProperty,
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