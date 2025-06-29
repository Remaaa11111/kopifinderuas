import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PetaKedaiScreen extends StatelessWidget {
  // Daftar kedai: nama + lat + long
  final List<Map<String, dynamic>> kedaiList = [
    {
      'nama': 'Kopi Kenangan',
      'lokasi': LatLng(-8.635739633036502, 115.21806965268469),
    },
    {
      'nama': 'Tomoro Coffee',
      'lokasi': LatLng(-8.679069453889976, 115.21492340665331),
    },
    {
      'nama': 'Janji Jiwa',
      'lokasi': LatLng(-8.648587835530703, 115.22003317715195),
    },
    {
      'nama': 'Tan Panama',
      'lokasi': LatLng(-8.653282323777894, 115.21688762199693),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Peta Kedai Kopi')),
      body: FlutterMap(
        options: MapOptions(
          center: kedaiList[0]['lokasi'], // 
          zoom: 14.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.rema.kopifinder',
          ),
          MarkerLayer(
            markers:
                kedaiList.map((kedai) {
                  return Marker(
                    width: 80,
                    height: 80,
                    point: kedai['lokasi'],
                    child: Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                        Container(
                          color: Colors.white,
                          child: Text(
                            kedai['nama'],
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
