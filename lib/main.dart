import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PBL Geo Tracker Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LocationEntry> locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final loadedLocations = await DatabaseHelper.instance.getAllLocations();
    setState(() {
      locations = loadedLocations;
    });
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
      }
      return 'Unknown location';
    } catch (e) {
      return 'Error getting address';
    }
  }

  Future<void> _getCurrentLocation() async {
    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      LocationEntry entry = LocationEntry(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        timestamp: DateTime.now(),
      );

      await DatabaseHelper.instance.insertLocation(entry);
      await _loadLocations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PBL Geo Tracker Prototype'),
      ),
      body: Column(
        children: [
          // Top half with the button
          Expanded(
            flex: 1,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.location_on),
                label: const Text(
                  'Log Location',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 2, thickness: 1),
          // Bottom half with the list
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                return ListTile(
                  title: Text(location.address),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(location.timestamp),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
