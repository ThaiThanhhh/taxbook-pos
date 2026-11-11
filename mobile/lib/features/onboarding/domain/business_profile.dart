import 'package:dt13_pos/features/tax/domain/tax_engine.dart';
import 'package:flutter/foundation.dart';

@immutable
class BusinessProfile {
  const BusinessProfile({
    required this.taxCode,
    required this.businessName,
    required this.primarySector,
    required this.taxMethod,
    this.address,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      taxCode: json['taxCode'] as String,
      businessName: json['businessName'] as String,
      address: json['address'] as String?,
      primarySector: TaxSector.values.byName(json['primarySector'] as String),
      taxMethod: json['taxMethod'] as String,
    );
  }

  static const Object _notProvided = Object();

  final String taxCode;
  final String businessName;
  final String? address;
  final TaxSector primarySector;
  final String taxMethod;

  Map<String, Object?> toJson() => {
    'taxCode': taxCode,
    'businessName': businessName,
    'address': address,
    'primarySector': primarySector.name,
    'taxMethod': taxMethod,
  };

  BusinessProfile copyWith({
    String? taxCode,
    String? businessName,
    Object? address = _notProvided,
    TaxSector? primarySector,
    String? taxMethod,
  }) {
    return BusinessProfile(
      taxCode: taxCode ?? this.taxCode,
      businessName: businessName ?? this.businessName,
      address: identical(address, _notProvided)
          ? this.address
          : address as String?,
      primarySector: primarySector ?? this.primarySector,
      taxMethod: taxMethod ?? this.taxMethod,
    );
  }
}
