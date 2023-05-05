import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:better_health/api/api_client.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _controller;
  final panelController = PanelController();
  final Set<Marker> _markers = {};
  late Map<String, dynamic> hospData = {};
  bool _markerTapped = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getCurrentLocation().then((location) => _getNearbyHospitals(location)
        .then((hospitals) => setState(() => _markers.addAll(hospitals))));
  }

  Future<void> _requestLocationPermission() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isDenied) {
      print("Permission denied!");
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return LatLng(position.latitude, position.longitude);
  }

  Future<List<Marker>> _getNearbyHospitals(LatLng currentPosition) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'];
    const radius = 5000; // The search radius in meters
    final location = '${currentPosition.latitude},${currentPosition.longitude}';
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
                  onTap: () => _onMarkerTapped(hospital),
                ))
            .toList();
      } else {
        throw Exception('Error: ${data['error_message']}');
      }
    } else {
      throw Exception('Error: ${response.reasonPhrase}');
    }
  }

  void _onMarkerTapped(Map<String, dynamic> hospital) async {
    final classifiedReviews = await ApiClient.postHospital(hospital);

    setState(() {
      hospData = {
        'hospital': hospital,
        'classifiedReviews': classifiedReviews,
      };
      _markerTapped = true;
    });
    print(hospData['classifiedReviews']);
  }

  @override
  Widget build(BuildContext context) {
    final panelHeightClosed = MediaQuery.of(context).size.height * .18;
    final panelHeightOpen = MediaQuery.of(context).size.height * .8;

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
                  SlidingUpPanel(
                    controller: panelController,
                    minHeight: _markerTapped ? panelHeightClosed : 0,
                    maxHeight: panelHeightOpen,
                    panelBuilder: (controller) => PanelWidget(
                        hospData: hospData,
                        controller: controller,
                        panelController: panelController),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                    body: GoogleMap(
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
                      onTap: (position) => panelController.close(),
                    ),
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

class PanelWidget extends StatelessWidget {
  final ScrollController controller;
  final PanelController panelController;
  final Map<String, dynamic> hospData;

  const PanelWidget({
    Key? key,
    required this.controller,
    required this.panelController,
    required this.hospData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.zero,
        controller: controller,
        children: <Widget>[
          SizedBox(height: 12),
          buidDragHandle(),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: hospData.containsKey('hospital')
                    ? NetworkImage(hospData['hospital']['icon'])
                    : null,
              ),
              SizedBox(
                width: 16,
              ),
              Expanded(
                child: Text(
                  hospData.containsKey('hospital')
                      ? hospData['hospital']['name']
                      : '',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          SizedBox(height: 16),
          Text(
            "Overall Review:",
            style: TextStyle(fontSize: 18),
          ),
          Container(
            height: 25.0,
            width: 100.0,
            decoration: BoxDecoration(
                color: hospData.containsKey('classifiedReviews')
                    ? hospData['classifiedReviews']['overall'] == 'positive'
                        ? Colors.green
                            .withOpacity(hospData['classifiedReviews']['score'])
                        : hospData['classifiedReviews']['overall'] == 'negative'
                            ? Colors.red.withOpacity(
                                hospData['classifiedReviews']['score'])
                            : Colors.grey.withOpacity(
                                hospData['classifiedReviews']['score'])
                    : Colors.white,
                borderRadius: BorderRadius.circular(10.0)),
            child: Center(
              child: Text(
                hospData.containsKey('classifiedReviews')
                    ? hospData['classifiedReviews']['overall']
                    : '',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Reviews:",
            style: TextStyle(fontSize: 18),
          ),
          KeywordsList(
            keywords: hospData.containsKey('classifiedReviews')
                ? hospData['classifiedReviews']['keywords']
                : [],
          ),
        ],
      );

  Widget buidDragHandle() => GestureDetector(
        onTap: togglePanel,
        child: Center(
          child: Container(
            width: 30,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  void togglePanel() => panelController.isPanelOpen
      ? panelController.close()
      : panelController.open();
}

class KeywordsList extends StatelessWidget {
  final List<dynamic> keywords;
  const KeywordsList({Key? key, required this.keywords}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
        children: keywords
            .map((keyword) => SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 15,
                  child: Container(
                    margin: EdgeInsets.only(right: 10, bottom: 10),
                    width: 100,
                    height: 25,
                    decoration: BoxDecoration(
                        color: keyword['overall'] == 'positive'
                            ? Colors.green
                                .withOpacity(keyword['score'] as double)
                            : keyword['overall'] == 'negative'
                                ? Colors.red
                                    .withOpacity(keyword['score'] as double)
                                : Colors.grey
                                    .withOpacity(keyword['score'] as double),
                        borderRadius: BorderRadius.circular(10.0)),
                    child: Center(
                      child: Text(
                        keyword['tag'],
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ))
            .toList());
  }
}
