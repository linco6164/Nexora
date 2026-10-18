class SamedayOohLocation {
  final int oohId;
  final int oohType;

  final String name;
  final String country;
  final String county;
  final String city;
  final String address;
  final String? postalCode;

  final double lat;
  final double lng;

  final int? supportedPayment;
  final int? clientVisible;
  final int? occupancyLevel;
  final int? capacityExceeded;

  const SamedayOohLocation({
    required this.oohId,
    required this.oohType,
    required this.name,
    required this.country,
    required this.county,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    this.postalCode,
    this.supportedPayment,
    this.clientVisible,
    this.occupancyLevel,
    this.capacityExceeded,
  });

  factory SamedayOohLocation.fromJson(
    Map<String, dynamic> json,
  ) {
    return SamedayOohLocation(
      oohId: _toInt(
        json['oohId'],
      ),
      oohType: _toInt(
        json['oohType'],
      ),
      name: (
        json['name'] ??
        ''
      ).toString(),
      country: (
        json['country'] ??
        ''
      ).toString(),
      county: (
        json['county'] ??
        ''
      ).toString(),
      city: (
        json['city'] ??
        ''
      ).toString(),
      address: (
        json['address'] ??
        ''
      ).toString(),
      postalCode:
          json['postalCode']
              ?.toString(),
      lat: _toDouble(
        json['lat'],
      ),
      lng: _toDouble(
        json['lng'],
      ),
      supportedPayment:
          _toNullableInt(
        json['supportedPayment'],
      ),
      clientVisible:
          _toNullableInt(
        json['clientVisible'],
      ),
      occupancyLevel:
          _toNullableInt(
        json['occupancyLevel'],
      ),
      capacityExceeded:
          _toNullableInt(
        json['capacityExceeded'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oohId': oohId,
      'oohType': oohType,
      'name': name,
      'country': country,
      'county': county,
      'city': city,
      'address': address,
      'postalCode': postalCode,
      'lat': lat,
      'lng': lng,
      'supportedPayment':
          supportedPayment,
      'clientVisible':
          clientVisible,
      'occupancyLevel':
          occupancyLevel,
      'capacityExceeded':
          capacityExceeded,
    };
  }

  bool get isEasybox =>
      oohType == 0;

  bool get isVisible =>
      clientVisible == null ||
      clientVisible == 1;

  bool get isCapacityExceeded =>
      capacityExceeded == 1;

  String get fullAddress {
    final parts = <String>[
      address,
      city,
      county,
    ].where(
      (value) =>
          value.trim().isNotEmpty,
    );

    return parts.join(', ');
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static double _toDouble(
    dynamic value,
  ) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }
}