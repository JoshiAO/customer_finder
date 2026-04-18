import 'package:flutter_test/flutter_test.dart';
import 'package:kenea_customers/services/database_service.dart';

void main() {
  group('Customer location extraction', () {
    test('reads canonical province/city/barangay keys', () {
      final raw = <String, dynamic>{
        'province': 'NUEVA ECIJA',
        'city': 'CABANATUAN CITY',
        'barangay': 'CABU',
      };

      final extracted = DatabaseService.extractCanonicalLocationFields(raw);

      expect(extracted['province'], 'NUEVA ECIJA');
      expect(extracted['city'], 'CABANATUAN CITY');
      expect(extracted['barangay'], 'CABU');
    });

    test('reads fallback aliases used by CML templates', () {
      final raw = <String, dynamic>{
        'Province Name': 'NUEVA ECIJA',
        'city/municipality': 'CABANATUAN CITY',
        'BRGY': 'CABU',
      };

      final extracted = DatabaseService.extractCanonicalLocationFields(raw);

      expect(extracted['province'], 'NUEVA ECIJA');
      expect(extracted['city'], 'CABANATUAN CITY');
      expect(extracted['barangay'], 'CABU');
    });

    test('cleans quotes and whitespace from location fields', () {
      final raw = <String, dynamic>{
        'province': '  "NUEVA ECIJA"  ',
        'city': "  'CABANATUAN CITY'  ",
        'barangay': '  CABU  ',
      };

      final extracted = DatabaseService.extractCanonicalLocationFields(raw);

      expect(extracted['province'], 'NUEVA ECIJA');
      expect(extracted['city'], 'CABANATUAN CITY');
      expect(extracted['barangay'], 'CABU');
    });
  });
}
