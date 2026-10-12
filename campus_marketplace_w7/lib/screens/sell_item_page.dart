import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;

  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'อุปกรณ์การเรียน';
  String? _imagePath;

  final List<String> _categories = [
    'อุปกรณ์การเรียน',
    'เครื่องใช้ไฟฟ้า',
    'เสื้อผ้า/แฟชั่น',
    'หนังสือ',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedDraft();
  }

  // โหลดร่างประกาศที่เคยบันทึกไว้ใน SQLite เมื่อเปิดหน้า
  Future<void> _loadSavedDraft() async {
    final draft = await widget.draftRepository.getDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft.title;
        _descriptionController.text = draft.description;
        if (_categories.contains(draft.category)) {
          _selectedCategory = draft.category;
        }
        _imagePath = draft.imagePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหลดร่างประกาศล่าสุดสำเร็จ')),
      );
    }
  }

  // บันทึกร่างประกาศลง SQLite
  Future<void> _saveDraft() async {
    final draft = ListingDraft(
      title: _titleController.text,
      category: _selectedCategory,
      description: _descriptionController.text,
      imagePath: _imagePath,
    );
    await widget.draftRepository.saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกร่างประกาศลงฐานข้อมูลแล้ว')),
      );
    }
  }

  // ลบไฟล์ร่างประกาศ
  Future<void> _clearDraft() async {
    await widget.draftRepository.deleteDraft();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = _categories.first;
      _imagePath = null;
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
        _imagePath = pickedFile.path;
      });
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
            onPressed: _clearDraft,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'บันทึกร่าง',
            onPressed: _saveDraft,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _imagePath != null && _imagePath!.isNotEmpty
                    ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('แตะเพื่อเลือกรูปภาพสินค้า'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _saveDraft();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลงประกาศขายสินค้าเรียบร้อย')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ลงประกาศขาย', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}