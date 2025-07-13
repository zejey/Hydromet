import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _cityController = TextEditingController(text: "San Pedro, Laguna, PH");

  String city = 'San Pedro, Laguna, PH';
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? airData;
  List<Map<String, dynamic>> locationSuggestions = [];
  bool isLoading = true;
  LatLng? selectedLocation;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    loadWeather();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _cityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadWeather() async {
    setState(() => isLoading = true);
    try {
      final weather = await _weatherService.fetchCurrentWeather(city);
      final air = await _weatherService.fetchAirPollution(
        weather['coord']['lat'],
        weather['coord']['lon'],
      );

      setState(() {
        weatherData = weather;
        airData = air;
        selectedLocation = LatLng(
          weather['coord']['lat'],
          weather['coord']['lon'],
        );
        isLoading = false;
      });
    } catch (e) {
      print('Error loading weather: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> handleSearch() async {
    final searchCity = _cityController.text.trim();
    setState(() {
      city = searchCity;
      locationSuggestions = [];
    });
    await loadWeather();
  }

  Future<void> handleLocationSearch(String input) async {
    final suggestions = await _weatherService.fetchLocationSuggestions(input);
    setState(() => locationSuggestions = suggestions);
  }

  void handleSelectLocation(Map<String, dynamic> selected) {
    final name = selected['name'] ?? '';
    final state = selected['state'] ?? '';
    final country = selected['country'] ?? '';
    final formatted = [name, state, country].where((s) => s.isNotEmpty).join(', ');

    setState(() {
      city = formatted;
      _cityController.text = formatted;
      locationSuggestions = [];
    });
    loadWeather();
  }

  Widget buildWeatherTile(String label, String value, IconData icon) {
    return SizedBox(
      width: MediaQuery.of(context).size.width >= 600 ? 260 : double.infinity,
      child: buildGlassyCard(
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$label: $value",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGlassyCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 3),
          ),
          child: child,
        ),
      ),
    );
  }

  String getBackgroundImage() {
    final weatherMain = weatherData?['weather'][0]['main'].toLowerCase();
    if (weatherMain == 'clear') return 'assets/sunny.jpg';
    if (weatherMain?.contains('cloud') ?? false) return 'assets/cloudy.jpg';
    if (weatherMain?.contains('rain') ?? false) return 'assets/rainy.jpg';
    if (weatherMain?.contains('snow') ?? false) return 'assets/snowy.jpg';
    if (weatherMain?.contains('thunderstorm') ?? false) return 'assets/thunderstorm.jpg';
    return 'assets/clear_day.jpg';
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
                  return Transform.scale(scale: _scaleAnimation.value, child: child);
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(getBackgroundImage(), fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.4)),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter city',
                            hintStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (text) => text.isNotEmpty
                              ? handleLocationSearch(text)
                              : setState(() => locationSuggestions = []),
                          onSubmitted: (_) => handleSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: handleSearch,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
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
                                title: Text(displayText, style: const TextStyle(color: Colors.white)),
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
                                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      Image.network(
                                        "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png",
                                        width: 100,
                                      ),
                                      Text(
                                        "${weatherData!['main']['temp'].round()}°C",
                                        style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        weatherData!['weather'][0]['description'],
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 20),

                                      // Responsive Card Grid
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          buildWeatherTile("Feels Like", "${weatherData!['main']['feels_like'].round()}°C", Icons.thermostat),
                                          buildWeatherTile("Humidity", "${weatherData!['main']['humidity']}%", Icons.water_drop),
                                          buildWeatherTile("Wind", "${weatherData!['wind']['speed']} m/s", Icons.air),
                                          buildWeatherTile("Pressure", "${weatherData!['main']['pressure']} hPa", Icons.speed),
                                          buildWeatherTile("Visibility", "${(weatherData!['visibility'] / 1000).toStringAsFixed(1)} km", Icons.remove_red_eye),
                                          buildWeatherTile("Clouds", "${weatherData!['clouds']['all']}%", Icons.cloud),
                                          if (airData != null)
                                            buildWeatherTile("Air Quality", "${airData!['list'][0]['main']['aqi']}", Icons.factory),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // Map View (if location is available)
                                      if (selectedLocation != null)
                                        SizedBox(
                                          height: 200,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: FlutterMap(
                                              options: MapOptions(
                                                center: selectedLocation,
                                                zoom: 10.0,
                                              ),
                                              children: [
                                                TileLayer(
                                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                                  subdomains: ['a', 'b', 'c'],
                                                  userAgentPackageName: 'com.example.app',
                                                ),
                                                MarkerLayer(
                                                  markers: [
                                                    Marker(
                                                      width: 40.0,
                                                      height: 40.0,
                                                      point: selectedLocation!,
                                                      builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                                    ),
                                                  ],
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
}
