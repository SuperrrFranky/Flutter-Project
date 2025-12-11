import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../menu/menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final PageController _bannerController = PageController(viewportFraction: 1.0);
  final TextEditingController _searchController = TextEditingController();
  int _currentBannerIndex = 0;
  String _searchQuery = '';
  bool _isSearching = false;
  String? _userDisplayName;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // List of all available services
  final List<Map<String, String>> _allServices = [
    {'title': 'Cleaning', 'image': 'assets/images/ui/dashboard/cleaning.png'},
    {'title': 'Carpenter', 'image': 'assets/images/ui/dashboard/carpenter.png'},
    {'title': 'Repairing', 'image': 'assets/images/ui/dashboard/repairing.png'},
    {'title': 'Checking', 'image': 'assets/images/ui/dashboard/checking.png'},
    {'title': 'Oil Change', 'image': 'assets/images/ui/dashboard/service_oil_change.png'},
    {'title': 'Battery', 'image': 'assets/images/ui/dashboard/battery.png'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    loadUserName();
    _setupUserListener();
  }

  void _setupUserListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data();
          if (data != null) {
            final userName = (data['user_name'] as String?)?.trim();
            if (userName != null && userName.isNotEmpty) {
              setState(() {
                _userDisplayName = userName;
              });
            }
          }
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh username when returning to dashboard
    loadUserName();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh username when widget is updated
    loadUserName();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  Future<void> loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _userDisplayName = null);
        return;
      }

      // Prefer FirebaseAuth displayName if available
      String? name = user.displayName;

      // Fallback to Firestore users/{uid}.user_name
      if (name == null || name.trim().isEmpty) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final fsName = (data['user_name'] as String?)?.trim();
            if (fsName != null && fsName.isNotEmpty) {
              name = fsName;
            }
          }
        }
      }

      setState(() => _userDisplayName = name);
    } catch (_) {
      // Keep silent; UI will show generic welcome
    }
  }


  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      body: GestureDetector(
        onTap: () {
          // Unfocus the search field when tapping elsewhere
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              if (!_isSearching) ...[
                _buildBannerCarousel(),
                const SizedBox(height: 20),
                _buildBannerDots(),
                const SizedBox(height: 20),
                _buildServicesGrid(),
              ] else ...[
                _buildSearchResults(),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: const BoxDecoration(
        color: AppColors.app_green,
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/ui/dashboard/profile_avatar.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Green System Business Software Sdn Bhd',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 2.2,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const _MenuRouteWrapper()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Welcome message
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _userDisplayName == null || _userDisplayName!.isEmpty
                      ? 'Welcome'
                      : 'Welcome, ' + _userDisplayName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(width: 17),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final List<String> banners = const [
      'assets/images/ui/dashboard/banner_image.png',
      'assets/images/ui/dashboard/banner2_image.png',
      'assets/images/ui/dashboard/banner4_image.png',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      height: 156,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF132C4A).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: PageView.builder(
          controller: _bannerController,
          itemCount: banners.length,
          onPageChanged: (index) {
            setState(() {
              _currentBannerIndex = index;
            });
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildFirstPromoBanner();
            }
            return Image.asset(banners[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity);
          },
        ),
      ),
    );
  }

  Widget _buildFirstPromoBanner() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.app_green,
      ),
      child: Stack(
        children: [
          // Background circle
          Align(
            alignment: const Alignment(0.3, -0.5),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8130AC).withOpacity(0.35),
              ),
            ),
          ),
          // Content column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 13),
              const Padding(
                padding: EdgeInsets.only(left: 21),
                child: Text(
                  '✨ Your Car Deserves the Best',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
              ),
              const SizedBox(height: 19),
              const Padding(
                padding: EdgeInsets.only(left: 22),
                child: Text(
                  'Professional Car Services • Affordable • Reliable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 22),
                child: Container(
                  width: 120,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Center(
                    child: Text(
                      'Book services',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Source Sans Pro',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Banner image
          Align(
            alignment: const Alignment(0.8, 0.5),
            child: SizedBox(
              width: 143,
              height: 56,
              child: Image.asset(
                'assets/images/ui/dashboard/banner_image.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerDots() {
    final int length = 3;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final bool isActive = index == _currentBannerIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 16 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.black : const Color(0xFFE3E1E8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }


  Widget _buildServicesGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      height: 248,
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
      child: Column(
        children: [
          const SizedBox(height: 20),
          // First row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceCard('Cleaning', 'assets/images/ui/dashboard/cleaning.png'),
              _buildServiceCard('Carpenter', 'assets/images/ui/dashboard/carpenter.png'),
              _buildServiceCard('Repairing', 'assets/images/ui/dashboard/repairing.png'),
            ],
          ),
          const SizedBox(height: 25),
          // Second row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildServiceCard('Checking', 'assets/images/ui/dashboard/checking.png'),
                _buildServiceCard('Oil Change', 'assets/images/ui/dashboard/service_oil_change.png'),
                _buildServiceCard('Battery', 'assets/images/ui/dashboard/battery.png'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Filter services based on search query
    final filteredServices = _allServices.where((service) {
      return service['title']!.toLowerCase().contains(_searchQuery);
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
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
      child: filteredServices.isEmpty
          ? _buildNoResultsMessage()
          : _buildSearchResultsGrid(filteredServices),
    );
  }

  Widget _buildNoResultsMessage() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 50,
              color: Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No services found for "$_searchQuery"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsGrid(List<Map<String, String>> services) {
    // Calculate rows needed
    int rows = (services.length / 3).ceil();
    double height = 20 + (rows * 89) + ((rows - 1) * 25) + 20; // top padding + cards + gaps + bottom padding
    
    return Container(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 20),
          ...List.generate(rows, (rowIndex) {
            int startIndex = rowIndex * 3;
            int endIndex = (startIndex + 3 > services.length) ? services.length : startIndex + 3;
            List<Map<String, String>> rowServices = services.sublist(startIndex, endIndex);
            
            return Column(
              children: [
                if (rowIndex > 0) const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...rowServices.map((service) => _buildServiceCard(service['title']!, service['image']!)),
                    // Add empty containers to maintain spacing if less than 3 items
                    ...List.generate(3 - rowServices.length, (index) => const SizedBox(width: 94)),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String imagePath) {
    return Container(
      width: 94,
      height: 89,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9.71),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 49,
            height: 47,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.build,
                  color: AppColors.app_green,
                  size: 30,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}

// Lightweight indirection to avoid circular import surprises in hot reload
class _MenuRouteWrapper extends StatelessWidget {
  const _MenuRouteWrapper();
  @override
  Widget build(BuildContext context) => const MenuScreen();
}
