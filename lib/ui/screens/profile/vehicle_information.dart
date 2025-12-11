import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/vehicle_model.dart';

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({super.key});

  @override
  State<VehicleInformationScreen> createState() => _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _mileageController = TextEditingController();
  final _plateNumController = TextEditingController();
  
  String? _selectedVehicleType;
  bool _isSaving = false;
  File? _selectedImage;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text(
          'Vehicle Information',
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
                    if (double.tryParse(value) == null) {
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
                
                const SizedBox(height: 16),
                
                // Vehicle Type Dropdown
                _buildVehicleTypeDropdown(),
                
                const SizedBox(height: 16),
                
                // Vehicle Photo Upload Section
                _buildVehiclePhotoSection(),
                
                const SizedBox(height: 32),
                
                // Save/Update Button
                _buildSaveButton(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
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

  Widget _buildVehiclePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Photo (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add vehicle photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max size: 1 MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveVehicle,
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
                'Save / Update',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }


  void _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() { _isSaving = true; });
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('vehicles');
      final doc = col.doc();
      
      // Create VehicleModel instance
      final vehicle = VehicleModel(
        vehicleId: doc.id,
        userId: uid,
        vehicleType: _selectedVehicleType!,
        vehicleName: _vehicleNameController.text.trim(),
        vehiclePhoto: null, // Will be updated if photo is uploaded
        mileage: int.parse(_mileageController.text.trim()),
        nickName: _nicknameController.text.trim(),
        vehiclePlateNum: _plateNumController.text.trim(),
      );

      // Convert to JSON and add additional fields
      Map<String, dynamic> vehicleData = vehicle.toJson();
      vehicleData['createdAt'] = FieldValue.serverTimestamp();
      vehicleData['updatedAt'] = FieldValue.serverTimestamp();

      // Handle photo upload if image is selected
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

      await doc.set(vehicleData);

      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle information saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _nicknameController.clear();
      _vehicleNameController.clear();
      _mileageController.clear();
      _plateNumController.clear();
      setState(() {
        _selectedVehicleType = null;
        _selectedImage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
