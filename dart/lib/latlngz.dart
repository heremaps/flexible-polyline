/// Coordinate triple
class LatLngZ {
  final double lat;
  final double lng;
  final double z;

  LatLngZ(this.lat, this.lng, [this.z = 0]);

  @override
  String toString() => "LatLngZ [lat=$lat, lng=$lng, z=$z]";

  @override
  bool operator ==(other) =>
      other is LatLngZ && other.lat == lat && other.lng == lng && other.z == z;

  @override
  int get hashCode => lat.hashCode + lng.hashCode + z.hashCode;
}

/// 3rd dimension specification.
/// Example a level, altitude, elevation or some other custom value.
/// ABSENT is default when there is no third dimension en/decoding required.
enum ThirdDimension {
  ABSENT,
  LEVEL,
  ALTITUDE,
  ELEVATION,
  RESERVED1,
  RESERVED2,
  CUSTOM1,
  CUSTOM2
}
