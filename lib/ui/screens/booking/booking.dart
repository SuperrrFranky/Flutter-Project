import 'package:assignment/models/booking_model.dart';
import 'package:assignment/services/notification_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/vehicle_model.dart';
import '../../../services/notification_service.dart';
import '../profile/user_vehicle.dart';
import '../../../services/booking_service.dart';
import 'booking_confirmation.dart';
import '../payment/billing.dart';
import '../../../core/constants/app_colors.dart';
import '../main_navigation_screen.dart';

// Data structure for service categories
class ServiceCategorySelection {
  String? category;
  List<String> selectedServices;
  bool isEnabled;
  bool isCompleted;

  ServiceCategorySelection({
    this.category,
    this.selectedServices = const [],
    this.isEnabled = false,
    this.isCompleted = false,
  });
}

class Booking extends StatefulWidget {
  final BookingModel? initialBooking;
  const Booking({super.key, this.initialBooking});

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  
  // Multiple category selections
  List<ServiceCategorySelection> _categorySelections = [
    ServiceCategorySelection(isEnabled: true), // First dropdown is always enabled
  ];
  
  double _previewTotal = 0.0;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  bool _hasUnpaidInvoices = false;
  
  // Data from Firebase
  List<String> _vehicleTypes = [];
  List<VehicleModel> _userVehicles = [];
  List<String> _serviceCategories = [];
  Map<String, List<String>> _serviceTypesByCategory = {}; // Cache service types by category
  bool _dataLoaded = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  Future<void> _applyInitialBookingIfAny() async {
    final initial = widget.initialBooking;
    if (initial == null) return;
    // Prefill controllers
    _vehicleNameController.text = initial.vehicleName;
    _phoneNumberController.text = initial.phoneNumber;
    _selectedDateTime = initial.preferredDateTime;

    // Build category selections from breakdown
    final Map<String, List<String>> byCategory = {};
    for (final item in initial.serviceBreakdown) {
      final cat = (item['category'] as String?) ?? '';
      final name = (item['serviceName'] as String?) ?? '';
      if (cat.isEmpty || name.isEmpty) continue;
      byCategory.putIfAbsent(cat, () => <String>[]).add(name);
    }
    if (byCategory.isNotEmpty) {
      _categorySelections = [];
      for (final entry in byCategory.entries) {
        _categorySelections.add(
          ServiceCategorySelection(
            category: entry.key,
            selectedServices: entry.value,
            isEnabled: true,
            isCompleted: true,
          ),
        );
        // Ensure types are cached for UI
        await _loadServiceTypes(entry.key, _categorySelections.length - 1);
      }
    }

    await _recomputePreviewTotal();
    if (mounted) setState(() {});
  }

