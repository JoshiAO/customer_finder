import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/customer.dart';
import '../widgets/customer_info_modal.dart';

class CityBrgyPage extends StatefulWidget {
  const CityBrgyPage({super.key});

  @override
  State<CityBrgyPage> createState() => _CityBrgyPageState();
}

class _CityBrgyPageState extends State<CityBrgyPage> {
  late Future<List<Customer>> _customersFuture;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  String? _selectedStatus;
  bool _onlyWithLocation = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _barangays = [];
  List<Map<String, dynamic>> _allAreas = [];

  String _normalizeLocationValue(String? value) {
    return (value ?? '')
      .replaceAll(RegExp("^['\"]+"), '')
      .replaceAll(RegExp("['\"]+\$"), '')
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _canonicalLocationValue(String? value) {
    return _normalizeLocationValue(value).replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    final areas = await DatabaseService().loadCustomerAreas();
    _allAreas = areas;
    _provinces = areas
        .map<String>((a) => (a['province'] as String? ?? '').trim())
        .toSet()
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();

    if (mounted) {
      setState(() {
        _loadCustomers();
      });
    }
  }

  void _updateCities() {
    if (_selectedProvince != null) {
      final selectedProvince = _canonicalLocationValue(_selectedProvince);
      _cities = _allAreas
          .where((a) => _canonicalLocationValue(a['province'] as String?) == selectedProvince)
          .map<String>((a) => (a['city'] as String? ?? '').trim())
          .toSet()
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort();
      if (!_cities.contains(_selectedCity)) _selectedCity = null;
    } else {
      _cities = [];
      _selectedCity = null;
    }
    _updateBarangays();
    setState(() {});
  }

  void _updateBarangays() {
    if (_selectedProvince != null && _selectedCity != null) {
      final selectedProvince = _canonicalLocationValue(_selectedProvince);
      final selectedCity = _canonicalLocationValue(_selectedCity);
      _barangays = _allAreas
          .where((a) =>
          _canonicalLocationValue(a['province'] as String?) == selectedProvince &&
          _canonicalLocationValue(a['city'] as String?) == selectedCity)
          .map<String>((a) => (a['barangay'] as String? ?? '').trim())
          .toSet()
          .where((s) => s.isNotEmpty)
          .toList()
        ..sort();
      if (!_barangays.contains(_selectedBarangay)) _selectedBarangay = null;
    } else {
      _barangays = [];
      _selectedBarangay = null;
    }
    setState(() {});
  }

  void _loadCustomers() {
    _customersFuture = DatabaseService().getCustomersForCityBrgyCards(
      province: _selectedProvince,
      city: _selectedCity,
      barangay: _selectedBarangay,
      status: _selectedStatus,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedProvince = null;
      _selectedCity = null;
      _selectedBarangay = null;
      _selectedStatus = null;
      _onlyWithLocation = false;
      _searchQuery = '';
      _searchController.clear();
      _cities = [];
      _barangays = [];
      _loadCustomers();
    });
  }

  bool _hasValidLocation(Customer customer) {
    final lat = customer.latitude;
    final lng = customer.longitude;
    if (lat == null || lng == null) return false;
    return lat != 0 && lng != 0;
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      hint: Text(hint, overflow: TextOverflow.ellipsis),
      initialValue: safeValue,
      items: [
        DropdownMenuItem<String>(value: null, child: Text('All', style: TextStyle(color: Colors.grey[600]))),
        ...items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City/Brgy'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _onlyWithLocation = !_onlyWithLocation;
              });
            },
            icon: Icon(
              _onlyWithLocation ? Icons.location_on : Icons.location_off,
            ),
            tooltip: 'Only with Long-Lat',
          ),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Reset Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Customer Code, Name, or Person...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _buildDropdown(
                    hint: 'Status',
                    value: _selectedStatus,
                    items: const ['Active/Approved', 'Blocked/On hold'],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _loadCustomers();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: 'Province',
                    value: _selectedProvince,
                    items: _provinces,
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                        _updateCities();
                        _loadCustomers();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    hint: 'City',
                    value: _selectedCity,
                    items: _cities,
                    enabled: _selectedProvince != null,
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _updateBarangays();
                        _loadCustomers();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    hint: 'Barangay',
                    value: _selectedBarangay,
                    items: _barangays,
                    enabled: _selectedCity != null,
                    onChanged: (value) {
                      setState(() {
                        _selectedBarangay = value;
                        _loadCustomers();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _customersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final allCustomers = snapshot.data!;
                    final searchedCustomers = _searchQuery.isEmpty
                      ? allCustomers
                      : allCustomers.where((c) =>
                          c.customerCode.toLowerCase().contains(_searchQuery) ||
                          c.customerName.toLowerCase().contains(_searchQuery) ||
                        c.fullName.toLowerCase().contains(_searchQuery)).toList();

                    final customers = _onlyWithLocation
                      ? searchedCustomers.where(_hasValidLocation).toList()
                      : searchedCustomers;

                  if (customers.isEmpty) {
                    return const Center(child: Text('No customers found.'));
                  }

                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final provinceText = customer.province.trim().isEmpty ? 'N/A' : customer.province.trim();
                      final cityText = customer.city.trim().isEmpty ? 'N/A' : customer.city.trim();
                      final barangayText = customer.barangay.trim().isEmpty ? 'N/A' : customer.barangay.trim();
                      final isActive = customer.status == 'Active/Approved';
                      final statusColor = isActive ? Colors.green : Colors.red;
                      final hasLocation = _hasValidLocation(customer);
                      final mapColor = hasLocation ? Colors.green : Colors.red;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(customer.customerName),
                          subtitle: Text(
                            '${customer.customerCode} • ${customer.fullName}\n'
                            'Province: $provinceText\n'
                            'City: $cityText\n'
                            'Barangay: $barangayText',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(Icons.map, size: 18, color: mapColor),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 10, color: statusColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    customer.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => CustomerInfoModal(customer: customer),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}