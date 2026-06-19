/// Simple data model for nearby lodging options shown during red alerts.
class Lodging {
  final String name;
  final String distance;
  final double rating;
  final String address;

  const Lodging({
    required this.name,
    required this.distance,
    required this.rating,
    required this.address,
  });

  /// Pre-loaded list of nearby lodging options (offline data).
  static const List<Lodging> nearbyDefaults = [
    Lodging(
      name: 'Hotel Camino Real',
      distance: '2.3 km',
      rating: 4.5,
      address: 'Av. Insurgentes Sur 1234',
    ),
    Lodging(
      name: 'Motel Descanso Seguro',
      distance: '5.1 km',
      rating: 4.0,
      address: 'Carr. Federal 45 Km 12',
    ),
    Lodging(
      name: 'Posada El Viajero',
      distance: '7.8 km',
      rating: 3.8,
      address: 'Blvd. López Mateos 567',
    ),
    Lodging(
      name: 'Hotel Express Ruta',
      distance: '10.2 km',
      rating: 4.2,
      address: 'Salida a Querétaro Km 3',
    ),
  ];
}
