class DSP {
  final String salesRepId;
  final String dspCode;
  final String salesRepName;
  final int activeCount;
  final int blockedCount;
  final String team;
  final String supervisor;

  DSP({
    required this.salesRepId,
    this.dspCode = '',
    required this.salesRepName,
    required this.activeCount,
    required this.blockedCount,
    this.team = '',
    this.supervisor = '',
  });

  factory DSP.fromJson(Map<String, dynamic> json) {
    return DSP(
      salesRepId: (json['sales_rep_id'] ?? '').toString(),
      dspCode: (json['dsp_code'] ?? '').toString(),
      salesRepName: (json['sales_rep_name'] ?? '').toString(),
      activeCount: int.tryParse(json['active_count'].toString()) ?? 0,
      blockedCount: int.tryParse(json['blocked_count'].toString()) ?? 0,
      team: (json['team'] ?? '').toString(),
      supervisor: (json['supervisor'] ?? '').toString(),
    );
  }
}