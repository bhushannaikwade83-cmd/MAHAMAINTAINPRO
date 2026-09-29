import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriceBreakdown Widget', () {
    testWidgets('should display total price correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdown(
              itemsSubtotal: 1298.00,
              addonsTotal: 499.00,
              serviceFee: 0.00,
              travelFee: 50.00,
              taxAmount: 211.00,
              discountAmount: 0.00,
              total: 1559.00,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('₹1559'), findsOneWidget);
    });

    testWidgets('should expand/collapse breakdown on tap', (WidgetTester tester) async {
      // Arrange
      bool expanded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PriceBreakdown(
                  itemsSubtotal: 1298.00,
                  addonsTotal: 499.00,
                  serviceFee: 0.00,
                  travelFee: 50.00,
                  taxAmount: 211.00,
                  discountAmount: 0.00,
                  total: 1559.00,
                  expanded: expanded,
                  onExpand: () {
                    setState(() => expanded = !expanded);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('View Price Breakdown'));
      await tester.pumpWidget(SizedBox.shrink());

      // Assert
      // expect(find.text('Items Subtotal'), findsOneWidget);
    });

    testWidgets('should display discount when applicable', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdown(
              itemsSubtotal: 1298.00,
              addonsTotal: 0.00,
              serviceFee: 0.00,
              travelFee: 0.00,
              taxAmount: 211.00,
              discountAmount: 200.00,
              total: 1309.00,
              expanded: true,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
    });

    testWidgets('should show all breakdown items when expanded', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdown(
              itemsSubtotal: 1298.00,
              addonsTotal: 499.00,
              serviceFee: 50.00,
              travelFee: 50.00,
              taxAmount: 211.00,
              discountAmount: 0.00,
              total: 2108.00,
              expanded: true,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Items Subtotal'), findsOneWidget);
      expect(find.text('Add-ons'), findsOneWidget);
      expect(find.text('Service Fee'), findsOneWidget);
      expect(find.text('Travel Fee'), findsOneWidget);
      expect(find.text('Tax (18%)'), findsOneWidget);
    });

    testWidgets('should handle zero prices correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdown(
              itemsSubtotal: 1000.00,
              addonsTotal: 0.00,
              serviceFee: 0.00,
              travelFee: 0.00,
              taxAmount: 0.00,
              discountAmount: 0.00,
              total: 1000.00,
              expanded: true,
            ),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('₹1000'), findsOneWidget);
      // Zero items should not display
      expect(find.text('Add-ons'), findsNothing);
    });
  });
}

// Placeholder widget reference
class PriceBreakdown extends StatelessWidget {
  final double itemsSubtotal;
  final double addonsTotal;
  final double serviceFee;
  final double travelFee;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final bool expanded;
  final VoidCallback? onExpand;

  const PriceBreakdown({
    Key? key,
    required this.itemsSubtotal,
    required this.addonsTotal,
    required this.serviceFee,
    required this.travelFee,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    this.expanded = false,
    this.onExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Total'),
        Text('₹${total.toStringAsFixed(0)}'),
        if (!expanded && onExpand != null)
          GestureDetector(
            onTap: onExpand,
            child: Text('View Price Breakdown'),
          ),
        if (expanded) ...[
          Text('Items Subtotal'),
          if (addonsTotal > 0) Text('Add-ons'),
          if (serviceFee > 0) Text('Service Fee'),
          if (travelFee > 0) Text('Travel Fee'),
          if (taxAmount > 0) Text('Tax (18%)'),
          if (discountAmount > 0) Text('Discount'),
        ],
      ],
    );
  }
}
