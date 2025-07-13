import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/weather_service.dart';
import '../services/auth_service.dart';
import 'log_in.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _cityController =
      TextEditingController(text: "San Pedro, Laguna, Philippines");
  final GlobalKey _hamburgerMenuKey = GlobalKey();
  final GlobalKey _profileButtonKey = GlobalKey();

  String city = 'San Pedro, Laguna, Philippines';
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? airData;
  List<Map<String, dynamic>> locationSuggestions = [];
  List<Map<String, dynamic>> hourlyForecast = [];
  bool isLoading = true;
  LatLng? selectedLocation;

  // Map-related variables
  final MapController _mapController = MapController();
  String _currentMapStyle = 'street';
  bool _showWeatherLayer = false;
  bool _showSatelliteLayer = false;
  bool _showHazardLocations = true; // Show hazards by default
  double _currentZoom = 14.0; // Better zoom level for San Pedro city view

  // Hazard locations in San Pedro, Laguna barangays with accurate coordinates
  final List<Map<String, dynamic>> _hazardLocations = [
    {
      'name': 'Barangay Riverside - Flood Risk',
      'type': 'flood',
      'location': LatLng(14.3489, 121.0612), // Near actual Laguna de Bay shoreline
      'severity': 'high',
      'description':
          'High flood risk during heavy rainfall and typhoons due to proximity to Laguna de Bay',
    },
    {
      'name': 'Barangay San Vicente - Landslide Risk',
      'type': 'landslide',
      'location': LatLng(14.3278, 121.0356), // Elevated area near sports complex
      'severity': 'medium',
      'description':
          'Moderate landslide risk on steep slopes in hillside areas',
    },
    {
      'name': 'Pacita Complex - Heat Island',
      'type': 'heat',
      'location': LatLng(14.3189, 121.0401), // Dense residential Pacita area
      'severity': 'medium',
      'description':
          'Urban heat island effect during summer months in dense residential area',
    },
    {
      'name': 'Barangay Landayan - Air Quality',
      'type': 'air_pollution',
      'location': LatLng(14.3411, 121.0478), // Commercial/traffic area
      'severity': 'medium',
      'description':
          'Elevated air pollution levels from commercial activities and heavy traffic',
    },
    {
      'name': 'Barangay Poblacion - Storm Surge',
      'type': 'storm_surge',
      'location': LatLng(14.3364, 121.0423), // Central poblacion area
      'severity': 'high',
      'description':
          'High storm surge risk during typhoons affecting central low-lying areas',
    },
    {
      'name': 'West Valley Fault Zone - Earthquake Risk',
      'type': 'earthquake',
      'location': LatLng(14.3250, 121.0380), // Near fault line area
      'severity': 'high',
      'description':
          'Near West Valley Fault line - earthquake preparedness required for all residents',
    },
  ];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final AuthManager _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    loadWeather();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkLoginStatus();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadWeather() async {
    try {
      setState(() => isLoading = true);

      // Use specific coordinates for San Pedro City Hall, Laguna, Philippines for accurate location
      const sanPedroLat = 14.3358; // San Pedro City Hall coordinates
      const sanPedroLon = 121.0417;

      final weather =
          await _weatherService.fetchWeatherByCoords(sanPedroLat, sanPedroLon);
      final air =
          await _weatherService.fetchAirPollution(sanPedroLat, sanPedroLon);
      final forecast =
          await _weatherService.fetchHourlyForecast(sanPedroLat, sanPedroLon);

      setState(() {
        weatherData = weather;
        airData = air;
        hourlyForecast = forecast;
        selectedLocation = LatLng(sanPedroLat, sanPedroLon);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty) {
      setState(() => locationSuggestions = []);
      return;
    }
    final suggestions = await _weatherService.fetchLocationSuggestions(query);
    setState(() => locationSuggestions = suggestions);
  }

  void handleSelectLocation(Map<String, dynamic> location) {
    final newCity = [
      location['name'] ?? '',
      location['state'] ?? '',
      location['country'] ?? '',
    ].where((e) => e.isNotEmpty).join(', ');

    setState(() {
      city = newCity;
      _cityController.text = newCity;
      locationSuggestions = [];
    });

    // Use the coordinates from the selected location
    if (location['lat'] != null && location['lon'] != null) {
      _fetchWeatherForLocation(LatLng(location['lat'], location['lon']));
    } else {
      loadWeather();
    }
  }

  String get weatherMain =>
      (weatherData?['weather']?[0]?['main'] ?? '').toLowerCase();

  String getBackgroundImage() {
    switch (weatherMain) {
      case 'clear':
        return 'assets/clear_day.jpg';
      case 'clouds':
        return 'assets/cloudy.jpg';
      case 'rain':
      case 'drizzle':
      case 'thunderstorm':
        return 'assets/rainy.jpg';
      case 'snow':
        return 'assets/snowy.jpg';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'assets/clear_day.jpg';
      default:
        return 'assets/clear_day.jpg';
    }
  }

  Widget buildWeatherTile(String title, String value, IconData icon) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget buildHourlyForecast() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              '24-Hour Forecast',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Horizontal Scrollable Forecast
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics:
                  const ClampingScrollPhysics(), // Changed to ClampingScrollPhysics for better scrolling
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hourlyForecast.length > 24
                  ? 24
                  : hourlyForecast.length, // Limit to 24 hours
              itemBuilder: (context, index) {
                final forecast = hourlyForecast[index];
                final time = forecast['time'] ?? '';

                // Parse the time more accurately
                DateTime? dateTime;
                String displayTime = "N/A";
                String displayDate = "";

                try {
                  if (time.isNotEmpty) {
                    dateTime = DateTime.parse(time);
                    displayTime =
                        "${dateTime.hour.toString().padLeft(2, '0')}:00";

                    // Show date for items that are not today
                    final now = DateTime.now();
                    if (dateTime.day != now.day) {
                      displayDate = "${dateTime.day}/${dateTime.month}";
                    } else if (index == 0) {
                      displayTime = "Now";
                    }
                  }
                } catch (e) {
                  // Fallback for parsing errors
                  if (time.length >= 13) {
                    displayTime = "${time.substring(11, 13)}:00";
                  }
                }

                final temp = "${(forecast['temp'] ?? 0).round()}°";
                final icon = forecast['icon'] ?? '01d';
                final humidity = "${(forecast['humidity'] ?? 0)}%";

                // Determine if this is the current hour
                final isCurrentHour = index == 0;

                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentHour
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentHour
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.3),
                      width: isCurrentHour ? 2 : 1,
                    ),
                    boxShadow: isCurrentHour
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize:
                        MainAxisSize.min, // Add this to prevent overflow
                    children: [
                      // Time
                      Text(
                        displayTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCurrentHour ? 13 : 12,
                          fontWeight:
                              isCurrentHour ? FontWeight.bold : FontWeight.w500,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Add text overflow handling
                      ),

                      // Date (if different day)
                      if (displayDate.isNotEmpty)
                        Text(
                          displayDate,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Add text overflow handling
                        ),

                      // Weather Icon
                      Flexible(
                        // Wrap with Flexible to prevent overflow
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            "https://openweathermap.org/img/wn/$icon.png",
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.wb_cloudy,
                                color: Colors.white,
                                size: 32,
                              );
                            },
                          ),
                        ),
                      ),

                      // Temperature
                      Text(
                        temp,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCurrentHour ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Add text overflow handling
                      ),

                      // Additional info for current hour
                      if (isCurrentHour) ...[
                        const SizedBox(height: 2),
                        Text(
                          humidity,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Add text overflow handling
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Real-time update indicator
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Updated ${_getLastUpdateTime()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLastUpdateTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Top row with hamburger menu and profile button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: _hamburgerMenuKey,
              onPressed: _showMenuOptions,
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            ),
            IconButton(
              key: _profileButtonKey,
              onPressed: _showProfileMenu,
              icon: Icon(
                _authManager.isLoggedIn
                    ? Icons.account_circle
                    : Icons.account_circle_outlined,
                color: _authManager.isLoggedIn ? Colors.white : Colors.white70,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Search bar below the buttons
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search location...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onChanged: searchLocations,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  city = value;
                  locationSuggestions = [];
                });
                loadWeather();
              }
            },
          ),
        ),
      ],
    );
  }

  void _showMenuOptions() {
    final RenderBox? button =
        _hamburgerMenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
            value: 'forum',
            child: Row(
              children: [
                Icon(Icons.forum, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text('Community Forum', style: TextStyle(color: Colors.blue)),
              ],
            )),
        const PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                Icon(Icons.info, size: 20),
                SizedBox(width: 8),
                Text('About'),
              ],
            )),
        const PopupMenuItem(
            value: 'help',
            child: Row(
              children: [
                Icon(Icons.help, size: 20),
                SizedBox(width: 8),
                Text('Help'),
              ],
            )),
      ],
    ).then((String? result) {
      if (result == 'forum' && mounted) {
        Navigator.pushNamed(context, '/forum');
      } else if (result == 'about' && mounted) {
        _showAboutDialog();
      } else if (result == 'help' && mounted) {
        _showHelpDialog();
      }
    });
  }

  void _showProfileMenu() {
    final RenderBox? button =
        _profileButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        // Always available items
        const PopupMenuItem(
            value: 'tips',
            child: Row(
              children: [
                Icon(Icons.lightbulb, size: 20),
                SizedBox(width: 8),
                Text('Tips'),
              ],
            )),
        const PopupMenuItem(
            value: 'hotlines',
            child: Row(
              children: [
                Icon(Icons.phone, size: 20),
                SizedBox(width: 8),
                Text('Emergency Hotlines'),
              ],
            )),
        // Login-required items
        if (_authManager.isLoggedIn) ...[
          const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              )),
          const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              )),
          const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              )),
        ] else ...[
          const PopupMenuItem(
              value: 'login',
              child: Row(
                children: [
                  Icon(Icons.login, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Login', style: TextStyle(color: Colors.green)),
                ],
              )),
        ],
      ],
    ).then((String? result) {
      if (result == 'profile' && mounted) {
        if (_authManager.isLoggedIn) {
          Navigator.pushNamed(context, '/profile');
        } else {
          _showSnackBar('Please log in to access profile');
          Navigator.pushNamed(context, '/login');
        }
      } else if (result == 'settings' && mounted) {
        _navigateToSettings();
      } else if (result == 'tips' && mounted) {
        Navigator.pushNamed(context, '/tips');
      } else if (result == 'hotlines' && mounted) {
        Navigator.pushNamed(context, '/hotlines');
      } else if (result == 'logout' && mounted) {
        _handleLogout();
      } else if (result == 'login' && mounted) {
        Navigator.pushNamed(context, '/login');
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Check if user is logged in
  void _checkLoginStatus() {
    // Just trigger a state rebuild to check auth status
    setState(() {
      // The state will be rebuilt when auth state changes
    });
  }

  void _navigateToSettings() {
    if (_authManager.isLoggedIn) {
      Navigator.pushNamed(context, '/settings');
    } else {
      _showSnackBar('Please log in to access settings');
      Navigator.pushNamed(context, '/login');
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                // Clear both authentication systems
                await _authManager.logout();
                AuthService.signOut();
                if (mounted) {
                  setState(() {
                    // Rebuild to reflect auth state change
                  });
                  nav.pushNamedAndRemoveUntil('/', (route) => false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Logged out successfully'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About HydroMet San Pedro'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HydroMet San Pedro, Laguna'),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text(
                  'A weather application specifically designed for San Pedro, Laguna, Philippines. Provides real-time weather updates, local hazard warnings, emergency hotlines, and safety tips for residents.'),
              SizedBox(height: 16),
              Text('© 2025 City of San Pedro, Laguna'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to use the app:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• View current weather conditions on the main screen'),
              Text(
                  '• Use the profile menu to access Settings, Tips, and Hotlines'),
              Text('• Login to access personalized settings'),
              Text(
                  '• Emergency hotlines are available for immediate assistance'),
              SizedBox(height: 16),
              Text('Need more help? Contact your local authorities.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Animated background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                      scale: _scaleAnimation.value, child: child);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(getBackgroundImage(), fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header with hamburger menu and profile button
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: locationSuggestions.isNotEmpty
                        ? ListView.builder(
                            itemCount: locationSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = locationSuggestions[index];
                              final displayText = [
                                suggestion['name'] ?? '',
                                suggestion['state'] ?? '',
                                suggestion['country'] ?? '',
                              ].where((e) => e.isNotEmpty).join(', ');
                              return ListTile(
                                title: Text(displayText,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                onTap: () => handleSelectLocation(suggestion),
                              );
                            },
                          )
                        : isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (weatherData != null) ...[
                                      Text(
                                        weatherData!['name'],
                                        style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      Image.network(
                                        "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png",
                                        width: 100,
                                      ),
                                      Text(
                                        "${weatherData!['main']['temp'].round()}°C",
                                        style: const TextStyle(
                                            fontSize: 50,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      Text(
                                        weatherData!['weather'][0]
                                            ['description'],
                                        style: const TextStyle(
                                            color: Colors.white70),
                                      ),
                                      const SizedBox(height: 20),

                                      // Hourly Forecast Scroll View
                                      if (hourlyForecast.isNotEmpty)
                                        buildHourlyForecast(),

                                      // Responsive Card Grid
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          buildWeatherTile(
                                              "Feels Like",
                                              "${weatherData!['main']['feels_like'].round()}°C",
                                              Icons.thermostat),
                                          buildWeatherTile(
                                              "Humidity",
                                              "${weatherData!['main']['humidity']}%",
                                              Icons.water_drop),
                                          buildWeatherTile(
                                              "Wind",
                                              "${weatherData!['wind']['speed']} m/s",
                                              Icons.air),
                                          buildWeatherTile(
                                              "Pressure",
                                              "${weatherData!['main']['pressure']} hPa",
                                              Icons.speed),
                                          buildWeatherTile(
                                              "Visibility",
                                              "${(weatherData!['visibility'] / 1000).toStringAsFixed(1)} km",
                                              Icons.remove_red_eye),
                                          buildWeatherTile(
                                              "Clouds",
                                              "${weatherData!['clouds']['all']}%",
                                              Icons.cloud),
                                          if (airData != null)
                                            buildWeatherTile(
                                                "Air Quality",
                                                "${airData!['list'][0]['main']['aqi']}",
                                                Icons.factory),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // Enhanced Interactive Geospatial Map
                                      if (selectedLocation != null)
                                        Container(
                                          height: 400,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Stack(
                                              children: [
                                                // Main Map
                                                FlutterMap(
                                                  mapController: _mapController,
                                                  options: MapOptions(
                                                    center: selectedLocation,
                                                    zoom: _currentZoom,
                                                    minZoom: 3.0,
                                                    maxZoom: 18.0,
                                                    interactiveFlags:
                                                        InteractiveFlag.all,
                                                    onTap:
                                                        (tapPosition, point) {
                                                      _onMapTap(point);
                                                    },
                                                    onPositionChanged:
                                                        (position, hasGesture) {
                                                      if (hasGesture) {
                                                        setState(() {
                                                          _currentZoom =
                                                              position.zoom!;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  children: [
                                                    // Base map layer
                                                    TileLayer(
                                                      urlTemplate:
                                                          _getMapStyleUrl(),
                                                      subdomains: const [
                                                        'a',
                                                        'b',
                                                        'c'
                                                      ],
                                                      userAgentPackageName:
                                                          'com.example.weather_app',
                                                    ),

                                                    // Weather overlay layer
                                                    if (_showWeatherLayer)
                                                      TileLayer(
                                                        urlTemplate:
                                                            'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=a62db0fee1e1de12a993982cece6a6bc',
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      ),

                                                    // Satellite overlay
                                                    if (_showSatelliteLayer)
                                                      TileLayer(
                                                        urlTemplate:
                                                            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                                      ),

                                                    // Markers layer
                                                    MarkerLayer(
                                                      markers: [
                                                        // Current location marker
                                                        Marker(
                                                          width: 50.0,
                                                          height: 50.0,
                                                          point:
                                                              selectedLocation!,
                                                          builder: (ctx) =>
                                                              _buildWeatherMarker(),
                                                        ),

                                                        // Additional markers for nearby locations
                                                        ..._buildNearbyLocationMarkers(),

                                                        // Hazard location markers
                                                        if (_showHazardLocations)
                                                          ..._buildHazardMarkers(),
                                                      ],
                                                    ),

                                                    // Circle layer for weather coverage
                                                    CircleLayer(
                                                      circles: [
                                                        CircleMarker(
                                                          point:
                                                              selectedLocation!,
                                                          radius:
                                                              5000, // 5km radius
                                                          color: Colors.blue
                                                              .withValues(
                                                                  alpha: 0.2),
                                                          borderColor:
                                                              Colors.blue,
                                                          borderStrokeWidth: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                // Map controls overlay
                                                _buildMapControls(),

                                                // Hazard controls (separate from zoom)
                                                _buildHazardControls(),

                                                // Zoom controls
                                                _buildZoomControls(),

                                                // Hazard instruction overlay
                                                if (_showHazardLocations)
                                                  Positioned(
                                                    top: 16,
                                                    left: 16,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.8),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.touch_app,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Tap hazard markers for details',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                // Weather info overlay
                                                _buildWeatherInfoOverlay(),

                                                // Zoom controls
                                                _buildZoomControls(),

                                                // Floating hazard toggle button
                                                Positioned(
                                                  bottom: 180,
                                                  left: 16,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _showHazardLocations
                                                              ? Colors
                                                                  .red.shade700
                                                              : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.3),
                                                          blurRadius: 12,
                                                          offset: const Offset(
                                                              0, 6),
                                                        ),
                                                      ],
                                                      border: Border.all(
                                                        color:
                                                            _showHazardLocations
                                                                ? Colors.red
                                                                    .shade900
                                                                : Colors.grey
                                                                    .shade300,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(25),
                                                        onTap: () {
                                                          setState(() {
                                                            _showHazardLocations =
                                                                !_showHazardLocations;
                                                          });
                                                          _showSnackBar(
                                                              _showHazardLocations
                                                                  ? 'Hazard locations are now visible'
                                                                  : 'Hazard locations are now hidden');
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 12),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .warning_rounded,
                                                                color: _showHazardLocations
                                                                    ? Colors
                                                                        .white
                                                                    : Colors.red
                                                                        .shade700,
                                                                size: 24,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                _showHazardLocations
                                                                    ? 'HAZARDS ON'
                                                                    : 'HAZARDS OFF',
                                                                style:
                                                                    TextStyle(
                                                                  color: _showHazardLocations
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .red
                                                                          .shade700,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ]
                                  ],
                                ),
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

  // Geospatial Map Helper Methods
  String _getMapStyleUrl() {
    switch (_currentMapStyle) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'dark':
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case 'street':
      default:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
  }

  void _onMapTap(LatLng point) {
    // Handle map tap - could fetch weather for tapped location
    setState(() {
      selectedLocation = point;
    });

    // Optional: Fetch weather for the tapped location
    _fetchWeatherForLocation(point);
  }

  Future<void> _fetchWeatherForLocation(LatLng point) async {
    try {
      final weather = await _weatherService.fetchWeatherByCoords(
          point.latitude, point.longitude);
      final air = await _weatherService.fetchAirPollution(
          point.latitude, point.longitude);
      final forecast = await _weatherService.fetchHourlyForecast(
          point.latitude, point.longitude);

      if (mounted) {
        setState(() {
          weatherData = weather;
          airData = air;
          hourlyForecast = forecast;
          selectedLocation = point;
        });
      }
    } catch (e) {
      // Handle error - could show a snackbar or toast
      if (mounted) {
        _showSnackBar('Failed to fetch weather data for selected location');
      }
    }
  }

  Widget _buildWeatherMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing animation
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
            );
          },
        ),
        // Weather icon
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getWeatherIcon(),
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon() {
    if (weatherData == null) return Icons.location_on;

    final main = weatherData!['weather'][0]['main'].toLowerCase();
    switch (main) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.location_on;
    }
  }

  List<Marker> _buildNearbyLocationMarkers() {
    // Only show San Pedro, Laguna specific locations with accurate coordinates
    final sanPedroLocations = [
      {'name': 'San Pedro City Hall', 'coords': LatLng(14.3358, 121.0417)}, // Actual City Hall location
      {'name': 'St. Peter the Apostle Cathedral', 'coords': LatLng(14.3364, 121.0423)}, // Main cathedral
      {'name': 'Pacita Complex I', 'coords': LatLng(14.3189, 121.0401)}, // Pacita subdivision
      {'name': 'SM City San Pedro', 'coords': LatLng(14.3336, 121.0439)}, // Shopping center
      {'name': 'Landayan Town Center', 'coords': LatLng(14.3411, 121.0478)}, // Commercial area
      {'name': 'San Pedro Plaza', 'coords': LatLng(14.3361, 121.0419)}, // Town plaza
      {'name': 'Laguna de Bay Shoreline', 'coords': LatLng(14.3489, 121.0612)}, // Actual lakefront
      {'name': 'San Pedro Sports Complex', 'coords': LatLng(14.3278, 121.0356)}, // Sports facility
    ];

    return sanPedroLocations.map((location) {
      return Marker(
        width: 30.0,
        height: 30.0,
        point: location['coords'] as LatLng,
        builder: (ctx) => GestureDetector(
          onTap: () => _onNearbyLocationTap(location),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.location_city,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onNearbyLocationTap(Map<String, dynamic> location) {
    final coords = location['coords'] as LatLng;
    _mapController.move(coords, 12.0);
    _fetchWeatherForLocation(coords);
  }

  List<Marker> _buildHazardMarkers() {
    if (!_showHazardLocations) return [];

    return _hazardLocations.map((hazard) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: hazard['location'] as LatLng,
        builder: (ctx) => Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () {
              _onHazardLocationTap(hazard);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getHazardColor(hazard['type'], hazard['severity']),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getHazardIcon(hazard['type']),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getHazardTypeLabel(hazard['type']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getHazardTypeLabel(String type) {
    switch (type) {
      case 'flood':
        return 'FLOOD';
      case 'landslide':
        return 'LANDSLIDE';
      case 'heat':
        return 'HEAT';
      case 'air_pollution':
        return 'AIR QUALITY';
      case 'storm_surge':
        return 'STORM SURGE';
      case 'earthquake':
        return 'EARTHQUAKE';
      default:
        return 'HAZARD';
    }
  }

  Color _getHazardColor(String type, String severity) {
    Color baseColor;
    switch (type) {
      case 'flood':
        baseColor = Colors.blue;
        break;
      case 'landslide':
        baseColor = Colors.brown;
        break;
      case 'heat':
        baseColor = Colors.orange;
        break;
      case 'air_pollution':
        baseColor = Colors.grey;
        break;
      case 'storm_surge':
        baseColor = Colors.indigo;
        break;
      case 'earthquake':
        baseColor = Colors.red;
        break;
      default:
        baseColor = Colors.purple;
    }

    // Adjust color intensity based on severity
    switch (severity) {
      case 'high':
        return Color.fromRGBO(
          ((baseColor.r * 255.0).round() * 0.8).round(),
          ((baseColor.g * 255.0).round() * 0.8).round(),
          ((baseColor.b * 255.0).round() * 0.8).round(),
          1.0,
        );
      case 'medium':
        return baseColor;
      case 'low':
        return Color.fromRGBO(
          255 - ((255 - (baseColor.r * 255.0).round()) * 0.6).round(),
          255 - ((255 - (baseColor.g * 255.0).round()) * 0.6).round(),
          255 - ((255 - (baseColor.b * 255.0).round()) * 0.6).round(),
          1.0,
        );
      default:
        return baseColor;
    }
  }

  IconData _getHazardIcon(String type) {
    switch (type) {
      case 'flood':
        return Icons.water;
      case 'landslide':
        return Icons.landscape;
      case 'heat':
        return Icons.thermostat;
      case 'air_pollution':
        return Icons.air;
      case 'storm_surge':
        return Icons.tsunami;
      case 'earthquake':
        return Icons.vibration;
      default:
        return Icons.warning;
    }
  }

  void _onHazardLocationTap(Map<String, dynamic> hazard) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getHazardColor(hazard['type'], hazard['severity']),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getHazardIcon(hazard['type']),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hazard Alert',
                  style: TextStyle(
                    color: _getHazardColor(hazard['type'], hazard['severity']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hazard['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getHazardColor(hazard['type'], hazard['severity']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${hazard['severity'].toUpperCase()} RISK',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hazard['description'],
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Safety Recommendations:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getHazardRecommendations(hazard['type']),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/tips');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _getHazardColor(hazard['type'], hazard['severity']),
              ),
              child: const Text(
                'View Safety Tips',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getHazardRecommendations(String type) {
    switch (type) {
      case 'flood':
        return '• Avoid the area during heavy rainfall\n• Keep emergency supplies ready\n• Monitor flood warnings\n• Know evacuation routes';
      case 'landslide':
        return '• Watch for signs of ground movement\n• Avoid construction on steep slopes\n• Plant vegetation to stabilize soil\n• Report cracks or unusual sounds';
      case 'heat':
        return '• Stay hydrated and seek shade\n• Limit outdoor activities during peak hours\n• Wear light-colored clothing\n• Check on elderly neighbors';
      case 'air_pollution':
        return '• Limit outdoor activities on high pollution days\n• Use air purifiers indoors\n• Wear N95 masks when outside\n• Plant trees and reduce emissions';
      case 'storm_surge':
        return '• Evacuate if storm surge warning issued\n• Move to higher ground\n• Secure loose outdoor items\n• Monitor weather updates continuously';
      case 'earthquake':
        return '• Secure heavy furniture and appliances\n• Know Drop, Cover, Hold procedures\n• Keep emergency supplies ready\n• Plan evacuation routes';
      default:
        return '• Stay informed about weather conditions\n• Follow official safety guidelines\n• Keep emergency supplies ready\n• Have evacuation plans prepared';
    }
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Map style toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.layers, color: Colors.black87),
              onSelected: (style) {
                setState(() {
                  _currentMapStyle = style;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'street', child: Text('Street')),
                const PopupMenuItem(
                    value: 'satellite', child: Text('Satellite')),
                const PopupMenuItem(value: 'terrain', child: Text('Terrain')),
                const PopupMenuItem(value: 'dark', child: Text('Dark')),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Weather layer toggle
          Container(
            decoration: BoxDecoration(
              color: _showWeatherLayer ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.cloud,
                color: _showWeatherLayer ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _showWeatherLayer = !_showWeatherLayer;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // Satellite layer toggle
          Container(
            decoration: BoxDecoration(
              color: _showSatelliteLayer ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.satellite,
                color: _showSatelliteLayer ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _showSatelliteLayer = !_showSatelliteLayer;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoOverlay() {
    if (weatherData == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 80, // Leave space for hazard controls
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getWeatherIcon(),
              color: Colors.blue.shade700,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${weatherData!['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${weatherData!['main']['temp'].round()}°C - ${weatherData!['weather'][0]['description']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Zoom: ${_currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
                });
                _mapController.move(_mapController.center, _currentZoom);
              },
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.remove, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
                });
                _mapController.move(_mapController.center, _currentZoom);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        children: [
          // Hazard locations toggle
          Container(
            decoration: BoxDecoration(
              color: _showHazardLocations ? Colors.red : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.warning,
                color: _showHazardLocations ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  _showHazardLocations = !_showHazardLocations;
                });
                // Show feedback message
                _showSnackBar(_showHazardLocations
                    ? 'Hazard locations are now visible on the map'
                    : 'Hazard locations are now hidden');
              },
              tooltip: 'Toggle Hazard Locations',
            ),
          ),

          const SizedBox(height: 8),

          // Legend button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black87),
              onPressed: () {
                _showHazardLegend();
              },
              tooltip: 'Show Legend',
            ),
          ),
        ],
      ),
    );
  }

  void _showHazardLegend() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE RISK MONITOR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'San Pedro, Laguna',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current weather-based risk assessment
                  _buildCurrentRiskStatus(),

                  const SizedBox(height: 16),

                  // Real-time hazard risk levels
                  const Text(
                    'CURRENT RISK LEVELS:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic risk assessment based on current conditions
                  ..._buildRealTimeRiskItems(),

                  const SizedBox(height: 16),

                  // Risk severity indicators
                  _buildRiskSeverityGuide(),

                  const SizedBox(height: 16),

                  // Live update indicator
                  _buildLiveUpdateIndicator(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/hotlines');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Emergency Hotlines',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for the real-time risk legend
  Widget _buildCurrentRiskStatus() {
    // Get current weather conditions
    final weatherCondition =
        weatherData?['weather']?[0]?['main']?.toLowerCase() ?? '';
    final temperature = weatherData?['main']?['temp'] ?? 0.0;
    final humidity = weatherData?['main']?['humidity'] ?? 0;
    final windSpeed = weatherData?['wind']?['speed'] ?? 0.0;

    // Determine overall risk level
    String riskLevel = 'LOW';
    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle;

    if (weatherCondition.contains('rain') ||
        weatherCondition.contains('thunderstorm')) {
      riskLevel = 'HIGH';
      riskColor = Colors.red;
      riskIcon = Icons.warning;
    } else if (temperature > 35 || humidity > 80 || windSpeed > 20) {
      riskLevel = 'MEDIUM';
      riskColor = Colors.orange;
      riskIcon = Icons.warning_amber;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'CURRENT RISK: $riskLevel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Weather: ${weatherCondition.isNotEmpty ? weatherCondition.toUpperCase() : 'Unknown'}',
            style: TextStyle(
              fontSize: 12,
              color: riskColor.withValues(alpha: 0.8),
            ),
          ),
          Text(
            'Temperature: ${temperature.toStringAsFixed(1)}°C • Humidity: $humidity%',
            style: TextStyle(
              fontSize: 12,
              color: riskColor.withValues(alpha: 0.8),
            ),
          ),
          if (windSpeed > 0)
            Text(
              'Wind Speed: ${windSpeed.toStringAsFixed(1)} m/s',
              style: TextStyle(
                fontSize: 12,
                color: riskColor.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRealTimeRiskItems() {
    final weatherCondition =
        weatherData?['weather']?[0]?['main']?.toLowerCase() ?? '';
    final temperature = weatherData?['main']?['temp'] ?? 0.0;
    final humidity = weatherData?['main']?['humidity'] ?? 0;
    final windSpeed = weatherData?['wind']?['speed'] ?? 0.0;

    List<Widget> riskItems = [];

    // Flood risk based on rain/thunderstorm
    if (weatherCondition.contains('rain') ||
        weatherCondition.contains('thunderstorm')) {
      riskItems.add(_buildRiskItem(
        'Flood Risk',
        'HIGH',
        Colors.red,
        Icons.water_drop,
        'Active rain/storms increase flood risk in low-lying areas',
      ));
    } else {
      riskItems.add(_buildRiskItem(
        'Flood Risk',
        'LOW',
        Colors.green,
        Icons.water_drop,
        'No significant precipitation detected',
      ));
    }

    // Heat risk based on temperature
    if (temperature > 35) {
      riskItems.add(_buildRiskItem(
        'Heat Risk',
        'HIGH',
        Colors.red,
        Icons.thermostat,
        'Extreme heat warning - heat exhaustion risk',
      ));
    } else if (temperature > 32) {
      riskItems.add(_buildRiskItem(
        'Heat Risk',
        'MEDIUM',
        Colors.orange,
        Icons.thermostat,
        'Hot conditions - stay hydrated',
      ));
    } else {
      riskItems.add(_buildRiskItem(
        'Heat Risk',
        'LOW',
        Colors.green,
        Icons.thermostat,
        'Temperature within safe range',
      ));
    }

    // Air quality risk based on humidity and weather
    if (humidity > 80 ||
        weatherCondition.contains('haze') ||
        weatherCondition.contains('smoke')) {
      riskItems.add(_buildRiskItem(
        'Air Quality Risk',
        'MEDIUM',
        Colors.orange,
        Icons.air,
        'High humidity or poor air quality conditions',
      ));
    } else {
      riskItems.add(_buildRiskItem(
        'Air Quality Risk',
        'LOW',
        Colors.green,
        Icons.air,
        'Air quality conditions acceptable',
      ));
    }

    // Storm surge/wind risk
    if (windSpeed > 25) {
      riskItems.add(_buildRiskItem(
        'Storm Surge Risk',
        'HIGH',
        Colors.red,
        Icons.waves,
        'Strong winds may cause storm surge',
      ));
    } else if (windSpeed > 15) {
      riskItems.add(_buildRiskItem(
        'Storm Surge Risk',
        'MEDIUM',
        Colors.orange,
        Icons.waves,
        'Moderate winds detected',
      ));
    } else {
      riskItems.add(_buildRiskItem(
        'Storm Surge Risk',
        'LOW',
        Colors.green,
        Icons.waves,
        'Wind conditions normal',
      ));
    }

    return riskItems;
  }

  Widget _buildRiskItem(String title, String level, Color color, IconData icon,
      String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSeverityGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RISK SEVERITY GUIDE:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildSeverityItem('HIGH', Colors.red, 'Immediate action required'),
          _buildSeverityItem('MEDIUM', Colors.orange, 'Caution advised'),
          _buildSeverityItem('LOW', Colors.green, 'Normal conditions'),
        ],
      ),
    );
  }

  Widget _buildSeverityItem(String level, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            level,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- $description',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveUpdateIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE UPDATES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'Risk levels update automatically based on current weather conditions',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
