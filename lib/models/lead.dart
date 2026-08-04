class Lead {
  final String id;
  final String societyName;
  final String contactPersonName;
  final String city;
  final double dealValueEstimate;
  final bool isOverdue;
  final DateTime? nextFollowUpAt;

  Lead({
    required this.id,
    required this.societyName,
    required this.contactPersonName,
    required this.city,
    required this.dealValueEstimate,
    required this.isOverdue,
    this.nextFollowUpAt,
  });
}
