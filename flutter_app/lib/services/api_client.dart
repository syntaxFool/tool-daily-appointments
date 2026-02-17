import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/data_models.dart';

/// Handles all API communication with Google Apps Script backend
class ApiClient {
  final http.Client _client = http.Client();

  /// Fetches all stylists with their tokens
  Future<List<Stylist>> fetchStylists() async {
    final uri = Uri.parse(apiBaseUrl).replace(queryParameters: {
      'action': 'stylists',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch stylists');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Stylists unavailable');
    }
    final list = (data['stylists'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(Stylist.fromJson).toList();
  }

  /// Fetches all consolidated invoice reports
  Future<List<Report>> fetchReports() async {
    final uri = Uri.parse(apiBaseUrl).replace(queryParameters: {
      'action': 'reports',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reports');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Reports unavailable');
    }
    final list = (data['reports'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(Report.fromJson).toList();
  }
}
