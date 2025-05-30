// services/invoice_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart'
    show rootBundle; // Để load font từ assets
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import './../models/orders.dart';
// import './format_currency.dart';

// Hàm format tiền tệ (ví dụ, bạn có thể dùng hàm formatCurrency đã có)
String _formatCurrency(double amount) {
  final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  return format.format(amount);
}

class InvoiceService {
  Future<Uint8List> generateInvoicePdf(Order order) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttfRegular = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttfBold = pw.Font.ttf(boldFontData);
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      print("✅ Font Roboto-Regular loaded: ${fontData.lengthInBytes} bytes");
    } catch (e) {
      print("❌ Error loading Roboto-Regular: $e");
    }

    // Dùng pw.ThemeData để áp dụng font mặc định cho toàn bộ tài liệu
    final baseTheme = pw.ThemeData.withFont(
      base: ttfRegular, // Chỉ dùng font regular
      // bold: ttfBold, // Tạm thời comment dòng này
    );

    // Thông tin nhà hàng/cửa hàng (Bạn có thể lấy từ config hoặc hardcode)
    const String storeName = "COFFEE SHOP";
    const String storeAddress = "180 Đường Cao Lỗ, Phường 4, Quận 8, TP. HCM";
    const String storePhone = "0123 456 789";
    // final Uint8List? logoBytes = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(); // Ví dụ load logo

    pdf.addPage(
      pw.Page(
        theme: baseTheme, // Áp dụng theme
        pageFormat: PdfPageFormat
            .a4, // Hoặc PdfPageFormat.roll80 (cho máy in bill khổ 80mm)
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header: Thông tin cửa hàng
              pw.Center(
                child: pw.Text(storeName,
                    style: pw.TextStyle(font: ttfBold, fontSize: 20)),
              ),
              // if (logoBytes != null) pw.Center(child: pw.Image(pw.MemoryImage(logoBytes), height: 50)),
              pw.SizedBox(height: 5),
              pw.Center(
                  child:
                      pw.Text(storeAddress, style: pw.TextStyle(fontSize: 10))),
              pw.Center(
                  child: pw.Text("ĐT: $storePhone",
                      style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 20),

              // 2. Tiêu đề hóa đơn
              pw.Center(
                child: pw.Text('HÓA ĐƠN THANH TOÁN',
                    style: pw.TextStyle(font: ttfBold, fontSize: 18)),
              ),
              pw.SizedBox(height: 10),

              // 3. Thông tin đơn hàng
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Mã ĐH: ${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}',
                        style: pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal())}',
                        style: pw.TextStyle(fontSize: 10)),
                  ]),
              if (order.tableNumber != null && order.tableNumber!.isNotEmpty)
                pw.Text('Bàn: ${order.tableNumber}',
                    style: pw.TextStyle(font: ttfBold, fontSize: 12)),
              pw.SizedBox(height: 15),

              // 4. Bảng chi tiết sản phẩm
              _buildProductsTable(order.products, ttfRegular, ttfBold),
              pw.SizedBox(height: 5),
              pw.Divider(),
              pw.SizedBox(height: 5),

              // 5. Tổng kết
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // _buildSummaryRow('Tạm tính:', _formatCurrency(order.total + (order.paymentInfo?.discountAmount ?? 0)), ttfRegular, ttfBold), // Cần tính subtotal đúng
                      // if (order.paymentInfo?.discountAmount != null && order.paymentInfo!.discountAmount! > 0)
                      //   _buildSummaryRow('Giảm giá (${order.paymentInfo?.voucherCode ?? ""}):', '-${_formatCurrency(order.paymentInfo!.discountAmount!)}', ttfRegular, ttfBold),
                      _buildSummaryRow('Tổng cộng:',
                          _formatCurrency(order.total), ttfRegular, ttfBold,
                          isTotal: true, fontSize: 14),
                    ],
                  )
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Phương thức: ${order.paymentMethod?.toUpperCase() ?? "N/A"}',
                        style: pw.TextStyle(fontSize: 10)),
                    pw.Text('Trạng thái: ${order.status.toUpperCase()}',
                        style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                  ]),

              pw.Spacer(), // Đẩy footer xuống dưới
              // 6. Footer
              pw.Divider(),
              pw.Center(
                child: pw.Text('Cảm ơn quý khách và hẹn gặp lại!',
                    style: pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save(); // Trả về dữ liệu PDF dưới dạng Uint8List
  }

  // Hàm tiện ích để xây dựng bảng sản phẩm
  static pw.Widget _buildProductsTable(
      List<OrderProduct> products, pw.Font regularFont, pw.Font boldFont) {
    final headers = ['#', 'Tên sản phẩm', 'SL', 'Đ.Giá', 'T.Tiền'];
    final data = products.asMap().entries.map((entry) {
      int idx = entry.key;
      OrderProduct item = entry.value;
      String itemName = item.product.name;
      List<String> notes = [];
      if (item.note.size.isNotEmpty) notes.add("Size: ${item.note.size}");
      if (item.note.sugarLevel.isNotEmpty)
        notes.add("Đường: ${item.note.sugarLevel.replaceAll(' SL', '%')}");
      if (item.note.toppings.isNotEmpty)
        notes.add("Topping: ${item.note.toppings.join(', ')}");
      // Thêm giá topping vào tổng giá sản phẩm (nếu cần)
      // Hoặc bạn có thể hiển thị giá topping như một dòng riêng hoặc cộng vào giá sản phẩm
      double itemTotal =
          item.price * item.quantity + (item.note.toppingPrice * item.quantity);

      return [
        (idx + 1).toString(),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(itemName, style: pw.TextStyle(font: boldFont, fontSize: 9)),
          if (notes.isNotEmpty)
            pw.Text(notes.join(" / "),
                style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        ]),
        item.quantity.toString(),
        _formatCurrency(item.price +
            item.note.toppingPrice), // Đơn giá đã bao gồm topping (nếu có)
        _formatCurrency(
            itemTotal), // Thành tiền (đã nhân số lượng và bao gồm topping)
      ];
    }).toList();

    return pw.Table.fromTextArray(
        headers: headers,
        data: data,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        headerStyle:
            pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
        cellHeight: 25,
        cellAlignments: {
          0: pw.Alignment.centerRight, // #
          1: pw.Alignment.centerLeft, // Tên SP
          2: pw.Alignment.center, // SL
          3: pw.Alignment.centerRight, // Đ.Giá
          4: pw.Alignment.centerRight, // T.Tiền
        },
        cellStyle: pw.TextStyle(fontSize: 8.5),
        columnWidths: {
          // Điều chỉnh độ rộng các cột
          0: const pw.FixedColumnWidth(20), // #
          1: const pw.FlexColumnWidth(3.5), // Tên SP
          2: const pw.FixedColumnWidth(25), // SL
          3: const pw.FlexColumnWidth(1.5), // Đ.Giá
          4: const pw.FlexColumnWidth(1.8), // T.Tiền
        });
  }

  // Hàm tiện ích để xây dựng các dòng trong phần tổng kết
  static pw.Widget _buildSummaryRow(
      String title, String value, pw.Font regularFont, pw.Font boldFont,
      {bool isTotal = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  font: isTotal ? boldFont : regularFont, fontSize: fontSize)),
          pw.SizedBox(width: 20), // Khoảng cách giữa title và value
          pw.Text(value,
              style: pw.TextStyle(
                  font: isTotal ? boldFont : regularFont, fontSize: fontSize)),
        ],
      ),
    );
  }
}
