import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import '../models/dsp.dart';
import '../models/customer.dart';
import '../models/counts.dart';
import '../models/area.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  Future<List<DSP>> fetchDSPs() async {
    final response = await http.get(Uri.parse('$baseUrl/dsps'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => DSP.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load DSPs');
    }
  }

  Future<List<Customer>> fetchCustomersByDSP(String dspId, {String? status, String? coverageDay, String? wklyCoverage}) async {
    String url = '$baseUrl/customers/$dspId';
    Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (coverageDay != null) queryParams['coverageDay'] = coverageDay;
    if (wklyCoverage != null) queryParams['wklyCoverage'] = wklyCoverage;
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Customer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<List<Customer>> fetchCustomers({String? province, String? city, String? barangay}) async {
    String url = '$baseUrl/customers';
    Map<String, String> queryParams = {};
    if (province != null) queryParams['province'] = province;
    if (city != null) queryParams['city'] = city;
    if (barangay != null) queryParams['barangay'] = barangay;
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Customer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<CustomerCounts> fetchCounts() async {
    final response = await http.get(Uri.parse('$baseUrl/counts'));
    if (response.statusCode == 200) {
      return CustomerCounts.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load counts');
    }
  }

  Future<void> updateCustomerStatus(String customerCode, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$customerCode/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<void> updateCustomerInfo(String customerCode, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$customerCode'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer');
    }
  }

  Future<void> updateCustomerLocation(String customerCode, double latitude, double longitude) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$customerCode/location'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update location');
    }
  }

  Future<List<Area>> loadAreas() async {
    final csvString = await rootBundle.loadString('assets/Area.csv');
    final lines = csvString.split('\n').where((line) => line.isNotEmpty).toList();
    // Skip header
    return lines.skip(1).map((line) {
      final parts = line.split(',');
      return Area(province: parts[0], city: parts[1], barangay: parts[2]);
    }).toList();
  }
}