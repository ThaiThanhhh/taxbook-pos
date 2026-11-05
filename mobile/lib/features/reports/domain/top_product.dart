import 'package:flutter/foundation.dart';

/// Khớp schema TopProduct trong api/openapi.yaml.
@immutable
class TopProduct {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.qty,
    required this.revenueVnd,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      qty: (json['qty'] as num).toInt(),
      revenueVnd: (json['revenue_vnd'] as num).toInt(),
    );
  }

  final String productId;
  final String name;
  final int qty;
  final int revenueVnd;
}
