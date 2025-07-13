import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather = await _weatherService.fetchCurrentWeather('San Pedro, Laguna, PH');
      setState(() {
        weatherData = weather;
        isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getWeatherSpecificTip() {
    if (weatherData == null) return "Stay prepared for any weather conditions!";
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final temp = weatherData!['main']['temp'];
    
    if (condition == 'rain' || condition == 'drizzle') {
      return "🌧️ RAIN ALERT: Avoid flood-prone areas and stay indoors if possible!";
    } else if (condition == 'thunderstorm') {
      return "⛈️ STORM WARNING: Seek shelter immediately and avoid open areas!";
    } else if (temp > 32) {
      return "🌡️ HIGH HEAT: Stay hydrated and avoid prolonged sun exposure!";
    } else if (temp < 20) {
      return "❄️ COOL WEATHER: Dress warmly and check on elderly neighbors!";
    } else if (condition == 'clear') {
      return "☀️ CLEAR SKIES: Perfect weather for emergency preparedness activities!";
    } else {
      return "🌤️ Current weather: ${weatherData!['weather'][0]['description']}. Stay weather-aware!";
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
                        'Weather Safety Tips',
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
              
              // Tips Content with Tabbed Interface
              Flexible(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Weather-specific tip banner
                      if (weatherData != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getWeatherTipGradient(),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getWeatherTipIcon(),
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getWeatherSpecificTip(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Custom Tab Bar with transition colors
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                        height: 38,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildColoredTab(
                                icon: Icons.air,
                                text: 'Air',
                                gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                                index: 0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildColoredTab(
                                icon: Icons.wb_sunny,
                                text: 'Heat',
                                gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                                index: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildColoredTab(
                                icon: Icons.water,
                                text: 'Flood',
                                gradientColors: [Colors.green.shade400, Colors.green.shade600],
                                index: 2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildColoredTab(
                                icon: Icons.storm,
                                text: 'Typhoon',
                                gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                                index: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Views
                      Flexible(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Air Quality Section
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _buildAirQualitySection(),
                            ),
                            
                            // Heat Index Section
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _buildHeatIndexSection(),
                            ),
                            
                            // Flood Section
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _buildFloodSection(),
                            ),
                            
                            // Typhoon Section
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: _buildTyphoonSection(),
                            ),
                          ],
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

  Widget _buildColoredTab({
    required IconData icon,
    required String text,
    required List<Color> gradientColors,
    required int index,
  }) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          bool isSelected = _tabController.index == index;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha: isSelected ? 0.4 : 0.2),
                  blurRadius: isSelected ? 6 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isSelected ? 14 : 12,
                  color: Colors.white,
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: isSelected ? 9 : 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Add placeholder methods for content sections
  Widget _buildAirQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.air,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'AIR QUALITY INDEX (AQI) - HEALTH GUIDELINES',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildColorCodedItem('0-50', 'GOOD (Green)', 
          '• Air quality is satisfying\n• Outdoor activities are safe\n• No health precautions needed', 
          Colors.green),
        _buildColorCodedItem('51-100', 'MODERATE (Yellow)', 
          '• Acceptable air quality\n• Sensitive individuals may experience minor symptoms\n• Consider reducing outdoor activities if you\'re sensitive', 
          Colors.yellow),
        _buildColorCodedItem('101-150', 'UNHEALTHY FOR SENSITIVE (Orange)', 
          '• Children, elderly, and people with respiratory conditions should limit outdoor activities\n• Wear N95 masks if going outside\n• Keep windows closed', 
          Colors.orange),
        _buildColorCodedItem('151-200', 'UNHEALTHY (Red)', 
          '• Everyone should avoid prolonged outdoor activities\n• Wear protective masks outdoors\n• Use air purifiers indoors\n• Seek medical attention if experiencing symptoms', 
          Colors.red),
        _buildColorCodedItem('201-300', 'VERY UNHEALTHY (Purple)', 
          '• Stay indoors with windows and doors closed\n• Avoid all outdoor activities\n• Use air purifiers and masks\n• Emergency health measures may be needed', 
          Colors.purple),
        _buildColorCodedItem('301+', 'HAZARDOUS (Maroon)', 
          '• Health emergency - stay indoors immediately\n• Avoid all outdoor exposure\n• Seek immediate medical attention for symptoms\n• Follow official emergency guidelines', 
          Colors.red.shade900),
        const SizedBox(height: 2),
        _buildPreventiveMeasuresSection('AIR QUALITY'),
      ],
    );
  }

  Widget _buildHeatIndexSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.wb_sunny,
              size: 35,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'HEAT INDEX - SAFETY MEASURES & HEALTH EFFECTS',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        _buildColorCodedItem('<26°C', 'SAFE (Green)', 
          '• No adverse health effects\n• Normal outdoor activities safe\n• Stay hydrated as usual', 
          Colors.green),
        _buildColorCodedItem('27-32°C', 'CAUTION (Yellow)', 
          '• Drink plenty of water every 15-20 minutes\n• Take frequent breaks in shade\n• Watch for signs of heat cramps\n• Avoid prolonged sun exposure', 
          Colors.yellow),
        _buildColorCodedItem('33-41°C', 'EXTREME CAUTION (Orange)', 
          '• Limit outdoor activities between 10AM-4PM\n• Drink water before feeling thirsty\n• Wear light-colored, loose clothing\n• Seek air-conditioned spaces\n• Watch for heat exhaustion symptoms', 
          Colors.orange),
        _buildColorCodedItem('42-51°C', 'DANGER (Red)', 
          '• Avoid outdoor activities during peak hours\n• Stay in air-conditioned areas\n• Drink water every 10-15 minutes\n• Apply cold wet cloths to body\n• Call for medical help if feeling unwell', 
          Colors.red),
        _buildColorCodedItem('>52°C', 'EXTREME DANGER (Dark Red)', 
          '• EMERGENCY - Stay indoors immediately\n• Seek immediate air conditioning\n• Apply ice packs to neck, armpits, groin\n• Call emergency services if experiencing heat stroke symptoms\n• Continuous hydration required', 
          Colors.red.shade900),
        const SizedBox(height: 2),
        _buildPreventiveMeasuresSection('HEAT'),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildFloodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.water,
              size: 35,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'FLOOD SAFETY & EMERGENCY RESPONSE GUIDE',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'FLOOD MONITORING LEVELS:',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildColorCodedItem('0-0.5m', 'ALERT LEVEL 1 (Yellow)', 
          '• Monitor weather updates continuously\n• Prepare emergency kit and evacuation plan\n• Check drainage systems around your area\n• Stay informed through official channels', 
          Colors.yellow),
        _buildColorCodedItem('0.5-1.3m', 'ALERT LEVEL 2 (Orange)', 
          '• Prepare to evacuate immediately\n• Move valuable items to higher areas\n• Ensure family emergency plan is ready\n• Monitor local government announcements', 
          Colors.orange),
        _buildColorCodedItem('1.3m+', 'CRITICAL LEVEL 3 (Red)', 
          '• EVACUATE IMMEDIATELY to nearest evacuation center\n• Do not attempt to cross flood waters\n• Call emergency hotlines if trapped\n• Follow all evacuation orders', 
          Colors.red),
        const SizedBox(height: 12),
        const Text(
          'FLOOD SAFETY TIPS:',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Text(
            '🚫 NEVER walk, swim, or drive through flood waters\n🚗 Turn Around, Don\'t Drown! - 6 inches can knock you down\n🌉 Stay off bridges over fast-moving water\n📱 Keep phones charged and emergency numbers handy\n🎒 Have emergency kit ready (food, water, medicines, flashlight)\n🏠 Move to higher ground or upper floors\n📻 Stay tuned to emergency broadcasts\n👥 Help neighbors, especially elderly and disabled',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 2),
        _buildPreventiveMeasuresSection('FLOOD'),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildTyphoonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.storm,
              size: 35,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'TYPHOON SAFETY & PREPAREDNESS GUIDE',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'WIND SIGNAL CLASSIFICATIONS:',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildColorCodedItem('Signal #1', 'TROPICAL DEPRESSION (Blue)', 
          '• Wind Speed: 61 km/h or less\n• Light to moderate damage expected\n• Secure loose objects, check emergency supplies', 
          Colors.blue),
        _buildColorCodedItem('Signal #2', 'TROPICAL STORM (Yellow)', 
          '• Wind Speed: 62-88 km/h\n• Minor to moderate damage possible\n• Stay indoors, avoid unnecessary travel', 
          Colors.yellow),
        _buildColorCodedItem('Signal #3', 'SEVERE TROPICAL STORM (Orange)', 
          '• Wind Speed: 89-117 km/h\n• Moderate to heavy damage expected\n• Suspend classes and work, secure all windows', 
          Colors.orange),
        _buildColorCodedItem('Signal #4', 'TYPHOON (Red)', 
          '• Wind Speed: 118-184 km/h\n• Heavy to very heavy damage expected\n• Complete shutdown, stay in strongest part of house', 
          Colors.red),
        _buildColorCodedItem('Signal #5', 'SUPER TYPHOON (Purple)', 
          '• Wind Speed: 185 km/h or higher\n• Catastrophic damage expected\n• Emergency shelters, evacuate if ordered', 
          Colors.purple),
        const SizedBox(height: 6),
        const Text(
          'TYPHOON PREPARATION CHECKLIST:',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: const Text(
            '📦 EMERGENCY KIT:\n• 3 days food & water supply\n• Flashlights & batteries\n• First aid kit & medicines\n• Portable radio\n• Cash & important documents\n\n🏠 HOME PREPARATION:\n• Secure or remove loose outdoor items\n• Cover windows with plywood/tape\n• Clear gutters and drains\n• Charge all devices\n• Fill bathtubs with clean water\n\n⚠️ DURING THE TYPHOON:\n• Stay indoors away from windows\n• Listen to weather updates\n• Don\'t use candles (fire hazard)\n• Avoid flooded areas\n• Have emergency numbers ready',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 2),
        _buildPreventiveMeasuresSection('TYPHOON'),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildColorCodedItem(String range, String level, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              range,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black87,
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

  Widget _buildPreventiveMeasuresSection(String type) {
    Map<String, List<Map<String, String>>> preventiveMeasures = {
      'AIR QUALITY': [
        {'number': '01', 'title': 'Enforce Clean Air Laws', 'description': 'Ban open burning, monitor vehicle and factory emissions.'},
        {'number': '02', 'title': 'Greening the City', 'description': 'Plant more trees, promote biking and walking.'},
        {'number': '03', 'title': 'Public Education', 'description': 'Teach proper waste disposal and pollution effects.'},
        {'number': '04', 'title': 'Air Monitoring', 'description': 'Install sensors, share air quality updates regularly.'},
      ],
      'HEAT': [
        {'number': '01', 'title': 'Public Awareness', 'description': 'Use social media, radio, and barangay announcements to inform residents about heat advisories and safety tips.'},
        {'number': '02', 'title': 'Hydration & Shade', 'description': 'Set up water stations and shaded areas in public places.'},
        {'number': '03', 'title': 'Modified Schedules', 'description': 'Adjust school and work hours or shift to online during extreme heat.'},
        {'number': '04', 'title': 'Protect Vulnerable Groups', 'description': 'Barangay health workers monitor children, elderly, and those with health conditions.'},
      ],
      'FLOOD': [
        {'number': '01', 'title': 'Emergency Kit', 'description': 'Keep emergency supplies, important documents, and first aid kit ready.'},
        {'number': '02', 'title': 'Evacuation Plan', 'description': 'Know your evacuation routes and nearest evacuation centers.'},
        {'number': '03', 'title': 'Stay Informed', 'description': 'Monitor weather updates and local government announcements.'},
        {'number': '04', 'title': 'Secure Property', 'description': 'Clear drainage systems and secure outdoor items before flooding.'},
      ],
      'TYPHOON': [
        {'number': '01', 'title': 'Spread public awareness', 'description': 'and early warnings.'},
        {'number': '02', 'title': 'Reinforce homes', 'description': 'and trim nearby trees.'},
        {'number': '03', 'title': 'Prepare emergency kits', 'description': 'and evacuation plans.'},
        {'number': '04', 'title': 'Conduct disaster drills', 'description': 'and community education.'},
      ],
    };

    String title = type == 'AIR QUALITY' ? 'PREVENTIVE MEASURES' : 
                   type == 'HEAT' ? 'How to Overcome/PREVENTION' :
                   type == 'FLOOD' ? 'PREVENTIVE MEASURES' : 'PREVENTIVE MEASURES';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...preventiveMeasures[type]!.map((item) => _buildNumberedItem(
          item['number']!,
          item['title']!,
          item['description']!,
        )).toList(),
      ],
    );
  }

  Widget _buildNumberedItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black54,
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

  List<Color> _getWeatherTipGradient() {
    if (weatherData == null) return [Colors.blue.shade400, Colors.blue.shade600];
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final temp = weatherData!['main']['temp'];
    
    if (condition == 'rain' || condition == 'drizzle') {
      return [Colors.blue.shade600, Colors.blue.shade800];
    } else if (condition == 'thunderstorm') {
      return [Colors.red.shade600, Colors.red.shade800];
    } else if (temp > 32) {
      return [Colors.orange.shade500, Colors.red.shade600];
    } else if (temp < 20) {
      return [Colors.indigo.shade500, Colors.blue.shade600];
    } else if (condition == 'clear') {
      return [Colors.green.shade500, Colors.green.shade700];
    } else {
      return [Colors.teal.shade500, Colors.teal.shade700];
    }
  }

  IconData _getWeatherTipIcon() {
    if (weatherData == null) return Icons.info;
    
    final condition = weatherData!['weather'][0]['main'].toLowerCase();
    final temp = weatherData!['main']['temp'];
    
    if (condition == 'rain' || condition == 'drizzle') {
      return Icons.umbrella;
    } else if (condition == 'thunderstorm') {
      return Icons.flash_on;
    } else if (temp > 32) {
      return Icons.thermostat;
    } else if (temp < 20) {
      return Icons.ac_unit;
    } else if (condition == 'clear') {
      return Icons.wb_sunny;
    } else {
      return Icons.cloud;
    }
  }
}
