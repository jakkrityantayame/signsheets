import 'package:gsheets/gsheets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:intl/intl.dart';

class GoogleSheetsService {
  static const _spreadsheetId = '1_Uz5B5GVlUmb-gNZBZiwVtMl5H3pV3mmgDoaRFbw43E';

  Future<GSheets> _initGSheets() async {
    try {
      final String credentialsJson = await rootBundle.loadString('assets/signatureapp-456405-2bb5a8080222.json');
      final credentials = jsonDecode(credentialsJson);
      return GSheets(credentials);
    } catch (e) {
      throw Exception("ไม่สามารถโหลดไฟล์ JSON: $e");
    }
  }

  Future<void> saveData(List<String> data) async {
    try {
      final gsheets = await _initGSheets();
      final sheet = await gsheets.spreadsheet(_spreadsheetId);
      if (sheet == null) {
        throw Exception("ไม่พบ Spreadsheet: $_spreadsheetId");
      }
      final worksheet = sheet.worksheetByTitle('Sheet1') ?? await sheet.addWorksheet('Sheet1');

      final firstRow = await worksheet.values.row(1);
      if (firstRow == null || firstRow.isEmpty) {
        await worksheet.values.insertRow(1, [
          'เลขที่',
          'วันที่ออก',
          'วันที่รับ',
          'ส่งจาก',
          'ส่งถึง',
          'เรื่อง',
          'ลายเซ็น',
          'ไฟล์แนบ',
          'ประเภท',
        ]);
      }

      final allRows = await worksheet.values.allRows();
      final nextRow = allRows.length + 1;
      // ตรวจสอบให้แน่ใจว่า data มีความยาวครบ 9 คอลัมน์
      while (data.length < 9) {
        data.add('');
      }
      await worksheet.values.insertRow(nextRow, data);
    } catch (e) {
      throw Exception("ไม่สามารถบันทึกข้อมูล: $e");
    }
  }

  Future<List<List<String>>> getData() async {
    try {
      final gsheets = await _initGSheets();
      final sheet = await gsheets.spreadsheet(_spreadsheetId);
      if (sheet == null) {
        throw Exception("ไม่พบ Spreadsheet: $_spreadsheetId");
      }
      final worksheet = sheet.worksheetByTitle('Sheet1');
      if (worksheet == null) {
        return [];
      }
      final rows = await worksheet.values.allRows(fromColumn: 1, length: 9); // ดึงคอลัมน์ A:I
      if (rows == null || rows.isEmpty) return [];
      return rows.length > 1 ? rows.sublist(1) : [];
    } catch (e) {
      throw Exception("ไม่สามารถดึงข้อมูล: $e");
    }
  }

  Future<void> deleteData(int rowIndex) async {
    try {
      final gsheets = await _initGSheets();
      final sheet = await gsheets.spreadsheet(_spreadsheetId);
      if (sheet == null) {
        throw Exception("ไม่พบ Spreadsheet: $_spreadsheetId");
      }
      final worksheet = sheet.worksheetByTitle('Sheet1');
      if (worksheet == null) {
        throw Exception("ไม่พบ Sheet1");
      }
      await worksheet.deleteRow(rowIndex + 2);
    } catch (e) {
      throw Exception("ไม่สามารถลบข้อมูล: $e");
    }
  }

  Future<void> updateData(int rowIndex, List<String> updatedData) async {
    try {
      final gsheets = await _initGSheets();
      final sheet = await gsheets.spreadsheet(_spreadsheetId);
      if (sheet == null) {
        throw Exception("ไม่พบ Spreadsheet: $_spreadsheetId");
      }
      final worksheet = sheet.worksheetByTitle('Sheet1');
      if (worksheet == null) {
        throw Exception("ไม่พบ Sheet1");
      }
      // ตรวจสอบให้แน่ใจว่า updatedData มีความยาวครบ 9 คอลัมน์
      while (updatedData.length < 9) {
        updatedData.add('');
      }
      await worksheet.values.insertRow(rowIndex + 2, updatedData);
    } catch (e) {
      throw Exception("ไม่สามารถอัปเดตข้อมูล: $e");
    }
  }

