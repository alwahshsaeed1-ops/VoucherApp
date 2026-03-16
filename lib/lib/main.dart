import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(MaterialApp(home: VoucherMakerApp(), debugShowCheckedModeBanner: false));

class VoucherMakerApp extends StatefulWidget {
  @override
  _VoucherMakerAppState createState() => _VoucherMakerAppState();
}

class _VoucherMakerAppState extends State<VoucherMakerApp> {
  final TextEditingController _netNameController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  File? _backgroundImage;

  // دالة لاختيار صورة التصميم من الهاتف
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _backgroundImage = File(pickedFile.path));
  }

  // دالة توليد الـ PDF بتنسيق 40 كرت في صفحة A4
  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final String prefix = _prefixController.text;
    final int start = int.parse(_startController.text);
    final int end = int.parse(_endController.text);
    final String netName = _netNameController.text;

    List<String> vouchers = [];
    for (int i = start; i <= end; i++) {
      vouchers.add(prefix + i.toString().padLeft(6, '0'));
    }

    final image = _backgroundImage != null ? pw.MemoryImage(_backgroundImage!.readAsBytesSync()) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return [
            pw.GridView(
              crossAxisCount: 5, // 5 كروت عرضاً
              childAspectRatio: 0.75,
              children: vouchers.map((code) {
                return pw.Container(
                  margin: pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    image: image != null ? pw.DecorationImage(image: image, fit: pw.BoxFit.cover) : null,
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(netName, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text("ID/Pass:", style: pw.TextStyle(fontSize: 6)),
                      pw.Text(code, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: "http://192.168.88.1/login?username=$code&password=$code",
                        width: 25, height: 25,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("صانع كروت شبكة فليكرز")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _netNameController, decoration: InputDecoration(labelText: "اسم الشبكة")),
            TextField(controller: _prefixController, decoration: InputDecoration(labelText: "أول 3 أرقام (البادئة)")),
            TextField(controller: _startController, decoration: InputDecoration(labelText: "رقم البداية")),
            TextField(controller: _endController, decoration: InputDecoration(labelText: "رقم النهاية")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _pickImage, child: Text("إدراج صورة تصميم الكرت")),
            if (_backgroundImage != null) Text("تم اختيار الصورة بنجاح"),
            SizedBox(height: 30),
            ElevatedButton(onPressed: _generatePDF, child: Text("توليد ملف PDF للطباعة"), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50))),
          ],
        ),
      ),
    );
  }
}
