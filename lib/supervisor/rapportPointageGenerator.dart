import 'dart:convert';
import 'dart:html';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

import '../model.dart';

class RapportPointage {
  static void printRepport(List<Map<String, dynamic>> pointages) async {
    final pdf = pw.Document();
    Map<String, dynamic> pointageSite = pointages.first;
    Supervisor superviseur = pointageSite['supervisor'];
    int nbSite = pointageSite['nbSite'];
    List<Map<String, dynamic>> pointing = pointageSite['Pointages'];

    pw.Widget header = pw.Row(children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        width: 60,
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Text("Superviseurs", style: const pw.TextStyle(fontSize: 6)),
      ),

      //pw.Text(nbSite.toString()),
      pw.Expanded(
          child: pw.Row(
              children: pointing.map((Map<String, dynamic> e) {
        DateTime date = e["date"];
        int nbPointage = e["nbPointage"];
        return pw.Container(
          padding: const pw.EdgeInsets.all(5),
          width: 30,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Text("${date.day}", style: const pw.TextStyle(fontSize: 5)),
        );
      }).toList()))
    ]);
    pw.Widget lisPointageWidget = pw.ListView.builder(
      itemCount: pointages.length,
      itemBuilder: (context, int index) {
        Map<String, dynamic> pointageSite = pointages[index];
        Supervisor superviseur = pointageSite['supervisor'];
        int nbSite = pointageSite['nbSite'];
        List<Map<String, dynamic>> pointing = pointageSite['Pointages'];

        return pw.Row(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            width: 60,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text("${superviseur.firstName} ${superviseur.lastName}",
                style: const pw.TextStyle(fontSize: 6)),
          ),

          //pw.Text(nbSite.toString()),
          pw.Expanded(
              child: pw.Row(
                  children: pointing.map((Map<String, dynamic> e) {
            DateTime date = e["date"];
            int nbPointage = e["nbPointage"];
            return pw.Container(
              padding: const pw.EdgeInsets.all(5),
              width: 30,
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Text("$nbPointage/$nbSite",
                  style: const pw.TextStyle(fontSize: 5)),
            );
          }).toList()))
        ]);
      },
    );

    pdf.addPage(pw.MultiPage(
      /*theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.varelaRoundRegular(),
        bold: await PdfGoogleFonts.varelaRoundRegular(),
        icons: await PdfGoogleFonts.materialIcons(),
      ),*/
      orientation: pw.PageOrientation.landscape,
      margin: const pw.EdgeInsets.all(10),
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [header, lisPointageWidget];
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }

  static void printRepportToExcel(List<Map<String, dynamic>> pointages) {
    int rowIndex = 2;
    var workbook = Workbook();
    var sheet = workbook.worksheets[0];
    sheet.showGridlines = true;
// set borders line style and color for cell.
    final Style style = workbook.styles.add('style');
    style.borders.all.lineStyle = LineStyle.thin;
    style.borders.all.color = '#000000';
    style.fontSize = 14;
    style.bold = true;
    style.backColor = "#B0C4DE";

    Map<String, dynamic> pointageSite = pointages.first;
    //Supervisor superviseur = pointageSite['supervisor'];
    //int nbSite = pointageSite['nbSite'];
    List<Map<String, dynamic>> pointing = pointageSite['Pointages'];
    //titre
    DateTime date = pointing.first["date"];
    sheet
        .getRangeByIndex(1, 1)
        .setText("Pointages du ${date.month}/${date.year}");
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 18;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
//header
    int colIndex = 2;
    sheet.getRangeByIndex(2, 1).setText("Superviseurs");
    sheet.getRangeByIndex(2, 1).cellStyle = style;
    for (Map<String, dynamic> p in pointing) {
      DateTime date = p["date"];
      sheet.getRangeByIndex(2, colIndex).setValue(date.day);
      sheet.getRangeByIndex(2, colIndex).cellStyle = style;
      colIndex++;
    }

    style.fontSize = 10;
    style.bold = false;
    style.backColor = "#FFFFFF";

    for (Map<String, dynamic> pointageSite in pointages) {
      rowIndex++;
      int colIndex = 2;
      Supervisor superviseur = pointageSite['supervisor'];
      int nbSite = pointageSite['nbSite'];
      List<Map<String, dynamic>> pointing = pointageSite['Pointages'];
      sheet
          .getRangeByIndex(rowIndex, 1)
          .setText("${superviseur.firstName} ${superviseur.lastName}");
      sheet.getRangeByIndex(rowIndex, 1).columnWidth = 12;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.color =
          '#000000';
      for (Map<String, dynamic> p in pointing) {
        DateTime date = p["date"];
        int nbPointage = p["nbPointage"];
        sheet
            .getRangeByIndex(rowIndex, colIndex)
            .setText("$nbPointage/$nbSite");
        sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = style;
        colIndex++;
      }
    }
//Save and launch the excel.
    final List<int> bytes = workbook.saveAsStream();
    var file = File(bytes, "PointageSiteParSuperviseur.xlsx");

//Dispose the document.
    workbook.dispose();
//Save and launch file.

    final content = base64Encode(bytes);
    final anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", "PointageSiteParSuperviseur.xlsx")
      ..click();
  }
}
