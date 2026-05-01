import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../models/gym_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../widgets/gym_card.dart';
import '../widgets/animated_login_prompt.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'gym_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? token; // <-- ADDED: Accepts token to fetch profile

  const HomeScreen({super.key, this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  // PROFILE STATE
  String _firstName = '';
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  // Dynamically check if user is logged in based on token presence
  bool get _isLoggedIn => widget.token != null && widget.token!.isNotEmpty;

  // ALL DYNAMIC FUTURES
  late Future<List<PromoBanner>> _futureBanners;
  late Future<List<GymCategory>> _futureCategories;
  late Future<List<Gym>> _futureFeaturedGyms;
  late Future<List<Gym>> _futureAllGyms;

  String _currentLocation = 'Fetching location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _triggerInitialFetches();
    _determinePosition();

    if (_isLoggedIn) {
      _loadUserProfile();
    } else {
      _isLoadingProfile = false;
    }
  }

  // --- FETCH USER PROFILE FROM API ---
  Future<void> _loadUserProfile() async {
    final userData = await _apiService.fetchUserProfile(widget.token!);

    if (mounted && userData != null) {
      setState(() {
        String rawName = userData['first_name'] ?? '';
        _firstName = rawName.isNotEmpty
            ? '${rawName[0].toUpperCase()}${rawName.substring(1)}'
            : 'User';

        _profileImageUrl = userData['profile_image'];
        _isLoadingProfile = false;
      });
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _triggerInitialFetches() {
    _futureBanners = _apiService.fetchBanners();
    _futureCategories = _apiService.fetchCategories();
    _futureFeaturedGyms = _apiService.fetchFeaturedGyms();
    _futureAllGyms = _apiService.fetchGyms();
  }

  Future<void> _refreshData() async {
    setState(() {
      _triggerInitialFetches();
    });
    await _determinePosition();
    if (_isLoggedIn) await _loadUserProfile();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Location Disabled');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('Permission Denied');

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        String state = place.administrativeArea ?? '';
        if (state.isNotEmpty && state.split(' ').length > 1) state = state.split(' ').map((e) => e[0]).join().toUpperCase();
        setState(() {
          _currentLocation = '$city${state.isNotEmpty ? ', $state' : ''}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Kanpur, UP'; // Fallback
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      extendBody: true,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryLight,
        backgroundColor: AppColors.cardBg,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), child: _buildSearchBar()),
              if (!_isLoggedIn) const Padding(padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), child: AnimatedLoginPrompt()),

              _buildBannersSection(),
              const SizedBox(height: 24),

              _buildCategoriesSection(),
              const SizedBox(height: 24),

              Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionHeader('Top Rated Near You', showSeeAll: true)),
              const SizedBox(height: 16),
              _buildFeaturedGymsSection(),
              const SizedBox(height: 32),

              Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0), child: _buildSectionHeader('Explore All Gyms', showSeeAll: false)),
              const SizedBox(height: 16),
              _buildAllGymsSection(),

              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ------------- DYNAMIC SECTIONS ------------- //

  Widget _buildBannersSection() {
    return FutureBuilder<List<PromoBanner>>(
      future: _futureBanners,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(width: 280, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20))))],
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Banner Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent, fontSize: 12)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data!;
        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(color: banner.backgroundColor, borderRadius: BorderRadius.circular(20)),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0, bottom: 0, top: 0, width: 140,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                        child: ShaderMask(
                          shaderCallback: (rect) => LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [banner.backgroundColor, Colors.transparent]).createShader(rect),
                          blendMode: BlendMode.dstOut,
                          child: Image.network(banner.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const SizedBox.shrink()),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(banner.badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 12),
                          SizedBox(width: 160, child: Text(banner.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2), maxLines: 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return FutureBuilder<List<GymCategory>>(
      future: _futureCategories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: AppColors.primaryLight)));
        } else if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Categories Error: ${snapshot.error}", style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 12)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!;
        return SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              String cleanIconName = cat.iconClass.replaceAll('mdi mdi-', '').replaceAll('mdi-', '').trim();
              IconData iconData = MdiIcons.fromString(cleanIconName) ?? Icons.category_rounded;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    Container(
                      height: 60, width: 60,
                      decoration: BoxDecoration(color: AppColors.cardBg, shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
                      child: Icon(iconData, color: AppColors.primaryLight, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(_capitalize(cat.name), style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  Widget _buildFeaturedGymsSection() {
    return FutureBuilder<List<Gym>>(
      future: _futureFeaturedGyms,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (ctx, i) => Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(width: 240, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))),
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Featured Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent, fontSize: 12)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("No featured gyms available right now.", style: TextStyle(color: AppColors.textMuted)));
        }

        final gyms = snapshot.data!;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: gyms.length,
            itemBuilder: (context, index) {
              final gym = gyms[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GymDetailsScreen(gymId: gym.id))),
                child: Container(
                  width: 240, margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(gym.imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Container(height: 120, color: Colors.black26, child: const Icon(Icons.broken_image, color: Colors.white24))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(gym.name, style: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Row(children: [const Icon(Icons.star_rounded, color: AppColors.accent, size: 14), const SizedBox(width: 2), Text(gym.rating > 0 ? gym.rating.toStringAsFixed(1) : 'New', style: const TextStyle(color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.bold))]),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(gym.address, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllGymsSection() {
    return FutureBuilder<List<Gym>>(
      future: _futureAllGyms,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 4,
            itemBuilder: (ctx, i) => Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(height: 110, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))),
          );
        } else if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(40.0), child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent))));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No gyms found in your area.", style: TextStyle(color: AppColors.textMuted))));
        }

        final gyms = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20.0), itemCount: gyms.length,
          itemBuilder: (context, index) {
            return GymCard(gym: gyms[index]);
          },
        );
      },
    );
  }

  // --- TOP BAR & HELPERS ---

  AppBar _buildAppBar() {
    return AppBar(
      toolbarHeight: 80, backgroundColor: Colors.transparent, elevation: 0, titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _isLoggedIn ? AppColors.primaryLight.withOpacity(0.5) : Colors.white10, width: 2)),
            child: CircleAvatar(
              radius: 20, backgroundColor: AppColors.cardBg,
              backgroundImage: _isLoggedIn && _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
              child: (!_isLoggedIn || _profileImageUrl == null) ? const Icon(Icons.person_outline_rounded, color: AppColors.textMuted) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    !_isLoggedIn
                        ? 'Welcome, Guest User 👋'
                        : _isLoadingProfile
                        ? 'Loading profile...'
                        : 'Good Morning, $_firstName 👋',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: _determinePosition,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primaryLight, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _isLoadingLocation
                            ? const Text('Locating...', style: TextStyle(color: AppColors.textMuted, fontSize: 14))
                            : Text(_currentLocation, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (!_isLoadingLocation) Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted.withOpacity(0.8), size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_isLoggedIn)
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.cardBg, shape: BoxShape.circle, border: Border.all(color: Colors.white10)), child: const Icon(Icons.notifications_outlined, color: AppColors.textMain, size: 20)),
                Positioned(top: 8, right: 10, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle, border: Border.all(color: AppColors.cardBg, width: 2)))),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Log In', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 14))),
          )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: const TextField(
        style: TextStyle(color: AppColors.textMain),
        decoration: InputDecoration(hintText: 'Search gyms, classes, or trainers...', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14), border: InputBorder.none, icon: Icon(Icons.search_rounded, color: AppColors.textMuted)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool showSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textMain, letterSpacing: -0.5)),
        if (showSeeAll) const Text('See All', style: TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}