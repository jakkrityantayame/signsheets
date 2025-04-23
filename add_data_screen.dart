import 'package:flutter/material.dart';
import 'package:signsheets/services/google_sheets_service.dart';
import 'package:intl/intl.dart';

class AddDataScreen extends StatefulWidget {
  final bool isSentDocument;

  const AddDataScreen({Key? key, required this.isSentDocument}) : super(key: key);

  @override
  _AddDataScreenState createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _receiveDateController = TextEditingController();
  final _subjectController = TextEditingController();
  String? _selectedFrom;
  String? _selectedTo;
  String? _customFrom;
  String? _customTo;
  String? _errorMessage;

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
    _selectedFrom = _options[0];
    _selectedTo = _options[0];
  }

  @override
  void dispose() {
    _idController.dispose();
    _issueDateController.dispose();
    _receiveDateController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        final formattedDate = DateFormat('dd/MM/').format(picked) + picked.year.toString();
        controller.text = formattedDate;
      });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });
      try {
        final newData = [
          _idController.text,
          widget.isSentDocument ? _issueDateController.text : '',
          widget.isSentDocument ? '' : _receiveDateController.text,
          _selectedFrom == 'อื่นๆ' ? (_customFrom ?? '') : _selectedFrom!,
          _selectedTo == 'อื่นๆ' ? (_customTo ?? '') : _selectedTo!,
          _subjectController.text,
          '', // ลายเซ็น (ยังไม่เพิ่มในตัวอย่างนี้)
          '', // ไฟล์แนบ (ยังไม่เพิ่มในตัวอย่างนี้)
          widget.isSentDocument ? 'ส่ง' : 'รับ', // ประเภท
        ];
        await _sheetsService.saveData(newData); // เปลี่ยนจาก addData เป็น saveData
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เพิ่มข้อมูลเรียบร้อยแล้ว")),
        );
      } catch (e) {
        setState(() {
          _errorMessage = "ไม่สามารถเพิ่มข้อมูล: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSentDocument ? "เพิ่มหนังสือส่ง" : "เพิ่มหนังสือรับ"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: "รหัส",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัส';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              if (widget.isSentDocument)
                TextFormField(
                  controller: _issueDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "วันที่ออกเอกสาร",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectDate(context, _issueDateController),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกวันที่ออกเอกสาร';
                    }
                    return null;
                  },
                ),
              if (!widget.isSentDocument)
                TextFormField(
                  controller: _receiveDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "วันที่รับเอกสาร",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectDate(context, _receiveDateController),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกวันที่รับเอกสาร';
                    }
                    return null;
                  },
                ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
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
                  labelText: "ส่งจาก",
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedFrom == 'อื่นๆ')
                TextFormField(
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
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
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
                  labelText: "ส่งถึง",
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedTo == 'อื่นๆ')
                TextFormField(
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
              SizedBox(height: 10),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: "เรื่อง",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเรื่อง';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                child: Text("บันทึก"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}