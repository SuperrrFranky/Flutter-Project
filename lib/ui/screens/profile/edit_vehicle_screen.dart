import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/vehicle_model.dart';

class EditVehicleScreen extends StatefulWidget {
  final VehicleModel vehicle;
  
  const EditVehicleScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _mileageController = TextEditingController();
  final _plateNumController = TextEditingController();
  
  String? _selectedVehicleType;
  bool _isSaving = false;
  File? _selectedImage;
  Uint8List? _existingPhotoData;
  final ImagePicker _picker = ImagePicker();

  final List<String> _vehicleTypes = [
    'Car',
    'Motorcycle',
    'Truck',
    'Van',
    'SUV',
    'Bus',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadExistingPhoto();
  }

  void _initializeFields() {
    _nicknameController.text = widget.vehicle.nickName;
    _vehicleNameController.text = widget.vehicle.vehicleName;
    _mileageController.text = widget.vehicle.mileage.toString();
    _plateNumController.text = widget.vehicle.vehiclePlateNum;
    _selectedVehicleType = widget.vehicle.vehicleType;
  }

  Future<void> _loadExistingPhoto() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || widget.vehicle.vehicleId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc(widget.vehicle.vehicleId!)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // Check for Blob photo data first
        if (data['vehicle_photo_data'] != null) {
          final blob = data['vehicle_photo_data'] as Blob;
          setState(() {
            _existingPhotoData = blob.bytes;
          });
          return;
        }
      }
    } catch (e) {
      // Silently handle error - vehicle might not have a photo
      print('Error loading existing photo: $e');
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _vehicleNameController.dispose();
    _mileageController.dispose();
    _plateNumController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingPhotoData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text(
          'Edit Vehicle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Photo Section
                _buildVehiclePhotoSection(),
                
                const SizedBox(height: 24),
                
                // Nickname Field
                _buildTextField(
                  label: 'Nickname',
                  controller: _nicknameController,
                  placeholder: 'Enter a nickname',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a nickname';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Vehicle Name Field
                _buildTextField(
                  label: 'Vehicle Name',
                  controller: _vehicleNameController,
                  placeholder: 'e.g., Myvi',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter vehicle name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Vehicle Type Dropdown
                _buildVehicleTypeDropdown(),
                
                const SizedBox(height: 16),
                
                // Mileage Field
                _buildTextField(
                  label: 'Mileage',
                  controller: _mileageController,
                  placeholder: 'Enter current mileage',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mileage';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Plate Number Field
                _buildTextField(
                  label: 'Plate Number',
                  controller: _plateNumController,
                  placeholder: 'e.g., ABC1234',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter plate number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF424242),
                          side: const BorderSide(color: Color(0xFF424242)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424242),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Update Vehicle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehiclePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _selectedImage != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                )
              : _existingPhotoData != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _existingPhotoData!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  : widget.vehicle.vehiclePhoto != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.vehicle.vehiclePhoto!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder();
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildImagePlaceholder(),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt, color: Color(0xFF424242)),
            label: const Text(
              'Change Photo',
              style: TextStyle(color: Color(0xFF424242)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'No photo selected',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedVehicleType,
            decoration: const InputDecoration(
              hintText: 'Type of vehicles',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _vehicleTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedVehicleType = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a vehicle type';
              }
              return null;
            },
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() { _isSaving = true; });
      
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final vehicleRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc(widget.vehicle.vehicleId!);

      // Create updated VehicleModel instance
      final updatedVehicle = widget.vehicle.copyWith(
        vehicleType: _selectedVehicleType!,
        vehicleName: _vehicleNameController.text.trim(),
        mileage: int.parse(_mileageController.text.trim()),
        nickName: _nicknameController.text.trim(),
        vehiclePlateNum: _plateNumController.text.trim(),
      );

      // Convert to JSON and add additional fields
      Map<String, dynamic> vehicleData = updatedVehicle.toJson();
      vehicleData['updatedAt'] = FieldValue.serverTimestamp();

      // Handle photo upload if new image is selected
      if (_selectedImage != null) {
        try {
          // Read the image file as bytes
          Uint8List imageBytes = await _selectedImage!.readAsBytes();

          // Check the size before uploading (1 MiB limit)
          if (imageBytes.lengthInBytes > 1048576) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image is too large! Maximum size is 1 MiB.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() { _isSaving = false; });
            return;
          }

          // Add photo data as Blob
          vehicleData['vehicle_photo_data'] = Blob(imageBytes);
          vehicleData['vehicle_photo_updated'] = FieldValue.serverTimestamp();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() { _isSaving = false; });
          return;
        }
      }

      await vehicleRef.update(vehicleData);

      if (!mounted) return;
      setState(() { _isSaving = false; });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle information updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(updatedVehicle); // Return updated vehicle
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
