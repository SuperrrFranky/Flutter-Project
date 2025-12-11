import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/vehicle_model.dart';
import '../models/user_model.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  static const String _bookingsCollection = 'bookings';
  // Service data now sourced from `services` collection
  static const String _servicesCollection = 'services';
  static const String _vehicleTypesCollection = 'vehicleTypes';
  static const String _vehiclesCollection = 'vehicles';

  // Get all bookings
  static Future<List<BookingModel>> getAllBookings() async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting bookings: $e');
      return [];
    }
  }

  // Live stream of upcoming bookings for a specific user
  static Stream<List<BookingModel>> getUpcomingBookingsStreamForUser(String userId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .where((b) => b.preferredDateTime.isAfter(now) || b.preferredDateTime.isAtSameMomentAs(now))
          .where((b) {
            final status = b.status.toLowerCase();
            return status == 'pending' || status == 'confirmed' || status == 'booked';
          })
          .toList();
      list.sort((a, b) => a.preferredDateTime.compareTo(b.preferredDateTime));
      return list;
    });
  }

  // Live stream of completed bookings for a specific user
  static Stream<List<BookingModel>> getCompletedBookingsStreamForUser(String userId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort latest completed first by preferredDateTime then createdAt fallback
      list.sort((a, b) {
        final cmp = b.preferredDateTime.compareTo(a.preferredDateTime);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  // Create a new booking
  static Future<BookingModel> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore.collection(_bookingsCollection).add({
        ...booking.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return booking.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  // Update existing booking
  static Future<BookingModel?> updateBooking(BookingModel booking) async {
    try {
      await _firestore
          .collection(_bookingsCollection)
          .doc(booking.id)
          .update({
        ...booking.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return booking;
    } catch (e) {
      print('Error updating booking: $e');
      return null;
    }
  }

  // Delete booking
  static Future<bool> deleteBooking(String id) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting booking: $e');
      return false;
    }
  }

  // Get booking by ID
  static Future<BookingModel?> getBookingById(String id) async {
    try {
      final doc = await _firestore
          .collection(_bookingsCollection)
          .doc(id)
          .get();
      
      if (doc.exists) {
        return BookingModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting booking by ID: $e');
      return null;
    }
  }

  // Get vehicle types
  static Future<List<String>> getVehicleTypes() async {
    try {
      final doc = await _firestore
          .collection(_vehicleTypesCollection)
          .doc('types')
          .get();
      
      if (doc.exists && doc.data() != null) {
        return List<String>.from(doc.data()!['types'] ?? []);
      }
      
      return [];
    } catch (e) {
      print('Error getting vehicle types: $e');
      return [];
    }
  }

  // Get all service types (distinct service names) from services
  static Future<List<String>> getServiceTypes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_servicesCollection)
          .get();

      final serviceNames = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final name = data['serviceName'];
        if (name is String && name.trim().isNotEmpty) {
          serviceNames.add(name);
        }
      }

      return serviceNames.toList();
    } catch (e) {
      print('Error getting service types: $e');
      return [];
    }
  }

  // Get service categories (distinct) from services collection
  static Future<List<String>> getServiceCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_servicesCollection)
          .get();

      final categories = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['serviceCategory'];
        if (category is String && category.trim().isNotEmpty) {
          categories.add(category);
        }
      }

      final list = categories.toList();
      list.sort();
      return list;
    } catch (e) {
      print('Error getting service categories: $e');
      return [];
    }
  }

  // Get service types by category (service names filtered by serviceCategory)
  static Future<List<String>> getServiceTypesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_servicesCollection)
          .where('serviceCategory', isEqualTo: category)
          .get();

      final names = <String>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final name = data['serviceName'];
        if (name is String && name.trim().isNotEmpty) {
          names.add(name);
        }
      }

      final list = names.toList();
      list.sort();
      return list;
    } catch (e) {
      print('Error getting service types by category: $e');
      return [];
    }
  }


  // Get registered vehicles for a user
  static Future<List<VehicleModel>> getUserVehicles(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .get();

      return query.docs.map((doc) => VehicleModel.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting user vehicles: $e');
      return [];
    }
  }

  // Get current user data
  static Future<UserModel?> getCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get rate multiplier for a vehicle type
  static double getVehicleRate(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return 1.0; // Base rate
      case 'motorcycle':
        return 0.8; // 20% cheaper
      case 'truck':
        return 1.5; // 50% more expensive
      case 'van':
        return 1.3; // 30% more expensive
      case 'suv':
        return 1.2; // 20% more expensive
      case 'bus':
        return 2.0; // 100% more expensive
      case 'other':
        return 1.0; // Default rate
      default:
        return 1.0; // Default fallback
    }
  }

  // Get base price for a service by name
  static Future<double?> getServicePriceByName(String serviceName) async {
    try {
      final q = await _firestore
          .collection(_servicesCollection)
          .where('serviceName', isEqualTo: serviceName)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return null;
      final data = q.docs.first.data();
      final price = data['price'];
      if (price is num) return price.toDouble();
      return null;
    } catch (e) {
      print('Error getting service price: $e');
      return null;
    }
  }

  // Get icon path for service category (matches dashboard icons)
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cleaning':
        return 'assets/images/ui/dashboard/cleaning.png';
      case 'carpenter':
        return 'assets/images/ui/dashboard/carpenter.png';
      case 'repairing':
        return 'assets/images/ui/dashboard/repairing.png';
      case 'checking':
        return 'assets/images/ui/dashboard/checking.png';
      case 'oil change':
        return 'assets/images/ui/dashboard/service_oil_change.png';
      case 'battery':
        return 'assets/images/ui/dashboard/battery.png';
      default:
        return 'assets/images/ui/dashboard/cleaning.png'; // default fallback
    }
  }

  // Check if user has any unpaid invoices
  static Future<bool> hasUnpaidInvoices(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'unpaid')
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking unpaid invoices: $e');
      return false; // Allow booking if there's an error checking
    }
  }
}
