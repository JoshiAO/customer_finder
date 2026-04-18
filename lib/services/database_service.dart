import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart' as sqf;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/customer.dart';
import '../models/dsp.dart';
import '../models/counts.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  final customerStore = intMapStoreFactory.store('customers');
  final dspStore = intMapStoreFactory.store('dsps');
  Uint8List? _dspMasterOverrideBytes;

  Future<String?> _persistedDspCsvPath() async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'dsp_master_override.csv');
  }

  Future<void> _savePersistedDspCsv(Uint8List bytes) async {
    final path = await _persistedDspCsvPath();
    if (path == null) return;
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List?> _readPersistedDspCsv() async {
    final path = await _persistedDspCsvPath();
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return Uint8List.fromList(await file.readAsBytes());
  }

  String _normalizeHeader(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  String _normalizeDspCode(String raw) {
    return raw
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'\.0+$'), '');
  }

  String _cellString(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index].toString().trim();
  }

  List<Map<String, String>> _parseDspMasterFromBytes(Uint8List bytes) {
    final csvContent = String.fromCharCodes(bytes).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final csvTable = CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(csvContent);
    if (csvTable.isEmpty) return [];

    final header = csvTable.first.map((h) => _normalizeHeader(h.toString())).toList();
    final indexByHeader = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      indexByHeader[header[i]] = i;
    }

    int idx(List<String> aliases) {
      for (final key in aliases) {
        final normalized = _normalizeHeader(key);
        if (indexByHeader.containsKey(normalized)) return indexByHeader[normalized]!;
      }
      return -1;
    }

    var codeIdx = idx(['dsp_code', 'dsp code', 'sales_rep_id', 'sales rep id']);
    final nameIdx = idx(['dsp_name', 'dsp name', 'sales_rep_name', 'sales rep name']);
    final teamIdx = idx(['team']);
    final supervisorIdx = idx(['supervisor']);

    // Fallback: if code column header is non-standard, assume first column is code.
    if (codeIdx < 0 && header.isNotEmpty) {
      codeIdx = 0;
    }

    final parsed = <Map<String, String>>[];
    for (var i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      final code = _normalizeDspCode(_cellString(row, codeIdx));
      if (code.isEmpty) continue;

      parsed.add({
        'sales_rep_id': code,
        'sales_rep_name': _cellString(row, nameIdx),
        'team': _cellString(row, teamIdx),
        'supervisor': _cellString(row, supervisorIdx),
      });
    }

    return parsed;
  }

  Future<List<Map<String, String>>> _loadDspMasterRows() async {
    if (_dspMasterOverrideBytes != null) {
      final rows = _parseDspMasterFromBytes(_dspMasterOverrideBytes!);
      if (rows.isNotEmpty) return rows;
    }

    final persistedBytes = await _readPersistedDspCsv();
    if (persistedBytes != null) {
      _dspMasterOverrideBytes = persistedBytes;
      final rows = _parseDspMasterFromBytes(persistedBytes);
      if (rows.isNotEmpty) return rows;
    }

    try {
      final assetBytes = await rootBundle.load('assets/DSP.csv');
      return _parseDspMasterFromBytes(assetBytes.buffer.asUint8List());
    } catch (_) {
      return <Map<String, String>>[];
    }
  }

  static String _sanitizeFolderSegment(String input) {
    return input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String customerImageFolderName(Customer customer) {
    final code = _sanitizeFolderSegment(customer.customerCode);
    final name = _sanitizeFolderSegment(customer.customerName);
    return '$code - $name';
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    DatabaseFactory dbFactory;
    String dbPath;

    if (kIsWeb) {
      dbFactory = databaseFactoryWeb;
      dbPath = 'kenea_sembast.db';
    } else {
      final dbsPath = await sqflite.getDatabasesPath();
      dbPath = p.join(dbsPath, 'kenea_sembast.db'); // new name avoids conflict with old sqflite db
      dbFactory = sqf.getDatabaseFactorySqflite(sqflite.databaseFactory);
    }

    return await dbFactory.openDatabase(dbPath, version: 1, onVersionChanged: _onVersionChanged);
  }

  Future<void> _onVersionChanged(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      // Create stores if needed, but sembast handles it
    }
  }

  Future<List<Customer>> _parseCustomersFromBytes(
    Uint8List bytes, {
    required bool isXlsx,
    void Function(double)? onProgress,
  }) async {
    List<String> header;
    List<List<dynamic>> dataRows;

    if (isXlsx) {
      final excel = xl.Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return [];
      final sheet = excel.tables.values.first;
      if (sheet.rows.isEmpty) return [];
      header = sheet.rows.first
          .map((cell) => (cell?.value?.toString() ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_'))
          .toList();
      dataRows = sheet.rows.skip(1).map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList()).toList();
    } else {
      // Normalize line endings before parsing
      final csvContent = String.fromCharCodes(bytes).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final csvTable = CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(csvContent);
      if (csvTable.isEmpty) return [];
      header = csvTable.first.map((value) => value.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')).toList();
      dataRows = csvTable.skip(1).toList();
    }

    final headerMap = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      headerMap[header[i]] = i;
    }

    int getIndex(List<String> names) {
      for (var name in names) {
        if (headerMap.containsKey(name)) return headerMap[name]!;
      }
      return -1;
    }

    final customers = <Customer>[];
    final totalRows = dataRows.length;
    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.every((cell) => cell == null || cell.toString().trim().isEmpty)) continue;

      String field(List<String> names, [String defaultValue = '']) {
        final idx = getIndex(names);
        if (idx < 0) return defaultValue;
        return idx < row.length ? row[idx].toString() : defaultValue;
      }

      final rawFirstName = field(['first_name', 'first name']);
      final rawLastName = field(['last_name', 'last name']);
      final rawOwner = field(['owner']);

      var resolvedFirstName = rawFirstName;
      var resolvedLastName = rawLastName;
      if (resolvedFirstName.isEmpty && resolvedLastName.isEmpty && rawOwner.isNotEmpty) {
        final parts = rawOwner.split(RegExp(r'\s+'));
        resolvedFirstName = parts.first;
        resolvedLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      customers.add(
        Customer(
          branchName: field(['branch_name', 'branch name']),
          cdam: field(['cdam']),
          fs: field(['fs']),
          channel: field(['channel']),
          salesRepId: field(['sales_rep_id', 'sales rep id', 'salesrep_id', 'salesrepid']),
          salesRepName: field(['sales_rep_name', 'sales rep name', 'salesrep_name', 'salesrepname']),
          customerCode: field(['customer_code', 'customer code']),
          customerName: field(['customer_name', 'customer name']),
          barangay: field(['barangay']),
          city: field(['city']),
          province: field(['province']),
          status: field(['status']),
          retailEnvironment: field(['retail_environment', 'retail environment']),
          partyClassificationDescription: field(['party_classification_description', 'party classification description']),
          coverageDay: field(['coverage_day', 'coverage day']),
          wklyCoverage: field(['wkly_coverage', 'wkly coverage']),
          freqCount: int.tryParse(field(['freq_count', 'freq count'], '0')) ?? 0,
          freq: field(['freq']),
          latitude: double.tryParse(field(['latitude', 'lat', 'gps_latitude', 'gps latitude'])),
          longitude: double.tryParse(field(['longitude', 'long', 'lng', 'gps_longitude', 'gps longitude'])),
          phone: field(['phone']),
          firstName: resolvedFirstName,
          lastName: resolvedLastName,
          address: field(['address']),
          tinNo: field(['tin_no', 'tin no']),
        ),
      );

      if ((i + 1) % 200 == 0) {
        if (totalRows > 0) {
          onProgress?.call((i + 1) / totalRows);
        }
        // Yield to event loop so frames can render during large imports.
        await Future<void>.delayed(Duration.zero);
      }
    }

    onProgress?.call(1.0);

    return customers;
  }

  Map<String, dynamic> _buildDspRecord(Customer customer) {
    return {
      'sales_rep_id': customer.salesRepId,
      'sales_rep_name': customer.salesRepName,
      'branch_name': customer.branchName,
      'cdam': customer.cdam,
      'fs': customer.fs,
      'channel': customer.channel,
    };
  }

  Future<void> importCML(Uint8List bytes, {bool isXlsx = false, void Function(double)? onProgress}) async {
    final db = await database;
    final customers = await _parseCustomersFromBytes(
      bytes,
      isXlsx: isXlsx,
      onProgress: (p) => onProgress?.call(p * 0.35),
    );

    final total = customers.length;
    await db.transaction((txn) async {
      await customerStore.delete(txn);
      await dspStore.delete(txn);

      final seenDspIds = <String>{};
      for (var i = 0; i < customers.length; i++) {
        final customer = customers[i];
        await customerStore.add(txn, customer.toJson());

        if (customer.salesRepId.isNotEmpty && seenDspIds.add(customer.salesRepId)) {
          await dspStore.add(txn, _buildDspRecord(customer));
        }

        if (total > 0) {
          onProgress?.call(0.35 + (((i + 1) / total) * 0.65));
        }
        if ((i + 1) % 200 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    });
  }

  Future<void> importDSPList(Uint8List bytes) async {
    final rows = _parseDspMasterFromBytes(bytes);
    if (rows.isEmpty) {
      throw Exception('No valid DSP rows found in CSV.');
    }

    _dspMasterOverrideBytes = bytes;
    await _savePersistedDspCsv(bytes);
  }

  Future<int> updateCML(Uint8List bytes, {bool isXlsx = false, void Function(double)? onProgress}) async {
    final db = await database;
    final incomingCustomers = await _parseCustomersFromBytes(
      bytes,
      isXlsx: isXlsx,
      onProgress: (p) => onProgress?.call(p * 0.30),
    );

    if (incomingCustomers.isEmpty) {
      onProgress?.call(1.0);
      return 0;
    }

    final existingRecords = await customerStore.find(db);
    final existingCodes = existingRecords
        .map((record) => (record.value['customer_code'] as String? ?? '').trim())
        .where((code) => code.isNotEmpty)
        .toSet();

    final existingDspRecords = await dspStore.find(db);
    final existingDspIds = existingDspRecords
        .map((record) => (record.value['sales_rep_id'] as String? ?? '').trim())
        .where((code) => code.isNotEmpty)
        .toSet();

    var added = 0;
    final total = incomingCustomers.length;
    await db.transaction((txn) async {
      for (var i = 0; i < incomingCustomers.length; i++) {
        final customer = incomingCustomers[i];
        if (customer.customerCode.isNotEmpty && !existingCodes.contains(customer.customerCode)) {
          await customerStore.add(txn, customer.toJson());
          if (customer.salesRepId.isNotEmpty && existingDspIds.add(customer.salesRepId)) {
            await dspStore.add(txn, _buildDspRecord(customer));
          }
          existingCodes.add(customer.customerCode);
          added++;
        }
        if (total > 0) {
          onProgress?.call(0.30 + (((i + 1) / total) * 0.70));
        }
        if ((i + 1) % 200 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    });

    return added;
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final records = await customerStore.find(db);
    return records.map((record) => Customer.fromJson(record.value)).toList();
  }

  Future<List<Customer>> getCustomersByDSP(String dspId, {String? status, String? coverageDay, String? wklyCoverage}) async {
    final db = await database;
    var filter = Filter.equals('sales_rep_id', dspId);
    if (status != null) {
      filter = filter & Filter.equals('status', status);
    }
    if (coverageDay != null) {
      filter = filter & Filter.equals('coverage_day', coverageDay);
    }
    if (wklyCoverage != null) {
      filter = filter & Filter.equals('wkly_coverage', wklyCoverage);
    }
    final records = await customerStore.find(db, finder: Finder(filter: filter));
    return records.map((record) => Customer.fromJson(record.value)).toList();
  }

  Future<List<Customer>> getCustomersFiltered({String? province, String? city, String? barangay, String? status}) async {
    final db = await database;
    final filters = <Filter>[];
    if (province != null) {
      filters.add(Filter.equals('province', province));
    }
    if (city != null) {
      filters.add(Filter.equals('city', city));
    }
    if (barangay != null) {
      filters.add(Filter.equals('barangay', barangay));
    }
    if (status != null) {
      filters.add(Filter.equals('status', status));
    }
    final finder = filters.isNotEmpty ? Finder(filter: Filter.and(filters)) : null;
    final records = await customerStore.find(db, finder: finder);
    return records.map((record) => Customer.fromJson(record.value)).toList();
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    final record = await customerStore.findFirst(db, finder: Finder(filter: Filter.equals('customer_code', customer.customerCode)));
    if (record != null) {
      await customerStore.record(record.key).update(db, customer.toJson());
    }
  }

  Future<CustomerCounts> getCounts() async {
    final db = await database;
    final overall = await customerStore.count(db);
    final active = await customerStore.count(
      db,
      filter: Filter.equals('status', 'Active/Approved'),
    );
    final inactive = overall - active;
    return CustomerCounts(overall: overall, active: active, inactive: inactive);
  }

  Future<int> getEditedCount() async {
    final db = await database;
    return customerStore.count(db, filter: Filter.and([
      Filter.notEquals('edited_fields', null),
      Filter.notEquals('edited_fields', ''),
    ]));
  }

  Future<List<DSP>> fetchDSPs() async {
    final db = await database;
    final masterByCode = <String, Map<String, dynamic>>{};
    final masterRows = await _loadDspMasterRows();
    for (final row in masterRows) {
      final code = _normalizeDspCode((row['sales_rep_id'] ?? '').toString());
      if (code.isEmpty) continue;
      masterByCode[code] = row;
    }

    final customerRecords = await customerStore.find(db);
    final dspMap = <String, Map<String, dynamic>>{};

    for (var record in customerRecords) {
      final data = record.value;
      final rawSalesRepId = (data['sales_rep_id'] as String? ?? '').trim();
      final salesRepId = _normalizeDspCode(rawSalesRepId);
      if (salesRepId.isNotEmpty) {
        if (!dspMap.containsKey(salesRepId)) {
          dspMap[salesRepId] = {
            'sales_rep_id': rawSalesRepId,
            'dsp_code': '',
            'sales_rep_name': '',
            'team': '',
            'supervisor': '',
            'active_count': 0,
            'blocked_count': 0,
          };
        }
        if (data['status'] == 'Active/Approved') {
          dspMap[salesRepId]!['active_count'] = (dspMap[salesRepId]!['active_count'] as int) + 1;
        } else {
          dspMap[salesRepId]!['blocked_count'] = (dspMap[salesRepId]!['blocked_count'] as int) + 1;
        }
      }
    }

    for (final code in masterByCode.keys) {
      dspMap.putIfAbsent(
        code,
        () => {
          'sales_rep_id': '',
          'dsp_code': code,
          'sales_rep_name': '',
          'team': '',
          'supervisor': '',
          'active_count': 0,
          'blocked_count': 0,
        },
      );
    }

    for (final entry in dspMap.entries) {
      final code = entry.key;
      final master = masterByCode[code];
      if (master == null) continue;

      final masterName = (master['sales_rep_name'] as String? ?? '').trim();
      if (masterName.isNotEmpty) {
        entry.value['sales_rep_name'] = masterName;
      }
      entry.value['dsp_code'] = code;
      entry.value['team'] = (master['team'] as String? ?? '').trim();
      entry.value['supervisor'] = (master['supervisor'] as String? ?? '').trim();
    }

    final list = dspMap.values.map((dsp) => DSP.fromJson(dsp)).toList();
    list.sort((a, b) {
      final aCode = a.dspCode.isNotEmpty ? a.dspCode : a.salesRepId;
      final bCode = b.dspCode.isNotEmpty ? b.dspCode : b.salesRepId;
      return aCode.compareTo(bCode);
    });
    return list;
  }

  Future<List<Customer>> getEditedCustomers() async {
    final db = await database;
    final records = await customerStore.find(db, finder: Finder(filter: Filter.and([
      Filter.notEquals('edited_fields', null),
      Filter.notEquals('edited_fields', ''),
    ])));
    return records.map((record) => Customer.fromJson(record.value)).toList();
  }

  Future<List<Map<String, dynamic>>> loadAreas() async {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    try {
      final csvRaw = await rootBundle.loadString('assets/Area.csv');
      final csvTable = CsvToListConverter(eol: '\n', shouldParseNumbers: false)
          .convert(csvRaw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

      for (var i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.length < 3) continue;
        final province = row[0].toString().trim();
        final city = row[1].toString().trim();
        final barangay = row[2].toString().trim();
        if (province.isEmpty || city.isEmpty || barangay.isEmpty) continue;

        final key = '$province|$city|$barangay';
        if (seen.add(key)) {
          result.add({'province': province, 'city': city, 'barangay': barangay});
        }
      }

      if (result.isNotEmpty) return result;
    } catch (_) {
      // Fall back to areas derived from customer data if asset read fails.
    }

    final db = await database;
    final records = await customerStore.find(db);
    for (final record in records) {
      final province = (record.value['province'] as String? ?? '').trim();
      final city = (record.value['city'] as String? ?? '').trim();
      final barangay = (record.value['barangay'] as String? ?? '').trim();
      if (province.isEmpty || city.isEmpty || barangay.isEmpty) continue;

      final key = '$province|$city|$barangay';
      if (seen.add(key)) {
        result.add({'province': province, 'city': city, 'barangay': barangay});
      }
    }
    return result;
  }

  Future<void> clearAllData({void Function(double)? onProgress}) async {
    final db = await database;
    final customerKeys = await customerStore.findKeys(db);
    final dspKeys = await dspStore.findKeys(db);
    final total = customerKeys.length + dspKeys.length;

    if (total == 0) {
      onProgress?.call(1.0);
      return;
    }

    var processed = 0;
    for (final key in customerKeys) {
      await customerStore.record(key).delete(db);
      processed++;
      onProgress?.call(processed / total);
    }
    for (final key in dspKeys) {
      await dspStore.record(key).delete(db);
      processed++;
      onProgress?.call(processed / total);
    }
  }

  Future<String> exportEditedCustomers() async {
    final customers = await getEditedCustomers();
    List<List<dynamic>> csvData = [
      ['Customer Code', 'Customer Name', 'Barangay', 'City', 'Province', 'Status', 'Retail Environment', 'Party Classification Description', 'Coverage Day', 'Wkly Coverage', 'Freq Count', 'Freq', 'Latitude', 'Longitude', 'Phone', 'First Name', 'Last Name', 'Address', 'TIN No', 'Edited Fields']
    ];
    for (var customer in customers) {
      csvData.add([
        customer.customerCode,
        customer.customerName,
        customer.barangay,
        customer.city,
        customer.province,
        customer.status,
        customer.retailEnvironment,
        customer.partyClassificationDescription,
        customer.coverageDay,
        customer.wklyCoverage,
        customer.freqCount,
        customer.freq,
        customer.latitude,
        customer.longitude,
        customer.phone,
        customer.firstName,
        customer.lastName,
        customer.address,
        customer.tinNo,
        customer.editedFields ?? '',
      ]);
    }
    return ListToCsvConverter().convert(csvData);
  }

  Future<Uint8List> exportEditedCustomersXlsx({void Function(double)? onProgress}) async {
    final customers = await getEditedCustomers();
    final excel = xl.Excel.createExcel();
    final sheet = excel['Edited Customers'];

    sheet.appendRow([
      xl.TextCellValue('Customer Code'),
      xl.TextCellValue('Customer Name'),
      xl.TextCellValue('Barangay'),
      xl.TextCellValue('City'),
      xl.TextCellValue('Province'),
      xl.TextCellValue('Status'),
      xl.TextCellValue('Retail Environment'),
      xl.TextCellValue('Party Classification Description'),
      xl.TextCellValue('Coverage Day'),
      xl.TextCellValue('Wkly Coverage'),
      xl.TextCellValue('Freq Count'),
      xl.TextCellValue('Freq'),
      xl.TextCellValue('Latitude'),
      xl.TextCellValue('Longitude'),
      xl.TextCellValue('Phone'),
      xl.TextCellValue('First Name'),
      xl.TextCellValue('Last Name'),
      xl.TextCellValue('Address'),
      xl.TextCellValue('TIN No'),
      xl.TextCellValue('Edited Fields')
    ]);

    if (customers.isEmpty) {
      onProgress?.call(1.0);
      return Uint8List.fromList(excel.encode() ?? <int>[]);
    }

    for (var i = 0; i < customers.length; i++) {
      final customer = customers[i];
      sheet.appendRow([
        xl.TextCellValue(customer.customerCode),
        xl.TextCellValue(customer.customerName),
        xl.TextCellValue(customer.barangay),
        xl.TextCellValue(customer.city),
        xl.TextCellValue(customer.province),
        xl.TextCellValue(customer.status),
        xl.TextCellValue(customer.retailEnvironment),
        xl.TextCellValue(customer.partyClassificationDescription),
        xl.TextCellValue(customer.coverageDay),
        xl.TextCellValue(customer.wklyCoverage),
        xl.IntCellValue(customer.freqCount),
        xl.TextCellValue(customer.freq),
        xl.TextCellValue(customer.latitude?.toString() ?? ''),
        xl.TextCellValue(customer.longitude?.toString() ?? ''),
        xl.TextCellValue(customer.phone),
        xl.TextCellValue(customer.firstName),
        xl.TextCellValue(customer.lastName),
        xl.TextCellValue(customer.address),
        xl.TextCellValue(customer.tinNo),
        xl.TextCellValue(customer.editedFields ?? ''),
      ]);
      onProgress?.call((i + 1) / customers.length);
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  Future<int> clearEditedCustomersFlags() async {
    final db = await database;
    final records = await customerStore.find(db, finder: Finder(filter: Filter.and([
      Filter.notEquals('edited_fields', null),
      Filter.notEquals('edited_fields', ''),
    ])));

    for (final record in records) {
      final updated = Map<String, dynamic>.from(record.value);
      updated['edited_fields'] = '';
      await customerStore.record(record.key).put(db, updated);
    }

    return records.length;
  }
}