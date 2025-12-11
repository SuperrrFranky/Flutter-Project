import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/bottom_navbar.dart';
import 'car_services_details.dart';
import 'completed_service_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking_model.dart';
import '../../../models/invoice_model.dart';
import '../../../services/booking_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarServicesScreen extends StatefulWidget {
  const CarServicesScreen({super.key});

  @override
  State<CarServicesScreen> createState() => _CarServicesScreenState();
}

class _CarServicesScreenState extends State<CarServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearchResults = true;
  String _searchQuery = '';
  final Set<String> _upcomingSelectedCategories = <String>{};
  final Set<String> _completedSelectedCategories = <String>{};
  List<String> _allCategories = const [];
  DateTime? _upcomingSelectedDate;
  DateTime? _completedSelectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(_onTabChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Rebuild to update per-tab indicators and counts when swiping between tabs
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadCategories() async {
    final list = await BookingService.getServiceCategories();
    setState(() => _allCategories = list);
  }

  Future<Invoice?> _getInvoiceForBooking(String bookingId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['invoiceId'] = doc.id; // Add the document ID as invoiceId
        return Invoice.fromJson(data);
      }
    } catch (e) {
      print('Error fetching invoice: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      body: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildAllCountSection(),
          const SizedBox(height: 5),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildPassTab(),
              ],
            ),
          ),
          BottomNavbar(
            currentIndex: 1, // Services tab
            onTap: (index) {
              if (index != 1) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 22, right: 22, bottom: 20),
      child: Column(
        children: [
          // First row - Back button and title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF282828)),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'All Services',
                    style: TextStyle(
                      color: Color(0xFF282828),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 20),
          // Second row - Tabs (Upcoming and Pass)
          Row(
            children: [
              const SizedBox(width: 50), // Align with design
              _buildTab('Upcoming', 0),
              const SizedBox(width: 115),
              _buildTab('Pass', 1),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 7),
          // Animated tab indicator
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              // Calculate the position based on animation value for smooth movement
              double startPosition = 41; // Position for "Upcoming" tab
              double endPosition = 215;  // Position for "Pass" tab (moved more to the right)
              double currentPosition = startPosition + (_tabController.animation!.value * (endPosition - startPosition));
              
              return Stack(
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: Colors.transparent,
                  ),
                  Positioned(
                    left: currentPosition,
                    child: Container(
                      height: 2,
                      width: 93,
                      color: const Color(0xFF282828),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 31,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 17),
                  Icon(
                    Icons.search,
                    color: const Color(0xFF0F0F0F).withOpacity(0.3),
                    size: 19,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 31,
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search.....',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.3),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _openFilterSheetForCurrentTab,
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.app_green,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF132C4A).withOpacity(0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Offstage(
                    offstage: !((_tabController.index == 0 && _upcomingSelectedCategories.isNotEmpty) || (_tabController.index == 1 && _completedSelectedCategories.isNotEmpty)),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _onDateIconTapped,
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.app_green,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF132C4A).withOpacity(0.02),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Offstage(
                    offstage: !((_tabController.index == 0 && _upcomingSelectedDate != null) || (_tabController.index == 1 && _completedSelectedDate != null)),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
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
  }

  Widget _buildAllCountSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StreamBuilder<List<BookingModel>>(
            stream: _tabController.index == 0
                ? BookingService.getUpcomingBookingsStreamForUser(user.uid)
                : BookingService.getCompletedBookingsStreamForUser(user.uid),
            builder: (context, snapshot) {
              final list = snapshot.data ?? const <BookingModel>[];
              final filtered = _tabController.index == 0
                  ? _applyFilters(list, _searchQuery, _upcomingSelectedCategories, _upcomingSelectedDate)
                  : _applyFilters(list, _searchQuery, _completedSelectedCategories, _completedSelectedDate);
              return Text(
                'All (' + filtered.length.toString() + ')',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFF282828) : Colors.black.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return _UpcomingBookingsList(
      searchQuery: _searchQuery,
      selectedCategories: _upcomingSelectedCategories,
      selectedDate: _upcomingSelectedDate,
    );
  }

  List<BookingModel> _applyFilters(List<BookingModel> source, String query, Set<String> selected, DateTime? selectedDate) {
    final q = query.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;
    final hasCat = selected.isNotEmpty;
    final hasDate = selectedDate != null;
    return source.where((b) {
      bool matchQuery = true;
      if (hasQuery) {
        matchQuery = (b.vehicleName.toLowerCase().contains(q)) ||
            (b.serviceType.toLowerCase().contains(q));
      }
      bool matchCat = true;
      if (hasCat) {
        final cats = _extractCategoriesFromBooking(b).map((e) => e.toLowerCase()).toSet();
        matchCat = selected.any((s) => cats.contains(s.toLowerCase()));
      }
      bool matchDate = true;
      if (hasDate) {
        matchDate = _isSameDay(b.preferredDateTime, selectedDate!);
      }
      return matchQuery && matchCat && matchDate;
    }).toList();
  }

  List<String> _extractCategoriesFromBooking(BookingModel booking) {
    final set = <String>{};
    for (final item in booking.serviceBreakdown) {
      final cat = (item['category'] as String?)?.trim();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }

  void _openFilterSheetForCurrentTab() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final isUpcoming = _tabController.index == 0;
        final temp = Set<String>.from(isUpcoming ? _upcomingSelectedCategories : _completedSelectedCategories);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (_allCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allCategories.map((c) {
                        final selected = temp.contains(c);
                        return FilterChip(
                          selected: selected,
                          label: Text(c),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) temp.add(c); else temp.remove(c);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() => temp.clear());
                        },
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (isUpcoming) {
                              _upcomingSelectedCategories
                                ..clear()
                                ..addAll(temp);
                            } else {
                              _completedSelectedCategories
                                ..clear()
                                ..addAll(temp);
                            }
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDatePickerForCurrentTab() async {
    final isUpcoming = _tabController.index == 0;
    final now = DateTime.now();
    final current = isUpcoming ? _upcomingSelectedDate : _completedSelectedDate;
    final initial = current ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        final onlyDate = DateTime(picked.year, picked.month, picked.day);
        if (isUpcoming) {
          _upcomingSelectedDate = onlyDate;
        } else {
          _completedSelectedDate = onlyDate;
        }
      });
    }
  }

  void _onDateIconTapped() async {
    final isUpcoming = _tabController.index == 0;
    final hasDate = isUpcoming ? _upcomingSelectedDate != null : _completedSelectedDate != null;
    if (!hasDate) {
      await _openDatePickerForCurrentTab();
      return;
    }
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 150, 0, 0),
      items: const [
        PopupMenuItem<String>(value: 'change', child: Text('Change date')),
        PopupMenuItem<String>(value: 'clear', child: Text('Clear date')),
      ],
    );
    if (selected == 'change') {
      await _openDatePickerForCurrentTab();
    } else if (selected == 'clear') {
      setState(() {
        if (isUpcoming) {
          _upcomingSelectedDate = null;
        } else {
          _completedSelectedDate = null;
        }
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildPassTab() {
    return _CompletedBookingsList(
      searchQuery: _searchQuery,
      selectedCategories: _completedSelectedCategories,
      selectedDate: _completedSelectedDate,
      getInvoiceForBooking: _getInvoiceForBooking,
    );
  }

  Widget _buildNoResultsUI() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Illustration
              Container(
                width: 194,
                height: 194,
                child: Image.asset(
                  'assets/images/ui/no_results_illustration.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback illustration matching the Figma design
                    return Container(
                      width: 194,
                      height: 194,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(97),
                      ),
                      child: Stack(
                        children: [
                          // Background circle
                          Center(
                            child: Container(
                              width: 155,
                              height: 155,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(77.5),
                              ),
                            ),
                          ),
                          // Document/page illustration
                          Positioned(
                            left: 53,
                            top: 40,
                            child: Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 32,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(4, (index) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    width: 60,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4D4D4),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                          // Search magnifying glass
                          Positioned(
                            right: 20,
                            bottom: 30,
                            child: Container(
                              width: 80,
                              height: 80,
                              child: Stack(
                                children: [
                                  // Magnifying glass circle
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFCCC6D9),
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  // Handle
                                  Positioned(
                                    right: 5,
                                    bottom: 5,
                                    child: Container(
                                      width: 25,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE1DCEB),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      transform: Matrix4.rotationZ(0.785398), // 45 degrees
                                    ),
                                  ),
                                  // X mark inside magnifying glass
                                  Positioned(
                                    left: 20,
                                    top: 20,
                                    child: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // "No search results" title
              const Text(
                'No search results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF303030),
                  fontFamily: 'Roboto Flex',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description text
              Text(
                'You have no upcoming services in "${_searchQuery.isEmpty ? 'Search' : _searchQuery}"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                  height: 1.3,
                  fontFamily: 'Roboto Flex',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedServiceCard({
    required String carNumber,
    required String date,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row: Title and Completed badge
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontFamily: 'Roboto Flex',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0F9918)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F9918),
                            fontFamily: 'Roboto Flex',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Second row: View button, Car plate, and Date/time
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // For this case, we need the booking ID to fetch invoice
                          // Since we don't have it here, we'll show a message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please use the View button in the completed services tab for detailed invoice information.'),
                            ),
                          );
                        },
                        child: Container(
                          width: 105,
                          height: 21.36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCFCFCF)),
                          ),
                          child: const Center(
                            child: Text(
                              'View',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Source Sans Pro',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Car plate : $carNumber',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withOpacity(0.5),
                          fontFamily: 'Roboto Flex',
                        ),
                      ),
                      const SizedBox(width: 50),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withOpacity(0.3),
                          fontFamily: 'Roboto Flex',
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
    );
  }

  Widget _buildPaginationComponent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button (disabled)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFBEBEBE)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.keyboard_arrow_left,
            color: Colors.black.withOpacity(0.3),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        // Page 1 (selected)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF7373EF)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              '1',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7373EF),
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Page 2
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFBEBEBE)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              '2',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Ellipsis
        Container(
          width: 40,
          height: 40,
          child: const Center(
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Page 99
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFBEBEBE)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              '99',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Next button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFBEBEBE)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.keyboard_arrow_right,
            color: Colors.black,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String carNumber,
    required String imagePath,
    required bool isUpcoming,
  }) {
    return Container(
      width: double.infinity,
      height: 122,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 19),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 13),
              Text(
                carNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontFamily: 'Source Sans Pro',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Car services',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CarServicesDetailsScreen(
                        booking: BookingModel(
                          userId: '',
                          vehicleType: 'Proton X50',
                          vehicleName: carNumber,
                          phoneNumber: '',
                          serviceType: 'Car services',
                          serviceTypes: const [],
                          preferredDateTime: DateTime.now(),
                          totalAmount: 0.0,
                          serviceBreakdown: const [],
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 105,
                  height: 21.36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCFCFCF)),
                  ),
                  child: const Center(
                    child: Text(
                      'View',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Source Sans Pro',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              Container(
                width: 148,
                height: 93,
                margin: const EdgeInsets.only(right: 21, top: 14, bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_car,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // Placeholder for actual car image
              Container(
                width: 86,
                height: 78,
                margin: const EdgeInsets.only(right: 47, top: 22, bottom: 22),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingBookingsList extends StatefulWidget {
  final String searchQuery;
  final Set<String> selectedCategories;
  final DateTime? selectedDate;
  const _UpcomingBookingsList({this.searchQuery = '', this.selectedCategories = const {}, this.selectedDate});

  @override
  State<_UpcomingBookingsList> createState() => _UpcomingBookingsListState();
}

class _UpcomingBookingsListState extends State<_UpcomingBookingsList> {
  static const int _pageSize = 10;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load bookings',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          );
        }
        final all = _applyFilters(snapshot.data ?? const <BookingModel>[]);
        if (all.isEmpty) {
          return Center(
            child: Text(
              'No upcoming bookings',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          );
        }

        final totalPages = (all.length / _pageSize).ceil().clamp(1, 9999);
        _currentPage = _currentPage.clamp(1, totalPages);
        final start = (_currentPage - 1) * _pageSize;
        final end = (start + _pageSize).clamp(0, all.length);
        final pageItems = all.sublist(start, end);

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pageItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return _ServiceCardFromBooking(booking: pageItems[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<List<BookingModel>> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream<List<BookingModel>>.empty();
    return BookingService.getUpcomingBookingsStreamForUser(user.uid);
  }

  List<BookingModel> _applyFilters(List<BookingModel> source) {
    final q = widget.searchQuery.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;
    final hasCat = widget.selectedCategories.isNotEmpty;
    final hasDate = widget.selectedDate != null;
    return source.where((b) {
      bool matchQuery = true;
      if (hasQuery) {
        matchQuery = (b.vehicleName.toLowerCase().contains(q)) ||
            (b.serviceType.toLowerCase().contains(q));
      }
      bool matchCat = true;
      if (hasCat) {
        final cats = _extractCategories(b).map((e) => e.toLowerCase()).toSet();
        matchCat = widget.selectedCategories.any((s) => cats.contains(s.toLowerCase()));
      }
      bool matchDate = true;
      if (hasDate) {
        matchDate = b.preferredDateTime.year == widget.selectedDate!.year &&
            b.preferredDateTime.month == widget.selectedDate!.month &&
            b.preferredDateTime.day == widget.selectedDate!.day;
      }
      return matchQuery && matchCat && matchDate;
    }).toList();
  }

  List<String> _extractCategories(BookingModel booking) {
    final set = <String>{};
    for (final item in booking.serviceBreakdown) {
      final cat = (item['category'] as String?)?.trim();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }
}

class _CompletedBookingsList extends StatefulWidget {
  final String searchQuery;
  final Set<String> selectedCategories;
  final DateTime? selectedDate;
  final Future<Invoice?> Function(String) getInvoiceForBooking;
  const _CompletedBookingsList({
    this.searchQuery = '', 
    this.selectedCategories = const {}, 
    this.selectedDate,
    required this.getInvoiceForBooking,
  });

  @override
  State<_CompletedBookingsList> createState() => _CompletedBookingsListState();
}

class _CompletedBookingsListState extends State<_CompletedBookingsList> {
  static const int _pageSize = 10;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: _stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load completed services',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          );
        }

        final all = _applyFilters(snapshot.data ?? const <BookingModel>[]);
        if (all.isEmpty) {
          return Center(
            child: Text(
              'No completed services',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          );
        }

        final totalPages = (all.length / _pageSize).ceil().clamp(1, 9999);
        _currentPage = _currentPage.clamp(1, totalPages);
        final start = (_currentPage - 1) * _pageSize;
        final end = (start + _pageSize).clamp(0, all.length);
        final pageItems = all.sublist(start, end);

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pageItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final b = pageItems[index];
                  return _CompletedServiceItem(
                    booking: b,
                    getInvoiceForBooking: widget.getInvoiceForBooking,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                onPageChanged: (p) => setState(() => _currentPage = p),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<List<BookingModel>> _stream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream<List<BookingModel>>.empty();
    return BookingService.getCompletedBookingsStreamForUser(user.uid);
  }

  List<BookingModel> _applyFilters(List<BookingModel> source) {
    final q = widget.searchQuery.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;
    final hasCat = widget.selectedCategories.isNotEmpty;
    final hasDate = widget.selectedDate != null;
    return source.where((b) {
      bool matchQuery = true;
      if (hasQuery) {
        matchQuery = (b.vehicleName.toLowerCase().contains(q)) ||
            (b.serviceType.toLowerCase().contains(q));
      }
      bool matchCat = true;
      if (hasCat) {
        final cats = _extractCategories(b).map((e) => e.toLowerCase()).toSet();
        matchCat = widget.selectedCategories.any((s) => cats.contains(s.toLowerCase()));
      }
      bool matchDate = true;
      if (hasDate) {
        matchDate = b.preferredDateTime.year == widget.selectedDate!.year &&
            b.preferredDateTime.month == widget.selectedDate!.month &&
            b.preferredDateTime.day == widget.selectedDate!.day;
      }
      return matchQuery && matchCat && matchDate;
    }).toList();
  }

  List<String> _extractCategories(BookingModel booking) {
    final set = <String>{};
    for (final item in booking.serviceBreakdown) {
      final cat = (item['category'] as String?)?.trim();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.toList();
  }
}

class _CompletedServiceItem extends StatelessWidget {
  final BookingModel booking;
  final Future<Invoice?> Function(String) getInvoiceForBooking;
  const _CompletedServiceItem({
    required this.booking,
    required this.getInvoiceForBooking,
  });

  @override
  Widget build(BuildContext context) {
    final date = booking.preferredDateTime;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title matches position/style of upcoming, but wording differs
                      Text(
                        booking.vehicleName.isNotEmpty ? booking.vehicleName : booking.vehicleType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Secondary line mirrors upcoming: categories
                      Text(
                        _categoriesText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusChip(status: booking.status),
                          const SizedBox(width: 10),
                          _OutlineButton(
                            label: 'View',
                            onTap: () async {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              // Fetch invoice data
                              if (booking.id == null) {
                                // Close loading dialog
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid booking ID. Cannot fetch invoice.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              final invoice = await getInvoiceForBooking(booking.id!);
                              
                              // Close loading dialog
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }

                              // Navigate with invoice data
                              if (context.mounted) {
                                if (invoice != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CompletedServiceDetailsScreen(
                                        carNumber: booking.vehicleName.isNotEmpty ? booking.vehicleName : booking.vehicleType,
                                        carModel: booking.vehicleType,
                                        date: _dateLabel(date),
                                        booking: booking,
                                        invoice: invoice, // Pass the invoice data
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show error if no invoice found
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No invoice found for this booking. Please contact support.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _DateBadge(dateTime: date),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  String _dateLabel(DateTime d) {
    return d.day.toString().padLeft(2, '0') + ' ' + _month(d.month) + ' ' + d.year.toString();
  }

  String _categoriesText() {
    final set = <String>{};
    for (final item in booking.serviceBreakdown) {
      final cat = (item['category'] as String?)?.trim();
      if (cat != null && cat.isNotEmpty) set.add(cat);
    }
    return set.isNotEmpty ? set.join(', ') : 'Car services';
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCFCFCF)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Source Sans Pro',
          ),
        ),
      ),
    );
  }
}

class _CompletedPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF0F9918)),
      ),
      child: const Text(
        'Completed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F9918),
          fontFamily: 'Roboto Flex',
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  const _PaginationBar({required this.currentPage, required this.totalPages, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    final canPrev = currentPage > 1;
    final canNext = currentPage < totalPages;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SquareButton(
          icon: Icons.keyboard_arrow_left,
          enabled: canPrev,
          onTap: canPrev ? () => onPageChanged(currentPage - 1) : null,
        ),
        const SizedBox(width: 12),
        _PageChip(number: currentPage, selected: true, onTap: (_) {}),
        if (totalPages >= currentPage + 1) ...[
          const SizedBox(width: 12),
          _PageChip(number: currentPage + 1, selected: false, onTap: onPageChanged),
        ],
        if (totalPages > currentPage + 2) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 36,
            height: 36,
            child: Center(child: Text('...')),
          ),
        ],
        if (totalPages > currentPage + 2) ...[
          const SizedBox(width: 12),
          _PageChip(number: totalPages, selected: false, onTap: onPageChanged),
        ],
        const SizedBox(width: 12),
        _SquareButton(
          icon: Icons.keyboard_arrow_right,
          enabled: canNext,
          onTap: canNext ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _SquareButton({required this.icon, this.enabled = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(enabled ? 0xFFBEBEBE : 0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? Colors.black : Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  final int number;
  final bool selected;
  final ValueChanged<int> onTap;
  const _PageChip({required this.number, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(number),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(selected ? 0xFF7373EF : 0xFFBEBEBE)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(selected ? 0xFF7373EF : 0xFF000000),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime dateTime;
  const _DateBadge({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final weekday = _weekday(dateTime.weekday);
    final time = dateTime.hour.toString().padLeft(2, '0') + ':' + dateTime.minute.toString().padLeft(2, '0');
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            weekday,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(int w) {
    const names = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    // Dart DateTime.weekday: 1=Mon..7=Sun
    return names[(w - 1).clamp(0, 6)];
  }
}
class _ServiceCardFromBooking extends StatelessWidget {
  final BookingModel booking;
  const _ServiceCardFromBooking({required this.booking});

  @override
  Widget build(BuildContext context) {
    final date = booking.preferredDateTime;
    final categories = _extractCategories(booking);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.vehicleName.isNotEmpty ? booking.vehicleName : booking.vehicleType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categories.isNotEmpty ? categories.join(', ') : 'Car services',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusChip(status: booking.status),
                      const SizedBox(width: 10),
                      _OutlineButton(
                        label: 'View',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CarServicesDetailsScreen(booking: booking),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DateBadge(dateTime: date),
          ],
        ),
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[(m - 1).clamp(0, 11)];
  }

  List<String> _extractCategories(BookingModel booking) {
    final set = <String>{};
    for (final item in booking.serviceBreakdown) {
      final cat = (item['category'] as String?)?.trim();
      if (cat != null && cat.isNotEmpty) {
        set.add(_titleCase(cat));
      }
    }
    return set.toList();
  }

  String _titleCase(String s) {
    return s
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    Color border;
    switch (normalized) {
      case 'confirmed':
      case 'booked':
        bg = const Color(0xFFE6F5EC);
        fg = AppColors.app_green;
        border = const Color(0xFFBFE7D0);
        break;
      case 'pending':
        bg = const Color(0xFFFFF4E5);
        fg = const Color(0xFFB26B00);
        border = const Color(0xFFFFE0B2);
        break;
      case 'in progress':
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF1967D2);
        border = const Color(0xFFBDD3FF);
        break;
      case 'completed':
        bg = const Color(0xFFE6F5EC);
        fg = AppColors.app_green;
        border = const Color(0xFFBFE7D0);
        break;
      default:
        bg = const Color(0xFFF1F3F4);
        fg = const Color(0xFF5F6368);
        border = const Color(0xFFE0E0E0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        _labelCase(status),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Source Sans Pro',
        ),
      ),
    );
  }

  String _labelCase(String s) {
    return s
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}
