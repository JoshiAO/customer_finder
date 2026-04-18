class CustomerCounts {
  final int overall;
  final int active;
  final int inactive;

  CustomerCounts({
    required this.overall,
    required this.active,
    required this.inactive,
  });

  factory CustomerCounts.fromJson(Map<String, dynamic> json) {
    return CustomerCounts(
      overall: int.tryParse(json['overall'].toString()) ?? 0,
      active: int.tryParse(json['active'].toString()) ?? 0,
      inactive: int.tryParse(json['inactive'].toString()) ?? 0,
    );
  }
}