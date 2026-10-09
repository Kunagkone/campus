import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const String _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await GeminiVisionService()
          .analyzeProductImage(_selectedImage!, _prompt);

      setState(() {
        _titleController.text = result.title;
        _categoryController.text = result.category;
        _descriptionController.text = result.description;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศขายสินค้า')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200, fit: BoxFit.cover)
                : Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_selectedImage == null || _isLoading)
                  ? null
                  : _analyzeImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
                ],
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const Divider(height: 32),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อประกาศ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'คำบรรยายสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}