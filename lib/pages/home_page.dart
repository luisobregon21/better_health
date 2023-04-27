// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    _currentLocation = _getCurrentLocation().then((location) {
      _updateMarkers();
      return location;
    });
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

  Future<List<Marker>> _getNearbyHospitals(LatLng currentPosition) async {
    final apiKey =
        'AIzaSyDqh1G3nYw3tAUG1BWpDhD0BBMT7vxTSho'; // Replace with your Google Places API key
    final radius = 5000; // The search radius in meters
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
                  infoWindow:
                      InfoWindow(title: hospital['name'], snippet: 'Hospital'),
                ))
            .toList();
      } else {
        throw Exception('Error: ${data['error_message']}');
      }
    } else {
      throw Exception('Error: ${response.reasonPhrase}');
    }
  }

  Future<void> _updateMarkers() async {
    final nearbyHospitals = await _getNearbyHospitals(await _currentLocation);
    final updatedMarkers = nearbyHospitals.toSet();
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
                      ),
                      ..._markers,
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
