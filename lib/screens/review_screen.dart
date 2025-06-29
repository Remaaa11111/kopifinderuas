import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewScreen extends StatefulWidget {
  final String kedaiId;
  final String? ulasanId;
  final String? initialKomentar;
  final double? initialRating;
  final String? initialFotoUrl;

  ReviewScreen({
    required this.kedaiId,
    this.ulasanId,
    this.initialKomentar,
    this.initialRating,
    this.initialFotoUrl,
  });

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final komentarController = TextEditingController();
  File? _image;
  double _rating = 3;
  final picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    komentarController.text = widget.initialKomentar ?? '';
    _rating = (widget.initialRating ?? 3.0).clamp(1.0, 5.0);
  }

  Future<String?> uploadToImgur(File imageFile) async {
    final clientId = 'c3f7650c7913123'; // Client ID Imgur
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

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Ambil dari Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() {
          _image = File(picked.path);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitReview() async {
    if (komentarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Komentar tidak boleh kosong')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await uploadToImgur(_image!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload gambar ke Imgur')),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else if (widget.initialFotoUrl != null &&
          widget.initialFotoUrl!.isNotEmpty) {
        imageUrl = widget.initialFotoUrl;
      } else {
        imageUrl = '';
      }

      if (widget.ulasanId != null) {
        await FirebaseFirestore.instance
            .collection('ulasan')
            .doc(widget.ulasanId)
            .update({
              'komentar': komentarController.text,
              'rating': _rating,
              'foto_url': imageUrl,
              'tanggal': FieldValue.serverTimestamp(),
            });
      } else {
        await FirebaseFirestore.instance.collection('ulasan').add({
          'id_kedai': widget.kedaiId,
          'user_email': FirebaseAuth.instance.currentUser!.email,
          'komentar': komentarController.text,
          'rating': _rating,
          'foto_url': imageUrl,
          'tanggal': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ulasan berhasil dikirim.')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim ulasan: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tulis Ulasan')),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: komentarController,
                    decoration: InputDecoration(
                      labelText: 'Komentar',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Text("Rating: ${_rating.toStringAsFixed(1)}"),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toString(),
                    onChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                  SizedBox(height: 16),
                  if (_image != null)
                    Container(
                      height: 150,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
                    )
                  else if (widget.initialFotoUrl != null &&
                      widget.initialFotoUrl!.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.initialFotoUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Pilih/Ganti Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      child: Text('Kirim Ulasan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