  Future<void> updateDates() async {
    try {
      final gsheets = await _initGSheets();
      final sheet = await gsheets.spreadsheet(_spreadsheetId);
      if (sheet == null) {
        throw Exception("ไม่พบ Spreadsheet: $_spreadsheetId");
      }
      final worksheet = sheet.worksheetByTitle('Sheet1');
      if (worksheet == null) {
        return;
      }

      final rows = await worksheet.values.allRows(fromColumn: 1, length: 9);
      if (rows == null || rows.length <= 1) return;

      final dataRows = rows.sublist(1);
      const outputFormat = 'dd/MM/';
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        bool updated = false;

        // ตรวจสอบให้แน่ใจว่า row มีความยาวครบ 9 คอลัมน์
        while (row.length < 9) {
          row.add('');
        }

        // อัปเดตวันที่ออก (คอลัมน์ 2)
        if (RegExp(r'^\d+(\.\d+)?$').hasMatch(row[1])) {
          try {
            final serialNumber = double.parse(row[1]);
            final baseDate = DateTime(1899, 12, 31);
            final adjustedDays = serialNumber > 60 ? serialNumber - 1 : serialNumber;
            final parsedDate = baseDate.add(Duration(days: adjustedDays.toInt()));
            row[1] = DateFormat(outputFormat).format(parsedDate) + parsedDate.year.toString();
            print("Row ${i + 2} - Date Issued (Serial): ${serialNumber} -> ${row[1]}");
            updated = true;
          } catch (e) {
            print("Row ${i + 2} - Failed to parse Date Issued (Serial): ${row[1]}");
            continue;
          }
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(row[1])) {
          final parsedDate = DateFormat('yyyy-MM-dd').parse(row[1]);
          row[1] = DateFormat(outputFormat).format(parsedDate) + parsedDate.year.toString();
          print("Row ${i + 2} - Date Issued (yyyy-MM-dd): ${parsedDate} -> ${row[1]}");
          updated = true;
        } else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(row[1])) {
          final parsedDate = DateFormat('dd/MM/yyyy').parse(row[1]);
          int christianYear;
          if (parsedDate.year >= 2500) {
            christianYear = parsedDate.year - 543;
            updated = true;
          } else {
            christianYear = parsedDate.year;
          }
          row[1] = DateFormat(outputFormat).format(parsedDate) + christianYear.toString();
          print("Row ${i + 2} - Date Issued (dd/MM/yyyy): ${parsedDate} -> ${row[1]}");
        }

        // อัปเดตวันที่รับ (คอลัมน์ 3)
        if (RegExp(r'^\d+(\.\d+)?$').hasMatch(row[2])) {
          try {
            final serialNumber = double.parse(row[2]);
            final baseDate = DateTime(1899, 12, 31);
            final adjustedDays = serialNumber > 60 ? serialNumber - 1 : serialNumber;
            final parsedDate = baseDate.add(Duration(days: adjustedDays.toInt()));
            row[2] = DateFormat(outputFormat).format(parsedDate) + parsedDate.year.toString();
            print("Row ${i + 2} - Date Received (Serial): ${serialNumber} -> ${row[2]}");
            updated = true;
          } catch (e) {
            print("Row ${i + 2} - Failed to parse Date Received (Serial): ${row[2]}");
            continue;
          }
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(row[2])) {
          final parsedDate = DateFormat('yyyy-MM-dd').parse(row[2]);
          row[2] = DateFormat(outputFormat).format(parsedDate) + parsedDate.year.toString();
          print("Row ${i + 2} - Date Received (yyyy-MM-dd): ${parsedDate} -> ${row[2]}");
          updated = true;
        } else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(row[2])) {
          final parsedDate = DateFormat('dd/MM/yyyy').parse(row[2]);
          int christianYear;
          if (parsedDate.year >= 2500) {
            christianYear = parsedDate.year - 543;
            updated = true;
          } else {
            christianYear = parsedDate.year;
          }
          row[2] = DateFormat(outputFormat).format(parsedDate) + christianYear.toString();
          print("Row ${i + 2} - Date Received (dd/MM/yyyy): ${parsedDate} -> ${row[2]}");
        }

        // อัปเดตแถวใน Google Sheets เฉพาะเมื่อมีการเปลี่ยนแปลง
        if (updated) {
          await worksheet.values.insertRow(i + 2, row);
          print("Row ${i + 2} - Updated in Google Sheets");
        }
      }
    } catch (e) {
      throw Exception("ไม่สามารถอัปเดตวันที่: $e");
    }
  }
}