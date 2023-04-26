import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _controller;
  late Future<LatLng> _currentLocation;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _currentLocation = _getCurrentLocation();
  }

  Future<void> _requestLocationPermission() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      // Permission granted
      final currLoc = await _currentLocation;
    } else {
      // Permission denied
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  Future<List<LatLng>> _getNearbyHospitals(LatLng currentPosition) async {
    // Use your preferred APIs or libraries to fetch the list of nearby hospitals.
    // For example, you can use the Google Places API.
    // Here's an example using mock data:
    return [
      LatLng(37.785808, -122.406417), // San Francisco General Hospital
      LatLng(37.761549, -122.415601), // St. Mary's Medical Center
      LatLng(37.773447, -122.437935), // UCSF Medical Center
    ];
  }

  Future<void> _updateMarkers() async {
    final nearbyHospitals = await _getNearbyHospitals(await _currentLocation);
    final updatedMarkers = nearbyHospitals
        .map((hospital) => Marker(
            markerId: MarkerId(hospital.toString()),
            position: hospital,
            infoWindow: InfoWindow(title: 'Hospital')))
        .toSet();
    setState(() {
      _markers.clear();
      _markers.addAll(updatedMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BetterHealth'),
        ),
        body: FutureBuilder<LatLng>(
          future: _currentLocation,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _controller = controller,
                    initialCameraPosition: CameraPosition(
                      target: snapshot.data ?? LatLng(0, 0),
                      zoom: 14,
                    ),
                    markers: Set.from([
                      Marker(
                        markerId: MarkerId('Current Location'),
                        position: snapshot.data ?? LatLng(0, 0),
                        infoWindow: InfoWindow(title: 'You are here'),
                      )
                    ]),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: () async {
                        final loc = await _getCurrentLocation();
                        _controller.animateCamera(
                            CameraUpdate.newCameraPosition(
                                CameraPosition(target: loc, zoom: 14)));
                        setState(() {
                          _currentLocation = Future.value(loc);
                        });
                      },
                      child: Icon(Icons.my_location),
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}
