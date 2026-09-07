enum BookingType { instant, slot }

enum RequestStatus {
  pending,
  assigned,
  enRoute,
  arrived,
  inProgress,
  completed,
  cancelled,
  rejected
}

class ServiceRequest {
  final int id;
  final int customerId;
  final int serviceId;
  final int serviceCategoryId;
  final String pincode;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final BookingType bookingType;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final int? timeSlotId;
  final String? description;
  final double budget;
  final RequestStatus status;
  final int? assignedVendorId;
  final String? vendorName;
  final String? vendorPhone;
  final String? vendorPhotoUrl;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? rating;
  final String? review;
  final String paymentStatus;

  ServiceRequest({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.serviceCategoryId,
    required this.pincode,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    required this.bookingType,
    this.scheduledDate,
    this.scheduledTime,
    this.timeSlotId,
    this.description,
    required this.budget,
    required this.status,
    this.assignedVendorId,
    this.vendorName,
    this.vendorPhone,
    this.vendorPhotoUrl,
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.rating,
    this.review,
    required this.paymentStatus,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      serviceId: json['service_id'] ?? 0,
      serviceCategoryId: json['service_category_id'] ?? 0,
      pincode: json['pincode'] ?? '',
      locationAddress: json['location_address'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      bookingType: json['booking_type'] == 'SLOT' ? BookingType.slot : BookingType.instant,
      scheduledDate: json['scheduled_date'] != null ? DateTime.tryParse(json['scheduled_date']) : null,
      scheduledTime: json['scheduled_time'],
      timeSlotId: json['time_slot_id'],
      description: json['description'],
      budget: json['budget'] != null ? double.tryParse(json['budget'].toString()) ?? 0.0 : 0.0,
      status: _parseStatus(json['status']),
      assignedVendorId: json['assigned_vendor_id'],
      vendorName: json['vendor_name'],
      vendorPhone: json['vendor_phone'],
      vendorPhotoUrl: json['vendor_photo_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      arrivedAt: json['arrived_at'] != null ? DateTime.parse(json['arrived_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      rating: json['rating'],
      review: json['review'],
      paymentStatus: json['payment_status'] ?? 'PENDING',
    );
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ASSIGNED':
        return RequestStatus.assigned;
      case 'EN_ROUTE':
        return RequestStatus.enRoute;
      case 'ARRIVED':
        return RequestStatus.arrived;
      case 'IN_PROGRESS':
        return RequestStatus.inProgress;
      case 'COMPLETED':
        return RequestStatus.completed;
      case 'CANCELLED':
        return RequestStatus.cancelled;
      case 'REJECTED':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }
}
