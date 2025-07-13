import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/weather_service.dart';

class HotlinesScreen extends StatefulWidget {
  const HotlinesScreen({super.key});

  @override
  State<HotlinesScreen> createState() => _HotlinesScreenState();
}

class _HotlinesScreenState extends State<HotlinesScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather = await _weatherService.fetchCurrentWeather('San Pedro, Laguna, PH');
      if (mounted) {
        setState(() {
          weatherData = weather;
          isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/b.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Emergency Hotlines',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the row
                  ],
                ),
              ),
              
              // Weather Condition Banner
              _buildWeatherBanner(),
              
              // Content with better readability
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Emergency Icon Header
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emergency,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'City of San Pedro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Emergency Services',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Weather and Emergency content area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Weather Information
                              _buildWeatherInfoCard(),
                              
                              const SizedBox(height: 16),
                              
                              const Text(
                                'In case of an emergency, please contact:',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Emergency Services List
                              _buildHotlineItem(
                                context,
                                'OFFICE OF THE MAYOR',
                                '(02) 8808-2020',
                                Icons.account_balance,
                                iconColor: Colors.blue.shade700,
                              ),
                              
                              _buildHotlineItem(
                                context,
                                'CITY DISASTER RISK REDUCTION AND\nMANAGEMENT OFFICE',
                                '(02) 8403-2648/0998 594 1743',
                                Icons.warning_amber,
                                iconColor: Colors.orange.shade700,
                              ),
                              
                              _buildHotlineItem(
                                context,
                                'SAN PEDRO AKTIBO\nRESCUE CREW',
                                '(02) 8403-2648/0998 594 1743',
                                Icons.local_hospital,
                                iconColor: Colors.red.shade600,
                              ),
                              
                              _buildHotlineItem(
                                context,
                                'PHILIPPINE NATIONAL\nPOLICE',
                                '(02) 8567-3381/8864-1548',
                                Icons.local_police,
                                iconColor: Colors.blue.shade800,
                              ),
                              
                              _buildHotlineItem(
                                context,
                                'CITY OF SAN PEDRO LAGUNA\nBUREAU OF FIRE PROTECTION',
                                '(02) 8808-0617/0936 470 2158',
                                Icons.local_fire_department,
                                iconColor: Colors.red.shade700,
                              ),
                              
                              _buildHotlineItem(
                                context,
                                'CITY FIRE AUXILIARY UNIT',
                                '(02) 8363 9392',
                                Icons.fire_truck,
                                iconColor: Colors.red.shade600,
                              ),
                              
                              _buildHotlineItem(
                                context,
                                'MERALCO',
                                '(02) 16211\nFor SMS  09209716211(SMART)\n09175516211 (GLOBE)',
                                Icons.electrical_services,
                                iconColor: Colors.yellow.shade700,
                                isLast: true,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Emergency Call 911
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade600, Colors.red.shade800],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.phone_in_talk,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '🚨 For immediate life-threatening emergencies, call 911',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfoCard() {
    if (isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Loading weather information...',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (weatherData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Unable to fetch weather data. Please check your connection.',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Weather data available - show rain/precipitation info
    String temperature = weatherData!['main']['temp'].toStringAsFixed(1);
    String weatherDescription = weatherData!['weather'][0]['description'];
    String windSpeed = weatherData!['wind']['speed'].toStringAsFixed(1);
    bool isRaining = _isRainingCondition();
    String rainInfo = _getRainInfo();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getWeatherGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main weather info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Weather Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getWeatherIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Weather Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$temperature°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            weatherDescription.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    Text(
                      'San Pedro, Laguna',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Rain/Weather Condition Info
          if (isRaining) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.grain,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rainInfo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Emergency weather warning
          if (_isEmergencyWeather()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SEVERE WEATHER ALERT - Take extra precautions!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Additional weather details
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.air,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Wind: $windSpeed m/s',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.water_drop,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Humidity: ${weatherData!['main']['humidity']}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineItem(BuildContext context, String serviceName, String phoneNumber, IconData icon, {bool isLast = false, Color? iconColor}) {
    // Set default color scheme based on service type
    Color serviceIconColor = iconColor ?? Colors.green.shade700;
    
    return Column(
      children: [
        Row(
          children: [
            // Service Icon/Logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                icon,
                color: serviceIconColor,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Service Name and Phone Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Name
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Phone Number Button
                  GestureDetector(
                    onTap: () => _makePhoneCall(context, phoneNumber),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        phoneNumber,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (!isLast) ...[
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    // Clean the phone number for copying (remove extra text)
    String cleanNumber = phoneNumber.split('\n').first;
    if (cleanNumber.contains('/')) {
      cleanNumber = cleanNumber.split('/').first;
    }
    
    // Copy phone number to clipboard and show snackbar
    await Clipboard.setData(ClipboardData(text: cleanNumber.trim()));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number $cleanNumber copied to clipboard'),
          backgroundColor: Colors.green.shade700,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // Weather Banner Widget
  Widget _buildWeatherBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getWeatherGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoadingWeather
          ? const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading weather...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : weatherData != null
              ? Row(
                  children: [
                    Icon(
                      _getWeatherIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weatherData!['main']['temp'].toStringAsFixed(1)}°C - ${weatherData!['weather'][0]['description']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isRainingCondition())
                            Text(
                              _getRainInfo(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Weather data unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Color> _getWeatherGradient() {
    if (weatherData == null) return [Colors.grey.shade600, Colors.grey.shade800];
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final isDay = _isDayTime();
    
    switch (condition) {
      case 'clear':
        return isDay 
            ? [Colors.orange.shade400, Colors.orange.shade600]
            : [Colors.indigo.shade600, Colors.indigo.shade800];
      case 'clouds':
        return [Colors.grey.shade500, Colors.grey.shade700];
      case 'rain':
      case 'drizzle':
        return [Colors.blue.shade600, Colors.blue.shade800];
      case 'thunderstorm':
        return [Colors.purple.shade600, Colors.purple.shade800];
      case 'snow':
        return [Colors.blue.shade300, Colors.blue.shade500];
      case 'mist':
      case 'fog':
        return [Colors.grey.shade400, Colors.grey.shade600];
      default:
        return [Colors.teal.shade500, Colors.teal.shade700];
    }
  }

  IconData _getWeatherIcon() {
    if (weatherData == null) return Icons.cloud;
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final isDay = _isDayTime();
    
    switch (condition) {
      case 'clear':
        return isDay ? Icons.wb_sunny : Icons.nights_stay;
      case 'clouds':
        return isDay ? Icons.wb_cloudy : Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

  bool _isRainingCondition() {
    if (weatherData == null) return false;
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    return condition == 'rain' || condition == 'drizzle' || condition == 'thunderstorm';
  }

  String _getRainInfo() {
    if (weatherData == null) return '';
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final description = weatherData!['weather'][0]['description'];
    
    if (condition == 'rain') {
      // Check if rain data is available
      if (weatherData!['rain'] != null) {
        if (weatherData!['rain']['1h'] != null) {
          return 'Rain: ${weatherData!['rain']['1h']} mm/h';
        }
      }
      return 'RAINING - $description';
    } else if (condition == 'drizzle') {
      return 'DRIZZLING - $description';
    } else if (condition == 'thunderstorm') {
      return 'THUNDERSTORM - $description';
    }
    
    return '';
  }

  bool _isEmergencyWeather() {
    if (weatherData == null) return false;
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final windSpeed = weatherData!['wind']['speed'] ?? 0;
    
    return condition == 'thunderstorm' || 
           condition == 'tornado' || 
           windSpeed > 15; // Strong wind alert
  }

  bool _isDayTime() {
    if (weatherData == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sunrise = weatherData!['sys']['sunrise'] ?? 0;
    final sunset = weatherData!['sys']['sunset'] ?? 0;
    
    return now >= sunrise && now <= sunset;
  }
}
