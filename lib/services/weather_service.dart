import 'dart:convert';
import 'package:http/http.dart' as http;

// using hardcoded API key for testing purposes
const apiKey = 'a62db0fee1e1de12a993982cece6a6bc';

class WeatherService {
  // Use this for Web version - Flutter Web
  //final String apiKey = dotenv.env['OPENWEATHER_API_KEY']!;
  // This is for Netlify version - Flutter not supported
  //final String apiKey = EnvConfig.weatherApiKey;
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';
  final String geoUrl = 'https://api.openweathermap.org/geo/1.0/direct';

  // Fetch Current Weather
  Future<Map<String, dynamic>> fetchCurrentWeather(String city) async {
    final url = '$baseUrl/weather?q=$city&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load current weather');
    }
  }

  // Fetch Air Quality Data
  Future<Map<String, dynamic>> fetchAirPollution(double lat, double lon) async {
    final url = '$baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$apiKey'; 
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load air quality data');
    }
  }

  // Fetch Location Suggestions
  Future<List<Map<String, dynamic>>> fetchLocationSuggestions(String city) async {
    final url = '$geoUrl?q=$city&limit=5&appid=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load location suggestions');
    }
  }

  // Fetch weather by coordinates
  Future<Map<String, dynamic>> fetchWeatherByCoords(double lat, double lon) async {
    final url = '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather by coordinates');
    }
  }

    // Fetch 5-day / 3-hour forecast (next 24 hours only)
    Future<List<Map<String, dynamic>>> fetchHourlyForecast(double lat, double lon) async {
      final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List forecasts = data['list'];
        return forecasts.take(8).map<Map<String, dynamic>>((item) => {
          'time': item['dt_txt'],
          'temp': item['main']['temp'],
          'icon': item['weather'][0]['icon'],
          'humidity': item['main']['humidity'],
        }).toList();
      } else {
        throw Exception('Failed to load hourly forecast');
      }
    }


}