  Future<void> _openVehiclePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select your vehicle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userVehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final v = _userVehicles[index];
                      final isSelected = v.displayName == _vehicleNameController.text;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, v.displayName),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected ? AppColors.app_green : Colors.grey[200]!, width: isSelected ? 2 : 1),
                              color: isSelected ? AppColors.app_green.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.app_green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.directions_car, color: AppColors.app_green, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (v.vehicleType.isNotEmpty)
                                        Text(
                                          v.vehicleType,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppColors.app_green),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _vehicleNameController.text = selected;
      });
      await _recomputePreviewTotal();
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final vehicleTypes = await BookingService.getVehicleTypes();
      final userVehicles = await BookingService.getUserVehicles(userId);
      final serviceCategories = await BookingService.getServiceCategories();
      
      // Load current user data to prefill phone number
      final currentUser = await BookingService.getCurrentUser();
      if (currentUser != null && currentUser.phoneNo.isNotEmpty) {
        _phoneNumberController.text = currentUser.phoneNo;
      }
      
      // Check for unpaid invoices
      final hasUnpaid = await BookingService.hasUnpaidInvoices(userId);
      
      setState(() {
        _vehicleTypes = vehicleTypes;
        _userVehicles = userVehicles;
        _serviceCategories = serviceCategories;
        _hasUnpaidInvoices = hasUnpaid;
        _dataLoaded = true;
      });
      await _applyInitialBookingIfAny();
      
      // Start animations with staggered timing
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _dataLoaded = true;
      });
      _fadeController.forward();
      _slideController.forward();
    }
  }

  Future<void> _loadServiceTypes(String category, int index) async {
    try {
      // Check if already cached
      if (_serviceTypesByCategory.containsKey(category)) {
        return;
      }
      
      final serviceTypes = await BookingService.getServiceTypesByCategory(category);
      setState(() {
        _serviceTypesByCategory[category] = serviceTypes;
      });
    } catch (e) {
      print('Error loading service types: $e');
      setState(() {
        _serviceTypesByCategory[category] = [];
      });
    }
  }

  Future<void> _recomputePreviewTotal() async {
    if (_userVehicles.isEmpty || _vehicleNameController.text.isEmpty) return;
    
    final selectedVehicle = _userVehicles.firstWhere(
      (v) => v.displayName == _vehicleNameController.text.trim(),
      orElse: () => _userVehicles.first,
    );
    
    final vehicleTypeForRate = selectedVehicle.vehicleType.isNotEmpty 
        ? selectedVehicle.vehicleType 
        : 'Car';
    
    final rate = BookingService.getVehicleRate(vehicleTypeForRate);
    double total = 0.0;
    
    // Calculate total from all category selections
    for (final selection in _categorySelections) {
      for (final serviceName in selection.selectedServices) {
        final base = await BookingService.getServicePriceByName(serviceName) ?? 0.0;
        total += base * rate;
      }
    }
    
    setState(() {
      _previewTotal = total;
    });
  }

  // Check if a category selection is completed (has category and at least one service)
  bool _isCategorySelectionCompleted(ServiceCategorySelection selection) {
    return selection.category != null && selection.selectedServices.isNotEmpty;
  }

  // Update category selections and manage dropdown visibility
  void _updateCategorySelections() {
    setState(() {
      for (int i = 0; i < _categorySelections.length; i++) {
        _categorySelections[i].isCompleted = _isCategorySelectionCompleted(_categorySelections[i]);
      }
      
      // Check if we need to add a new dropdown
      if (_categorySelections.isNotEmpty && _categorySelections.last.isCompleted) {
        // Add new dropdown if the last one is completed and we haven't reached a reasonable limit
        if (_categorySelections.length < 5) { // Reasonable limit
          _categorySelections.add(ServiceCategorySelection(isEnabled: false));
        }
      }
      
      // Enable next dropdown if previous is completed
      for (int i = 1; i < _categorySelections.length; i++) {
        if (i > 0 && _categorySelections[i - 1].isCompleted && !_categorySelections[i].isEnabled) {
          // Keep it disabled until user clicks on it
        }
      }
    });
  }

  // Enable a dropdown when user clicks on it
  void _enableDropdown(int index) {
    if (index > 0 && _categorySelections[index - 1].isCompleted) {
      setState(() {
        _categorySelections[index].isEnabled = true;
      });
    }
  }

  // Remove empty dropdowns except the first one
  void _removeEmptyDropdowns() {
    setState(() {
      _categorySelections.removeWhere((selection) => 
        _categorySelections.indexOf(selection) > 0 && 
        selection.category == null && 
        selection.selectedServices.isEmpty
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _vehicleNameController.dispose();
    _phoneNumberController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    // Set minimum date to tomorrow (at least 1 day in advance)
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    final DateTime minDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isBefore(minDate) ? minDate : _selectedDateTime,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.app_green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Set time restrictions: 9 AM to 8 PM
      final TimeOfDay minTime = const TimeOfDay(hour: 9, minute: 0);
      final TimeOfDay maxTime = const TimeOfDay(hour: 20, minute: 0);
      
      // If selected date is today, set initial time to 9 AM or current time (whichever is later)
      TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedDateTime);
      if (pickedDate.day == DateTime.now().day && 
          pickedDate.month == DateTime.now().month && 
          pickedDate.year == DateTime.now().year) {
        final now = TimeOfDay.now();
        if (now.hour < 9) {
          initialTime = minTime;
        } else if (now.hour >= 20) {
          // If it's past 8 PM today, show tomorrow's date instead
          return;
        }
      }
      
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.app_green,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1A1A1A),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Validate time is within allowed range (9 AM - 8 PM)
        if (pickedTime.hour >= 9 && pickedTime.hour < 20) {
          setState(() {
            _selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        } else {
          // Show error message for invalid time
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking time must be between 9:00 AM and 8:00 PM'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    // Check for unpaid invoices before allowing new booking
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final hasUnpaid = await BookingService.hasUnpaidInvoices(userId);
    if (hasUnpaid) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.payment, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have unpaid invoices. Please complete payment before making a new booking.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Validate booking time restrictions
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    // Check if booking is at least 1 day in advance
    if (_selectedDateTime.isBefore(tomorrow)) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Booking must be at least 1 day in advance'),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Check if time is within allowed range (9 AM - 8 PM)
    if (_selectedDateTime.hour < 9 || _selectedDateTime.hour >= 20) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Booking time must be between 9:00 AM and 8:00 PM'),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if at least one category selection is completed
    final hasCompletedSelections = _categorySelections.any((selection) => selection.isCompleted);
    if (!hasCompletedSelections) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select at least one service'),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final selectedVehicle = _userVehicles.firstWhere(
        (v) => v.displayName == _vehicleNameController.text.trim(),
        orElse: () => _userVehicles.first,
      );
      
      final vehicleTypeForRate = selectedVehicle.vehicleType.isNotEmpty 
          ? selectedVehicle.vehicleType 
          : 'Car';
      
      final rate = BookingService.getVehicleRate(vehicleTypeForRate);

      double totalAmount = 0.0;
      final List<Map<String, dynamic>> breakdown = [];
      final List<String> allSelectedServices = [];
      
      // Collect all services from all category selections
      for (final selection in _categorySelections) {
        if (selection.isCompleted) {
          allSelectedServices.addAll(selection.selectedServices);
          
          for (final serviceName in selection.selectedServices) {
            final base = await BookingService.getServicePriceByName(serviceName) ?? 0.0;
            final total = base * rate;
            breakdown.add({
              'serviceName': serviceName,
              'basePrice': base,
              'rate': rate,
              'total': total,
              'category': selection.category,
            });
            totalAmount += total;
          }
        }
      }

      if (widget.initialBooking != null && widget.initialBooking!.id != null) {
        // Update existing booking, then return to caller
        final updated = widget.initialBooking!.copyWith(
          vehicleType: vehicleTypeForRate,
          vehicleName: _vehicleNameController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          serviceType: allSelectedServices.join(', '),
          serviceTypes: allSelectedServices,
          preferredDateTime: _selectedDateTime,
          totalAmount: totalAmount,
          serviceBreakdown: breakdown,
        );
        await BookingService.updateBooking(updated);

        final bookingId = updated.id.hashCode;

        await NotificationService.rescheduleReminderNotification(
          bookingId,
          updated.vehicleName,
          updated.preferredDateTime,
        );

        if (mounted) Navigator.pop(context, updated);
        return;
      } else {
        final booking = BookingModel(
          userId: userId,
          vehicleType: vehicleTypeForRate,
          vehicleName: _vehicleNameController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          serviceType: allSelectedServices.join(', '), // Combined service types
          serviceTypes: allSelectedServices,
          preferredDateTime: _selectedDateTime,
          totalAmount: totalAmount,
          serviceBreakdown: breakdown,
        );

        final created = await BookingService.createBooking(booking);

        final bookingId = created.id.hashCode;

        await NotificationService.scheduleReminderNotification(
          bookingId,
          created.vehicleName,
          created.preferredDateTime,
        );

        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(booking: created),
          ),
        );

        if (!mounted) return;
        
        // Clear form after returning from confirmation screen
        _formKey.currentState!.reset();
        _vehicleNameController.clear();
        _phoneNumberController.clear();
        _serviceTypeController.clear();
        setState(() {
          _selectedDateTime = DateTime.now().add(const Duration(days: 1));
          _categorySelections = [ServiceCategorySelection(isEnabled: true)];
          _previewTotal = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.app_green.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.app_green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.app_green),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading booking details...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A), size: 20),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Book a Service',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.app_green,
                      AppColors.app_green,
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Form Content with enhanced animations
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          _buildProgressIndicator(),
                          const SizedBox(height: 24),

                          // Unpaid invoices warning banner
                          if (_hasUnpaidInvoices) ...[
                            _buildUnpaidInvoicesWarning(),
                            const SizedBox(height: 16),
                          ],

                          // If no vehicles, suggest registration
                          if (_userVehicles.isEmpty) ...[
                            _buildEmptyVehicleCard(),
                            const SizedBox(height: 24),
                          ],

                          // Vehicle Selection
                          _buildVehicleSelection(),
                          const SizedBox(height: 24),

                          // Phone Number Field
                          _buildEnhancedFormField(
                            label: 'Contact Number',
                            hint: _phoneNumberController.text.isNotEmpty 
                                ? 'Phone number prefilled from profile (editable)' 
                                : 'Enter your phone number',
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            suffixIcon: _phoneNumberController.text.isNotEmpty 
                                ? Icons.edit_outlined 
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-]')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              final phoneRegex = RegExp(
                                r'^(?:'
                                r'0?11[- ]?\d{8}'              // 011 with or without 0, 8 digits
                                r'|0?1[0,2-9][- ]?\d{7,8}'     // 010, 012–019 with or without 0, 7–8 digits
                                r'|0?[3-9][- ]?\d{6,8}'        // Landline 03–09 with or without 0, 6–8 digits
                                r'|\d{8}'                      // Raw 8-digit number
                                r')$'
                              );
                              if (!phoneRegex.hasMatch(value.trim())) {
                                return 'Enter a valid Malaysian phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Multiple Service Category Selections
                          ..._buildMultipleCategorySelections(),

                          const SizedBox(height: 24),

                          // Date & Time Selection
                          _buildDateTimeSelection(),
                          const SizedBox(height: 40),

                          // Submit Button
                          _buildSubmitButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int completedSteps = 0;
    if (_vehicleNameController.text.isNotEmpty) completedSteps++;
    if (_phoneNumberController.text.isNotEmpty) completedSteps++;
    final hasCompletedCategories = _categorySelections.any((selection) => selection.isCompleted);
    if (hasCompletedCategories) completedSteps++;
    if (_selectedDateTime != DateTime.now().add(const Duration(days: 1))) completedSteps++;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.app_green.withOpacity(0.1),
            AppColors.app_green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.app_green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.app_green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: AppColors.app_green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Booking Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.app_green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedSteps/4',
                  style: const TextStyle(
                    color: AppColors.app_green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (index) {
              final isCompleted = index < completedSteps;
              final isCurrent = index == completedSteps;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? AppColors.app_green 
                        : isCurrent 
                            ? AppColors.app_green.withOpacity(0.5)
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidInvoicesWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.1),
            AppColors.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.payment,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have unpaid invoices. Please complete payment before making a new booking.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              // Navigate to billing screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Billing()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehicleCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.app_green.withOpacity(0.12),
                  AppColors.app_green.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.app_green.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.app_green.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.app_green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    size: 48,
                    color: AppColors.app_green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No vehicles registered',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your vehicle details to get started with booking services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserVehicleScreen(),
                      ),
                    );
                    _loadData();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Register Vehicle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.app_green,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.app_green.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleSelection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.app_green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: AppColors.app_green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Select Vehicle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (_vehicleNameController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.app_green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _userVehicles.isEmpty ? null : _openVehiclePicker,
            borderRadius: BorderRadius.circular(18),
            child: IgnorePointer(
              child: TextFormField(
                controller: _vehicleNameController,
                readOnly: true,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Please select your vehicle';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: _userVehicles.isEmpty ? 'No vehicles found' : 'Choose your vehicle',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  suffixIcon: const Icon(Icons.directions_car, color: AppColors.app_green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide(color: AppColors.app_green, width: 2.5),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide(color: Color(0xFFE74C3C), width: 1.5),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide(color: Color(0xFFE74C3C), width: 2.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final hasValue = controller.text.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (prefixIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.app_green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: AppColors.app_green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (hasValue)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.app_green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onTap,
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              readOnly: readOnly,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                ),
                suffixIcon: suffixIcon != null 
                    ? Icon(
                        suffixIcon,
                        color: AppColors.app_green.withOpacity(0.7),
                        size: 20,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.app_green, width: 2.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build multiple category selection dropdowns
  List<Widget> _buildMultipleCategorySelections() {
    List<Widget> widgets = [];
    
    for (int index = 0; index < _categorySelections.length; index++) {
      final selection = _categorySelections[index];
      final isFirstDropdown = index == 0;
      final shouldShow = isFirstDropdown || (index > 0 && _categorySelections[index - 1].isCompleted);
      
      if (shouldShow) {
        widgets.add(_buildSingleCategorySelection(index));
        if (index < _categorySelections.length - 1) {
          widgets.add(const SizedBox(height: 24));
        }
      }
    }
    
    return widgets;
  }

  Widget _buildSingleCategorySelection(int index) {
    final selection = _categorySelections[index];
    final isEnabled = selection.isEnabled;
    final isCompleted = selection.isCompleted;
    final canBeEnabled = index == 0 || (index > 0 && _categorySelections[index - 1].isCompleted);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: !isEnabled && index > 0 ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: !isEnabled && index > 0 
              ? Colors.grey[300]! 
              : isCompleted 
                  ? AppColors.app_green 
                  : Colors.grey[200]!,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (!isEnabled && index > 0)
                      ? Colors.grey[300]
                      : AppColors.app_green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.build_outlined,
                  color: (!isEnabled && index > 0)
                      ? Colors.grey[600]
                      : AppColors.app_green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Service Category ${index + 1}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: (!isEnabled && index > 0)
                        ? Colors.grey[500]
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.app_green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.app_green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${selection.selectedServices.length}',
                        style: const TextStyle(
                          color: AppColors.app_green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!isEnabled && index > 0 && canBeEnabled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tap to enable',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (index > 0) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _categorySelections.removeAt(index);
                    });
                    _recomputePreviewTotal();
                  },
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          
          // Enable overlay for disabled dropdowns
          if (!isEnabled && index > 0 && canBeEnabled)
            InkWell(
              onTap: () => _enableDropdown(index),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.grey[100],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to enable this category',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Category Selection Dropdown
            DropdownButtonFormField<String>(
              key: ValueKey(selection.category),
              isExpanded: true,
              value: selection.category,
              menuMaxHeight: 250,
              dropdownColor: Colors.white,
              selectedItemBuilder: (context) => _serviceCategories
                  .map(
                    (cat) => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.app_green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            BookingService.getCategoryIcon(cat),
                            width: 16,
                            height: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cat,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
              items: _serviceCategories
                  .where((cat) => !_categorySelections.any((sel) => sel.category == cat && sel != selection))
                  .map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 60),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.app_green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.asset(
                                BookingService.getCategoryIcon(cat),
                                width: 16,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.category,
                                    size: 16,
                                    color: AppColors.app_green,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                cat,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isEnabled ? (value) async {
                if (value != null) {
                  setState(() {
                    selection.category = value;
                    selection.selectedServices = [];
                    _serviceTypeController.clear();
                    _previewTotal = 0.0;
                  });
                  await _loadServiceTypes(value, index);
                  if (!mounted) return;
                  setState(() {});
                  _updateCategorySelections();
                }
              } : null,
              decoration: InputDecoration(
                hintText: 'Choose service category',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.app_green, width: 2.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
            ),
            
            // Service Types Selection (if category is selected)
            if (selection.category != null && _serviceTypesByCategory[selection.category] != null) ...[
              const SizedBox(height: 20),
              _buildServiceTypesSelection(index),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildServiceTypesSelection(int categoryIndex) {
    final selection = _categorySelections[categoryIndex];
    final serviceTypes = _serviceTypesByCategory[selection.category] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.checklist, color: AppColors.app_green, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Select Services',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (selection.selectedServices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.app_green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selection.selectedServices.length} selected',
                  style: const TextStyle(
                    color: AppColors.app_green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: serviceTypes.isEmpty ? null : () => _openServiceTypesPicker(categoryIndex),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(
                color: selection.selectedServices.isEmpty 
                    ? Colors.grey[200]! 
                    : AppColors.app_green,
                width: selection.selectedServices.isEmpty ? 1.5 : 2.5,
              ),
              borderRadius: BorderRadius.circular(18),
              color: selection.selectedServices.isEmpty 
                  ? Colors.grey[50] 
                  : AppColors.app_green.withOpacity(0.08),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selection.selectedServices.isEmpty
                            ? (serviceTypes.isEmpty ? 'No services available' : 'Tap to select services')
                            : selection.selectedServices.length == 1
                                ? selection.selectedServices.first
                                : '${selection.selectedServices.length} services selected',
                        style: TextStyle(
                          color: selection.selectedServices.isEmpty
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: selection.selectedServices.isEmpty 
                              ? FontWeight.w500 
                              : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selection.selectedServices.length > 1) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: selection.selectedServices.take(3).map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.app_green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.app_green.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                service.length > 15 ? '${service.substring(0, 15)}...' : service,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.app_green,
                                ),
                              ),
                            );
                          }).toList()
                            ..addAll(selection.selectedServices.length > 3 ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${selection.selectedServices.length - 3} more',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              )
                            ] : []),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selection.selectedServices.isEmpty 
                        ? Colors.grey[300] 
                        : AppColors.app_green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selection.selectedServices.isEmpty ? Icons.tune : Icons.check_circle,
                    color: selection.selectedServices.isEmpty 
                        ? Colors.grey[600] 
                        : Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Service types picker for specific category
  Future<void> _openServiceTypesPicker(int categoryIndex) async {
    final selection = _categorySelections[categoryIndex];
    final options = _serviceTypesByCategory[selection.category] ?? [];
    final selectedSet = Set<String>.from(selection.selectedServices);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return DraggableScrollableSheet(
              initialChildSize: MediaQuery.of(context).size.height > 600 ? 0.7 : 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.app_green.withOpacity(0.1),
                              AppColors.app_green.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.app_green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: AppColors.app_green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Services',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  if (selection.category != null)
                                    Text(
                                      selection.category!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedSet.isEmpty 
                                    ? Colors.grey[100] 
                                    : AppColors.app_green,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: selectedSet.isEmpty ? null : [
                                  BoxShadow(
                                    color: AppColors.app_green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selectedSet.isEmpty ? Icons.shopping_cart_outlined : Icons.check_circle,
                                    color: selectedSet.isEmpty ? Colors.grey[600] : Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${selectedSet.length}',
                                    style: TextStyle(
                                      color: selectedSet.isEmpty ? Colors.grey[600] : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Service list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final item = options[index];
                            final checked = selectedSet.contains(item);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: checked ? AppColors.app_green : Colors.grey[200]!,
                                  width: checked ? 2.5 : 1.5,
                                ),
                                color: checked 
                                    ? AppColors.app_green.withOpacity(0.08)
                                    : Colors.white,
                                boxShadow: checked ? [
                                  BoxShadow(
                                    color: AppColors.app_green.withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ] : [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: FutureBuilder<double?>(
                                future: BookingService.getServicePriceByName(item),
                                builder: (context, snapshot) {
                                  final price = snapshot.data ?? 0.0;
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setLocalState(() {
                                          if (checked) {
                                            selectedSet.remove(item);
                                          } else {
                                            selectedSet.add(item);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Service icon
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: checked 
                                                    ? AppColors.app_green 
                                                    : Colors.grey[100],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                checked ? Icons.check : Icons.build,
                                                color: checked ? Colors.white : Colors.grey[600],
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Service details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    item,
                                                    style: TextStyle(
                                                      fontWeight: checked ? FontWeight.w700 : FontWeight.w600,
                                                      color: checked ? AppColors.app_green : const Color(0xFF1A1A1A),
                                                      fontSize: 15,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Price with better formatting
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: checked 
                                                          ? AppColors.app_green.withOpacity(0.1) 
                                                          : Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: checked ? AppColors.app_green : Colors.grey[300]!,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'RM ${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        color: checked ? AppColors.app_green : Colors.grey[700],
                                                        fontSize: 12,
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
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Bottom actions
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          24, 
                          16, 
                          24, 
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, null),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[400]!, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: ElevatedButton(
                                  onPressed: selectedSet.isEmpty 
                                      ? null 
                                      : () => Navigator.pop(context, selectedSet.toList()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: selectedSet.isEmpty 
                                        ? Colors.grey[300] 
                                        : AppColors.app_green,
                                    foregroundColor: Colors.white,
                                    elevation: selectedSet.isEmpty ? 0 : 8,
                                    shadowColor: AppColors.app_green.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        selectedSet.isEmpty ? Icons.touch_app : Icons.check_circle,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          selectedSet.isEmpty ? 'Select' : 'Confirm (${selectedSet.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selection.selectedServices = result;
      });
      _updateCategorySelections();
      await _recomputePreviewTotal();
    }
  }

  Widget _buildDateTimeSelection() {
    final isSelected = _selectedDateTime != DateTime.now().add(const Duration(days: 1));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.app_green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.app_green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Preferred Date & Time',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.app_green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.app_green : Colors.grey[200]!,
                  width: isSelected ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(18),
                color: isSelected 
                    ? AppColors.app_green.withOpacity(0.08) 
                    : Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSelected
                              ? 'Selected Date & Time'
                              : 'Select your preferred date & time',
                          style: TextStyle(
                            color: isSelected 
                                ? AppColors.app_green 
                                : const Color(0xFF94A3B8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSelected
                              ? '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} at ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}'
                              : 'Tap to choose',
                          style: TextStyle(
                            color: isSelected 
                                ? const Color(0xFF1A1A1A) 
                                : const Color(0xFF94A3B8),
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.app_green 
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Time restrictions info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.app_green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.app_green.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.app_green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Time Restrictions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.app_green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Bookings must be made at least 1 day in advance\n• Available times: 9:00 AM - 8:00 PM',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.app_green.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
  // Calculate total selected services across all categories
  int totalSelectedServices = 0;
  for (final selection in _categorySelections) {
    totalSelectedServices += selection.selectedServices.length;
  }
  
  return AnimatedBuilder(
    animation: _pulseAnimation,
    builder: (context, child) {
      return Transform.scale(
        scale: _isLoading ? 1.0 : _pulseAnimation.value,
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isLoading 
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [AppColors.app_green, AppColors.app_green],
            ),
            boxShadow: _isLoading ? null : [
              BoxShadow(
                color: AppColors.app_green.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (_isLoading || _hasUnpaidInvoices) ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Flexible(
                        child: Text(
                          'Processing your booking...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : _hasUnpaidInvoices
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payment,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Complete Payment First',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          totalSelectedServices > 0 ? Icons.check_circle : Icons.shopping_cart,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Book Service Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_previewTotal > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'RM ${_previewTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (totalSelectedServices > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 80),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalSelectedServices',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      );
    },
  );
}
}