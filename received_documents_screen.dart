import 'package:flutter/material.dart';
import 'package:signsheets/services/google_sheets_service.dart';
import 'package:signsheets/screens/add_data_screen.dart';
import 'package:signsheets/screens/detail_screen.dart';
import 'package:intl/intl.dart';

class ReceivedDocumentsScreen extends StatefulWidget {
  @override
  _ReceivedDocumentsScreenState createState() => _ReceivedDocumentsScreenState();
}

class _ReceivedDocumentsScreenState extends State<ReceivedDocumentsScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  List<List<String>> _data = [];
  List<List<String>> _filteredData = [];
  String _searchQuery = '';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _sheetsService.updateDates();
      final data = await _sheetsService.getData();
      // แปลงวันที่จาก serial number เป็นรูปแบบวันที่
      final convertedData = data.map((row) {
        return row.asMap().entries.map((entry) {
          int index = entry.key;
          String value = entry.value;
          if (index == 1 || index == 2) { // วันที่ออกและวันที่รับ
            return convertSerialToDate(value);
          }
          return value;
        }).toList();
      }).toList();
      // กรองเฉพาะเอกสารที่มีประเภทเป็น "รับ" (index 8)
      final receivedData = convertedData.where((row) => row.length > 8 && row[8] == 'รับ').toList();
      setState(() {
        _data = receivedData;
        _filteredData = receivedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
      return 'Invalid Date'; // คืนค่าเมื่อแปลงไม่ได้
    }
  }

  void _searchData(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredData = _data;
      } else {
        _filteredData = _data.where((row) => row[0].contains(query)).toList();
      }
    });
  }

  Future<void> _deleteData(int index) async {
    try {
      await _sheetsService.deleteData(index);
      await _fetchData();
    } catch (e) {
      setState(() {
        _errorMessage = "ไม่สามารถลบข้อมูล: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("หนังสือรับ"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "ค้นหาด้วยรหัส",
                border: OutlineInputBorder(),
              ),
              onChanged: _searchData,
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                ? Center(child: Text("ไม่มีหนังสือรับ"))
                : ListView.builder(
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                final row = _filteredData[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: Icon(Icons.receipt, color: Colors.green),
                    title: Text("รหัส: ${row[0]}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("เรื่อง: ${row[5]}"),
                        Text("วันที่รับเอกสาร: ${row[2]}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteData(index),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            data: row,
                            rowIndex: index,
                            onUpdate: _fetchData,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDataScreen(isSentDocument: false),
            ),
          ).then((_) => _fetchData());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}