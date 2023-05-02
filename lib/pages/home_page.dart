import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:better_health/api/api_client.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      _getCurrentLocation().then((location) => _getNearbyHospitals(location)
          .then((hospitals) => setState(() => _markers.addAll(hospitals))));
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  Future<List<Marker>> _getNearbyHospitals(LatLng currentPosition) async {
    const apiKey = 'AIzaSyDqh1G3nYw3tAUG1BWpDhD0BBMT7vxTSho';
    const radius = 5000; // The search radius in meters
    final location =
        '${currentPosition.latitude},${currentPosition.longitude}'; // The user's current location
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$location&radius=$radius&type=hospital&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final hospitals = List<Map<String, dynamic>>.from(data['results']);
        return hospitals
            .map((hospital) => Marker(
                  markerId: MarkerId(hospital['place_id']),
                  position: LatLng(hospital['geometry']['location']['lat'],
                      hospital['geometry']['location']['lng']),
                  infoWindow: InfoWindow(
                    title: hospital['name'],
                    snippet: 'Hospital',
                    onTap: () => ApiClient.postHospital(hospital),
                  ),
                ))
            .toList();
      } else {
        throw Exception('Error: ${data['error_message']}');
      }
    } else {
      throw Exception('Error: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('BetterHealth'),
        ),
        body: FutureBuilder<LatLng>(
          future: _getCurrentLocation(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) =>
                        setState(() => _controller = controller),
                    initialCameraPosition: CameraPosition(
                      target: snapshot.data!,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('Current Location'),
                        position: snapshot.data!,
                        infoWindow: const InfoWindow(title: 'You are here'),
                      ),
                      ..._markers,
                    },
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
                      },
                      child: const Icon(Icons.my_location),
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
