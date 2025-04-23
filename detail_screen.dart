import 'package:flutter/material.dart';
import 'package:signsheets/services/google_sheets_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class DetailScreen extends StatefulWidget {
  final List<String> data;
  final int rowIndex;
  final VoidCallback onUpdate;

  const DetailScreen({
    Key? key,
    required this.data,
    required this.rowIndex,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isEditing = false;
  late List<TextEditingController> _controllers;
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  String? _errorMessage;
  String? _selectedFrom;
  String? _selectedTo;
  String? _customFrom;
  String? _customTo;
  final List<String> _options = [
    'คณะบริหารธุรกิจ',
    'สำนักประกันฯ',
    'คณะวิศวกรรมฯ',
    'บัณฑิตวิทยาลัย',
    'สำนักวางแผนฯ',
    'การเงิน',
    'สำนักกองทุน',
    'แนะแนว',
    'ศูนย์คอมฯ',
    'สำนักวิจัยฯ',
    'สำนักศึกษาทั่วไป',
    'สำนักกิจการฯ',
    'ห้องสมุด',
    'สำนักอธิการบดี',
    'สำนักวิชาการ',
    'สำนักทะเบียน',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      8,
          (index) {
        String text = index < widget.data.length ? widget.data[index] : '';
        // แปลงวันที่จาก serial number เป็นรูปแบบวันที่
        if (index == 1 || index == 2) {
          text = convertSerialToDate(text);
        }
        return TextEditingController(text: text);
      },
    );
    _selectedFrom = _options.contains(widget.data[3]) ? widget.data[3] : 'อื่นๆ';
    _selectedTo = _options.contains(widget.data[4]) ? widget.data[4] : 'อื่นๆ';
    _customFrom = _selectedFrom == 'อื่นๆ' ? widget.data[3] : null;
    _customTo = _selectedTo == 'อื่นๆ' ? widget.data[4] : null;
  }

  // ฟังก์ชันแปลง serial number เป็นวันที่ (dd/MM/yyyy)
  String convertSerialToDate(String serial) {
    try {
      int serialNumber = int.parse(serial);
      // Google Sheets เริ่มนับวันที่จาก 30/12/1899
      final baseDate = DateTime(1899, 12, 30);
      // เพิ่มจำนวนวันตาม serial number
      final date = baseDate.add(Duration(days: serialNumber));
      // ฟอร์แมตวันที่เป็น dd/MM/yyyy
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return serial; // คืนค่าเดิมถ้าแปลงไม่ได้
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        final formattedDate = DateFormat('dd/MM/').format(picked) + picked.year.toString();
        _controllers[index].text = formattedDate;
      });
    }
  }

  Future<void> _saveData() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      final updatedData = [
        _controllers[0].text,
        _controllers[1].text,
        _controllers[2].text,
        _selectedFrom == 'อื่นๆ' ? (_customFrom ?? '') : _selectedFrom!,
        _selectedTo == 'อื่นๆ' ? (_customTo ?? '') : _selectedTo!,
        _controllers[5].text,
        widget.data[6],
        widget.data.length > 7 ? widget.data[7] : '',
      ];
      await _sheetsService.updateData(widget.rowIndex, updatedData);
      widget.onUpdate();
      setState(() {
        _isEditing = false;
        _controllers[3].text = updatedData[3];
        _controllers[4].text = updatedData[4];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("บันทึกข้อมูลเรียบร้อยแล้ว")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "ไม่สามารถบันทึกข้อมูล: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดข้อมูล"),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveData,
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailItem("รหัส :", 0),
                  _buildDetailItem("วันที่ออกเอกสาร :", 1, isDate: true),
                  _buildDetailItem("วันที่รับเอกสาร :", 2, isDate: true),
                  _buildFromField(),
                  _buildToField(),
                  _buildDetailItem("เรื่อง :", 5),
                  _buildDetailItem("ลายเซ็น :", 6, isSignature: true, isEditable: false),
                  _buildDetailItem("ไฟล์แนบ :", 7, isEditable: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, int index, {bool isDate = false, bool isSignature = false, bool isEditable = true}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!isSignature && !isDate && _isEditing && isEditable)
                  Expanded(
                    child: TextFormField(
                      controller: _controllers[index],
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: label,
                      ),
                    ),
                  ),
                if (!isSignature && !isDate && (!_isEditing || !isEditable))
                  Expanded(
                    child: Text(
                      _controllers[index].text.isEmpty ? '-' : _controllers[index].text,
                      textAlign: TextAlign.end,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                if (isDate && _isEditing)
                  Expanded(
                    child: TextFormField(
                      controller: _controllers[index],
                      readOnly: true,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: label,
                      ),
                      onTap: () => _selectDate(context, index),
                    ),
                  ),
                if (isDate && !_isEditing)
                  Expanded(
                    child: Text(
                      _controllers[index].text.isEmpty ? '-' : _controllers[index].text,
                      textAlign: TextAlign.end,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
            if (isSignature && _controllers[index].text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.memory(
                  base64Decode(_controllers[index].text),
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      'ไม่สามารถแสดงลายเซ็น',
                      style: TextStyle(color: Colors.red),
                    );
                  },
                ),
              ),
            if (isSignature && _controllers[index].text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '-',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFromField() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ส่งจาก",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: _isEditing
                      ? DropdownButtonFormField<String>(
                    value: _selectedFrom,
                    items: _options.map((String option) {
                      return DropdownMenuItem(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFrom = value;
                        if (value != 'อื่นๆ') _customFrom = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  )
                      : Text(
                    _controllers[3].text.isEmpty ? '-' : _controllers[3].text,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (_isEditing && _selectedFrom == 'อื่นๆ')
              TextFormField(
                initialValue: _customFrom,
                decoration: InputDecoration(
                  labelText: "ระบุส่งจาก",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _customFrom = value;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToField() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ส่งถึง",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: _isEditing
                      ? DropdownButtonFormField<String>(
                    value: _selectedTo,
                    items: _options.map((String option) {
                      return DropdownMenuItem(value: option, child: Text(option));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTo = value;
                        if (value != 'อื่นๆ') _customTo = null;
                      });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  )
                      : Text(
                    _controllers[4].text.isEmpty ? '-' : _controllers[4].text,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            if (_isEditing && _selectedTo == 'อื่นๆ')
              TextFormField(
                initialValue: _customTo,
                decoration: InputDecoration(
                  labelText: "ระบุส่งถึง",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _customTo = value;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}