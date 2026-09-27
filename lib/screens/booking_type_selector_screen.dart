import 'package:flutter/material.dart';
import '../models/service_request_model.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFFFCF3EA);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
}

class BookingTypeSelector extends StatelessWidget {
  final String serviceName;
  final String serviceIcon;
  final Function(BookingType) onSelected;

  const BookingTypeSelector({
    super.key,
    required this.serviceName,
    required this.serviceIcon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.canvas,
      appBar: AppBar(
        backgroundColor: _AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: _AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _AppColors.line),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: _AppColors.ink),
            ),
          ),
        ),
        title: const Text('Booking Type',
            style: TextStyle(
                color: _AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(serviceIcon, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Choose booking type for',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _AppColors.inkSoft,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text(serviceName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _AppColors.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // INSTANT Option
              _BookingTypeCard(
                icon: Icons.flash_on_rounded,
                title: 'Book Now',
                subtitle: 'Instant Service',
                description: 'Vendor arrives in 15-20 minutes\nReal-time tracking available',
                isInstant: true,
                onTap: () {
                  onSelected(BookingType.instant);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 14),

              // SLOT Option
              _BookingTypeCard(
                icon: Icons.calendar_today_rounded,
                title: 'Schedule',
                subtitle: 'Slot Booking',
                description: 'Choose date & time\nVendor assigned 1-2 days before',
                isInstant: false,
                onTap: () {
                  onSelected(BookingType.slot);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingTypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isInstant;
  final VoidCallback onTap;

  const _BookingTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isInstant,
    required this.onTap,
  });

  @override
  State<_BookingTypeCard> createState() => _BookingTypeCardState();
}

class _BookingTypeCardState extends State<_BookingTypeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.96).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _AppColors.line, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: _AppColors.brandDeep, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _AppColors.ink)),
                        Text(widget.subtitle,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.brand, width: 2),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _AppColors.brand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: _AppColors.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
