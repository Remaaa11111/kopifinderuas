import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'review_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class DetailScreen extends StatefulWidget {
  final String kedaiId;

  DetailScreen({required this.kedaiId});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Future<void> openUrl(BuildContext context, String url) async {
    print('DEBUG URL: $url');
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  Future<void> tambahUlasan(
    String kedaiId,
    double _rating,
    TextEditingController _ulasanController,
  ) async {
    await FirebaseFirestore.instance.collection('ulasan').add({
      'id_kedai': kedaiId,
      'user_email': FirebaseAuth.instance.currentUser?.email,
      'komentar': _ulasanController.text,
      'rating': _rating,
      'tanggal': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteUlasan(String docId) async {
    await FirebaseFirestore.instance.collection('ulasan').doc(docId).delete();
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    String currentKomentar, {
    double? currentRating,
    String? currentFotoUrl,
  }) {
    final TextEditingController _editController = TextEditingController(
      text: currentKomentar,
    );
    double _editRating = currentRating ?? 0;
    String? _editFotoUrl = currentFotoUrl;
    File? _selectedImage;

    Future<void> _pickImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _selectedImage = File(picked.path);
        // Upload ke Imgur
        final url = await uploadToImgur(_selectedImage!);
        if (url != null) {
          _editFotoUrl = url;
        }
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Edit Komentar'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _editController,
                          decoration: InputDecoration(labelText: 'Komentar'),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                index < _editRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                setState(() {
                                  _editRating = (index + 1).toDouble();
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_editFotoUrl != null && _editFotoUrl!.isNotEmpty)
                          Image.network(_editFotoUrl!, height: 80),
                        TextButton.icon(
                          icon: Icon(Icons.photo),
                          label: Text('Ganti Foto'),
                          onPressed: () async {
                            await _pickImage();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('ulasan')
                            .doc(docId)
                            .update({
                              'komentar': _editController.text,
                              'rating': _editRating,
                              'foto_url': _editFotoUrl ?? '',
                              'tanggal': FieldValue.serverTimestamp(),
                            });
                        Navigator.pop(context);
                      },
                      child: Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<String?> uploadToImgur(File imageFile) async {
    final clientId = 'c3f7650c7913123'; // Ganti dengan Client ID Anda
    final url = Uri.parse('https://api.imgur.com/3/image');
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      url,
      headers: {'Authorization': 'Client-ID $clientId'},
      body: {'image': base64Image, 'type': 'base64'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['link'];
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG kedaiId: ${widget.kedaiId}");

    if (widget.kedaiId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Detail Kedai')),
        body: Center(child: Text('ID Kedai tidak valid.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Detail Kedai')),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('kedaikopi')
                .doc(widget.kedaiId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: Text('Data tidak ditemukan.'));

          final kedai = snapshot.data!;
          final rating = double.tryParse(kedai['rating'].toString()) ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (kedai['foto'] != null && kedai['foto'] != '')
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    kedai['foto'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      kedai['nama'] ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        rating.round(),
                        (i) => Icon(Icons.star, color: Colors.orange, size: 20),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '(${kedai['rating'] ?? '-'})',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.brown),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      kedai['alamat'] ?? '',
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 18, color: Colors.green[700]),
                  SizedBox(width: 4),
                  Text(
                    kedai['harga'] ?? '',
                    style: TextStyle(fontSize: 15, color: Colors.green[700]),
                  ),
                ],
              ),
              if (kedai['gmaps'] != null && kedai['gmaps'] != '')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url =
                          kedai['gmaps'].toString().startsWith('http')
                              ? kedai['gmaps']
                              : 'https://${kedai['gmaps']}';
                      openUrl(context, url);
                    },
                    icon: Icon(Icons.map),
                    label: Text("Lihat di Google Maps"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(kedaiId: widget.kedaiId),
                    ),
                  );
                },
                icon: Icon(Icons.rate_review),
                label: Text('Tulis Ulasan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Ulasan Pengunjung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('ulasan')
                        .where('id_kedai', isEqualTo: widget.kedaiId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Belum ada ulasan. Jadilah yang pertama!'),
                    );
                  }

                  final ulasanDocs = snapshot.data!.docs.toList();

                  return Column(
                    children:
                        ulasanDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final ulasanRating =
                              ((data['rating'] ?? 0).clamp(0, 5)).toInt();

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  ...List.generate(
                                    ulasanRating,
                                    (i) => Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['user_email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['komentar'] ?? '',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    if (data['foto_url'] != null &&
                                        data['foto_url'] != '')
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            data['foto_url'],
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                height: 120,
                                                color: Colors.grey[300],
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 32,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    if (data['tanggal'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          DateFormat('dd MMM yyyy').format(
                                            (data['tanggal'] as Timestamp)
                                                .toDate(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'Baru saja',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              trailing:
                                  (FirebaseAuth.instance.currentUser?.email ==
                                          data['user_email'])
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ReviewScreen(
                                                        kedaiId: widget.kedaiId,
                                                        ulasanId: doc.id,
                                                        initialKomentar:
                                                            data['komentar'],
                                                        initialRating:
                                                            (data['rating'] ??
                                                                    0)
                                                                .toDouble(),
                                                        initialFotoUrl:
                                                            data['foto_url'],
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              _deleteUlasan(doc.id);
                                            },
                                          ),
                                        ],
                                      )
                                      : null,
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
