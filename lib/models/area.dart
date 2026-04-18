class Area {
  final String province;
  final String city;
  final String barangay;

  Area({required this.province, required this.city, required this.barangay});

  factory Area.fromCsv(List<String> row) {
    return Area(
      province: row[0],
      city: row[1],
      barangay: row[2],
    );
  }
}