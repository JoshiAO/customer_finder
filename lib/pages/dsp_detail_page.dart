import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/dsp.dart';
import '../models/customer.dart';
import '../widgets/customer_info_modal.dart';

class DSPDetailPage extends StatefulWidget {
  final DSP dsp;

  const DSPDetailPage({super.key, required this.dsp});

  @override
  State<DSPDetailPage> createState() => _DSPDetailPageState();
}

class _DSPDetailPageState extends State<DSPDetailPage> {
  late Future<List<Customer>> _customersFuture;
  String? _selectedStatus;
  String? _selectedCoverageDay;
  String? _selectedWklyCoverage;
  bool _onlyWithLocation = false;

  final Map<String, String> _coverageDayMap = {
    'Monday': 'MON',
    'Tuesday': 'TUE',
    'Wednesday': 'WED',
    'Thursday': 'THU',
    'Friday': 'FRI',
    'Saturday': 'SAT',
  };

  final Map<String, String> _wklyCoverageMap = {
    'Weekly': 'WKLY',
    'Week 1 and 3': 'W1&W3',
    'Week 2 and 4': 'W2&W4',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    _customersFuture = DatabaseService().getCustomersByDSP(
      widget.dsp.salesRepId,
      status: _selectedStatus,
      coverageDay: _selectedCoverageDay,
      wklyCoverage: _selectedWklyCoverage,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedCoverageDay = null;
      _selectedWklyCoverage = null;
      _onlyWithLocation = false;
      _loadCustomers();
    });
  }

  bool _hasValidLocation(Customer customer) {
    final lat = customer.latitude;
    final lng = customer.longitude;
    if (lat == null || lng == null) return false;
    return lat != 0 && lng != 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dsp.salesRepName),
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text('Status'),
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem<String>(value: null, child: Text('Status')),
                      DropdownMenuItem<String>(value: 'Active/Approved', child: Text('Active/Approved')),
                      DropdownMenuItem<String>(value: 'Blocked/On hold', child: Text('Blocked/On hold')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _loadCustomers();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text('Coverage Day'),
                    value: _selectedCoverageDay,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Coverage Day')),
                      ..._coverageDayMap.entries
                          .map((e) => DropdownMenuItem<String>(value: e.value, child: Text(e.key))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCoverageDay = value;
                        _loadCustomers();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    hint: Text('Wkly Coverage'),
                    value: _selectedWklyCoverage,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Wkly Coverage')),
                      ..._wklyCoverageMap.entries
                          .map((e) => DropdownMenuItem<String>(value: e.value, child: Text(e.key))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedWklyCoverage = value;
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
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final customers = snapshot.data!;
                  final filteredCustomers = _onlyWithLocation
                      ? customers.where(_hasValidLocation).toList()
                      : customers;

                  if (filteredCustomers.isEmpty) {
                    return const Center(child: Text('No customers found.'));
                  }

                  return ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      final isActive = customer.status == 'Active/Approved';
                      final statusColor = isActive ? Colors.green : Colors.red;
                      final hasLocation = _hasValidLocation(customer);
                      final mapColor = hasLocation ? Colors.green : Colors.red;
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(customer.customerCode),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.customerName),
                              Text(customer.phone),
                              Text('${customer.firstName} ${customer.lastName}'.trim()),
                              Text(customer.address),
                              Text(customer.partyClassificationDescription),
                              Text(customer.coverageDay),
                              Text(customer.wklyCoverage),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
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
                            ],
                          ),
                          onTap: () async {
                            final didUpdate = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => CustomerInfoModal(customer: customer),
                            );
                            if (didUpdate == true && mounted) {
                              setState(_loadCustomers);
                            }
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