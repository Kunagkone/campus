import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';
import '../repositories/item_repository_firestore.dart';
import '../services/storage_service.dart';
import '../services/gemini_vision_service.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _uploadStatusText;
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
  void initState() {
    super.initState();
    _loadSavedDraft();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 1. โหลดร่างประกาศที่เคยบันทึกไว้ใน SQLite
  Future<void> _loadSavedDraft() async {
    final draft = await widget.draftRepository.getDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
        if (draft.imagePath != null && draft.imagePath!.isNotEmpty) {
          final file = File(draft.imagePath!);
          if (file.existsSync()) {
            _selectedImage = file;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหลดร่างประกาศล่าสุดจากฐานข้อมูลสำเร็จ')),
      );
    }
  }

  // 2. บันทึกร่างประกาศลง SQLite
  Future<void> _saveDraft() async {
    final draft = ListingDraft(
      title: _titleController.text,
      category: _categoryController.text,
      description: _descriptionController.text,
      imagePath: _selectedImage?.path,
    );
    await widget.draftRepository.saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกร่างประกาศลงฐานข้อมูลแล้ว')),
      );
    }
  }

  // 3. ลบร่างประกาศออกจาก SQLite และล้างฟอร์ม
  Future<void> _clearDraft() async {
    await widget.draftRepository.deleteDraft();
    setState(() {
      _selectedImage = null;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
      _errorMessage = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบร่างประกาศเรียบร้อยแล้ว')),
      );
    }
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

  // 4. โพสต์ขายจริง (Upload to Storage & Save to Firestore)
  Future<void> _postToFirestore() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อประกาศก่อนโพสต์ขาย')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าก่อนโพสต์ขาย')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำการโพสต์ขายสินค้า')),
      );
      return;
    }

    // ถามราคาผ่าน Dialog
    final priceController = TextEditingController();
    final price = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('กำหนดราคาสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ระบุราคาสินค้าที่ต้องการขาย (บาท):'),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ราคา (บาท)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(priceController.text.trim());
              if (val == null || val <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุราคาเป็นตัวเลขที่มากกว่า 0')),
                );
                return;
              }
              Navigator.pop(ctx, val);
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (price == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatusText = 'กำลังอัปโหลดรูปภาพขึ้น Firebase Storage...';
      _errorMessage = null;
    });

    try {
      // 1. อัปโหลดรูปขึ้น Storage
      final storageService = StorageService();
      final imageUrl = await storageService.uploadListingImage(
        _selectedImage!,
        user.uid,
      );

      setState(() {
        _uploadStatusText = 'กำลังบันทึกข้อมูลสินค้าลง Cloud Firestore...';
      });

      // 2. สร้าง Item และบันทึกลง Firestore
      final newItem = Item(
        id: 0,
        title: title,
        price: price,
        description: description,
        category: category.isEmpty ? 'ทั่วไป' : category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );

      await ItemRepositoryFirestore().postItem(newItem);

      // 3. ลบร่างออกจาก Local Database (SQLite)
      await widget.draftRepository.deleteDraft();

      setState(() {
        _selectedImage = null;
        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('🎉 โพสต์ขายสินค้าลงระบบเรียบร้อยแล้ว! ร่างเดิมถูกลบแล้ว'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('เกิดข้อผิดพลาดในการโพสต์: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'ลบร่าง',
            onPressed: _isUploading ? null : _clearDraft,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'บันทึกร่าง',
            onPressed: _isUploading ? null : _saveDraft,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                  )
                : Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_selectedImage == null || _isLoading || _isUploading)
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
            if (_isUploading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      _uploadStatusText ?? 'กำลังดำเนินการ...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const Divider(height: 32),
            TextField(
              controller: _titleController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                labelText: 'ชื่อประกาศ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_isUploading,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'คำบรรยายสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploading ? null : _saveDraft,
                    icon: const Icon(Icons.save),
                    label: const Text('บันทึกเป็นร่าง'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _postToFirestore,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('โพสต์ขายจริง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
