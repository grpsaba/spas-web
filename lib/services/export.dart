import 'dart:convert';
import 'dart:html';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart';
import 'package:spas_web/const.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

import '../model.dart';

class ExportData {
  static void pointageAgentToExcel(List<Map<String, dynamic>> data,
      String debut, String fin, bool isBefore) {
    if (isBefore) {
      int rowIndex = 1;
      var workbook = Workbook();
      var sheet = workbook.worksheets[0];
      sheet.showGridlines = false;
      // set borders line style and color for cell.
      final Style style = workbook.styles.add('style');
      style.borders.all.lineStyle = LineStyle.thin;
      style.borders.all.color = '#000000';
      style.fontSize = 12;
      style.bold = true;
      style.backColor = "#32CD32";

      /*sheet.getRangeByIndex(1, 1).setText("Période");
          sheet.getRangeByIndex(1, 1).cellStyle = style;

          sheet.getRangeByIndex(1, 2).setText("Immatricule");
          sheet.getRangeByIndex(1, 2).cellStyle = style;

          sheet.getRangeByIndex(1, 3).setText("Prénom");
          sheet.getRangeByIndex(1, 3).cellStyle = style;

          sheet.getRangeByIndex(1, 4).setText("Nom");
          sheet.getRangeByIndex(1, 4).cellStyle = style;

          sheet.getRangeByIndex(1, 5).setText("Contact");
          sheet.getRangeByIndex(1, 5).cellStyle = style;

          sheet.getRangeByIndex(1, 6).setText("Présence");
          sheet.getRangeByIndex(1, 6).cellStyle = style;*/

      style.fontSize = 10;
      style.bold = false;
      style.backColor = "#FFFFFF";

      for (var pointageData in data) {
        Agent agent = pointageData["agent"];
        List<PointingAgent> pointages = pointageData["pointages"];

        rowIndex++;
        sheet.getRangeByIndex(rowIndex, 1).setText(agent.code);
        sheet.getRangeByIndex(rowIndex, 1).columnWidth = 12;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.fontSize = 10;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = false;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.lineStyle =
            LineStyle.thin;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.color =
            '#000000';

        sheet.getRangeByIndex(rowIndex, 2).setText("255");
        sheet.getRangeByIndex(rowIndex, 2).cellStyle = style;

        sheet.getRangeByIndex(rowIndex, 3).setText("HA10");
        sheet.getRangeByIndex(rowIndex, 3).cellStyle = style;

        sheet.getRangeByIndex(rowIndex, 4).setText("${30 - pointages.length}");
        sheet.getRangeByIndex(rowIndex, 4).cellStyle = style;

        /*sheet.getRangeByIndex(rowIndex, 5).setText(agent.phone);
            sheet.getRangeByIndex(rowIndex, 5).cellStyle = style;

            sheet.getRangeByIndex(rowIndex, 6).setText(pointages.length.toString());
            sheet.getRangeByIndex(rowIndex, 6).cellStyle = style;*/
      }
      //Save and launch the excel.
      final List<int> bytes = workbook.saveAsStream();
      var file = File(bytes, "pointageAgents.xlsx");

      //Dispose the document.
      workbook.dispose();
      //Save and launch file.

      final content = base64Encode(bytes);
      final anchor = AnchorElement(
          href:
              "data:application/octet-stream;charset=utf-16le;base64,$content")
        ..setAttribute("download", "pointageAgents.xlsx")
        ..click();
    } else {
      int rowIndex = 1;
      var workbook = Workbook();
      var sheet = workbook.worksheets[0];
      sheet.showGridlines = false;
      // set borders line style and color for cell.
      final Style style = workbook.styles.add('style');
      style.borders.all.lineStyle = LineStyle.thin;
      style.borders.all.color = '#000000';
      style.fontSize = 12;
      style.bold = true;
      style.backColor = "#32CD32";

      /*sheet.getRangeByIndex(1, 1).setText("Période");
          sheet.getRangeByIndex(1, 1).cellStyle = style;

          sheet.getRangeByIndex(1, 2).setText("Immatricule");
          sheet.getRangeByIndex(1, 2).cellStyle = style;

          sheet.getRangeByIndex(1, 3).setText("Prénom");
          sheet.getRangeByIndex(1, 3).cellStyle = style;

          sheet.getRangeByIndex(1, 4).setText("Nom");
          sheet.getRangeByIndex(1, 4).cellStyle = style;

          sheet.getRangeByIndex(1, 5).setText("Contact");
          sheet.getRangeByIndex(1, 5).cellStyle = style;

          sheet.getRangeByIndex(1, 6).setText("Présence");
          sheet.getRangeByIndex(1, 6).cellStyle = style;*/

      style.fontSize = 10;
      style.bold = false;
      style.backColor = "#FFFFFF";

      for (var pointageData in data) {
        Agent agent = pointageData["agent"];
        List<PointingAgent> pointages = pointageData["pointages"];

        rowIndex++;
        sheet.getRangeByIndex(rowIndex, 1).setText(agent.code);
        sheet.getRangeByIndex(rowIndex, 1).columnWidth = 12;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.fontSize = 10;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = false;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.lineStyle =
            LineStyle.thin;
        sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.color =
            '#000000';

        sheet.getRangeByIndex(rowIndex, 2).setText("255");
        sheet.getRangeByIndex(rowIndex, 2).cellStyle = style;

        sheet.getRangeByIndex(rowIndex, 3).setText("HA09");
        sheet.getRangeByIndex(rowIndex, 3).cellStyle = style;

        sheet.getRangeByIndex(rowIndex, 4).setText("${pointages.length - 30}");
        sheet.getRangeByIndex(rowIndex, 4).cellStyle = style;

        /*sheet.getRangeByIndex(rowIndex, 5).setText(agent.phone);
            sheet.getRangeByIndex(rowIndex, 5).cellStyle = style;

            sheet.getRangeByIndex(rowIndex, 6).setText(pointages.length.toString());
            sheet.getRangeByIndex(rowIndex, 6).cellStyle = style;*/
      }
      //Save and launch the excel.
      final List<int> bytes = workbook.saveAsStream();
      var file = File(bytes, "pointageAgents.xlsx");

      //Dispose the document.
      workbook.dispose();
      //Save and launch file.

      final content = base64Encode(bytes);
      final anchor = AnchorElement(
          href:
              "data:application/octet-stream;charset=utf-16le;base64,$content")
        ..setAttribute("download", "pointageAgents.xlsx")
        ..click();
    }
  }

  static void pointageSiteToExcel(
      List<Map<String, dynamic>> data, String debut, String fin) {
    int rowIndex = 1;
    var workbook = Workbook();
    var sheet = workbook.worksheets[0];
    sheet.showGridlines = false;
    // set borders line style and color for cell.
    final Style style = workbook.styles.add('style');
    style.borders.all.lineStyle = LineStyle.thin;
    style.borders.all.color = '#000000';
    style.fontSize = 12;
    style.bold = true;
    style.backColor = "#32CD32";

    sheet.getRangeByIndex(1, 1).setText("Période");
    sheet.getRangeByIndex(1, 1).cellStyle = style;

    sheet.getRangeByIndex(1, 4).setText("Nom");
    sheet.getRangeByIndex(1, 4).cellStyle = style;

    sheet.getRangeByIndex(1, 5).setText("Contact");
    sheet.getRangeByIndex(1, 5).cellStyle = style;

    sheet.getRangeByIndex(1, 6).setText("Visites");
    sheet.getRangeByIndex(1, 6).cellStyle = style;

    style.fontSize = 10;
    style.bold = false;
    style.backColor = "#FFFFFF";

    for (var pointageData in data) {
      Site site = pointageData["site"];
      List<PointingSite> pointages = pointageData["pointages"];
      rowIndex++;
      sheet.getRangeByIndex(rowIndex, 1).setText(
          "${debut.toString().split(" ")[0]} - ${fin.toString().split(" ")[0]}");
      sheet.getRangeByIndex(rowIndex, 1).columnWidth = 12;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.color =
          '#000000';

      sheet.getRangeByIndex(rowIndex, 4).setText(site.name);
      sheet.getRangeByIndex(rowIndex, 4).cellStyle = style;

      sheet.getRangeByIndex(rowIndex, 5).setText(site.phone);
      sheet.getRangeByIndex(rowIndex, 5).cellStyle = style;

      sheet.getRangeByIndex(rowIndex, 6).setText(pointages.length.toString());
      sheet.getRangeByIndex(rowIndex, 6).cellStyle = style;
    }
    //Save and launch the excel.
    final List<int> bytes = workbook.saveAsStream();
    var file = File(bytes, "pointageSites.xlsx");

    //Dispose the document.
    workbook.dispose();
    //Save and launch file.

    final content = base64Encode(bytes);
    final anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", "pointageSites.xlsx")
      ..click();
  }
}

class CarteGenerator {
  static void generateCarteAgent(Agent agent) async {
    final pdf = pw.Document();
    //get logo

    var image = pw.MemoryImage(
      (await rootBundle.load("assets/logo.png")).buffer.asUint8List(),
    );
    // get default avatar
    var avatar = pw.MemoryImage(
      (await rootBundle.load("assets/agent.png")).buffer.asUint8List(),
    );
    //get avatar
    pw.Image avatarImage = pw.Image(avatar);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (context) {
        return pw.Container(
            margin: const pw.EdgeInsets.all(5),
            height: 152,
            width: 245,
            decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.indigo, width: 2.0)),
            child: pw.Column(
              children: [
                //header

                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      //logo
                      pw.Image(image),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("GROUPE SABA",
                                  style: pw.TextStyle(
                                      fontSize: 15,
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.SizedBox(width: 10),
                          pw.Container(
                              height: 50,
                              width: 50,
                              child: pw.ClipOval(child: avatarImage))
                        ],
                      )
                    ],
                  ),
                  height: 50,
                  decoration: const pw.BoxDecoration(
                      color: PdfColors.indigo,
                      borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5))),
                ),
                //contant
                pw.Expanded(
                    child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            //contant info personne
                            pw.Row(
                              children: [
                                //item info personne
                                pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceAround,
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                        "${agent.firstName} ${agent.lastName}",
                                        style: pw.TextStyle(
                                            fontSize: 12,
                                            color: PdfColors.black,
                                            fontWeight: pw.FontWeight.bold)),
                                    pw.Text(
                                      "Immatricule: ${agent.code}",
                                      style: const pw.TextStyle(
                                        fontSize: 11,
                                      ),
                                    ),
                                    pw.Text(
                                      "Téléphone: ${agent.phone}",
                                      style: const pw.TextStyle(fontSize: 11),
                                    )
                                  ],
                                )
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Container(
                                      height: 70,
                                      width: 70,
                                      child: pw.BarcodeWidget(
                                          color: PdfColors.black,
                                          barcode: pw.Barcode.qrCode(),
                                          data: agent.code),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        )))
              ],
            ));
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }

//multiple
  static void generateMiltiCarteAgent(List<Agent> data) async {
    final pdf = pw.Document();
    //get logo
    var image = pw.MemoryImage(
      (await rootBundle.load("assets/logo.png")).buffer.asUint8List(),
    );
    // get default avatar
    var avatar = pw.MemoryImage(
      (await rootBundle.load("assets/agent.png")).buffer.asUint8List(),
    );
    pw.Widget listCarte = pw.Wrap(
        children: data.map((agent) {
      pw.Widget contant;
      //get avatar
      pw.Image avatarImage = pw.Image(avatar);

      return pw.Container(
          margin: const pw.EdgeInsets.all(5),
          height: 152,
          width: 245,
          decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.indigo, width: 2.0)),
          child: pw.Column(
            children: [
              //header

              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    //logo
                    pw.Image(image),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text("GROUPE SABA",
                                style: pw.TextStyle(
                                    fontSize: 15,
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(width: 10),
                        pw.Container(
                            height: 50,
                            width: 50,
                            child: pw.ClipOval(child: avatarImage))
                      ],
                    )
                  ],
                ),
                height: 50,
                decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo,
                    borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(5),
                        topRight: pw.Radius.circular(5))),
              ),
              //contant
              pw.Expanded(
                  child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          //contant info personne
                          pw.Row(
                            children: [
                              //item info personne
                              pw.Column(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceAround,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                      "${agent.firstName} ${agent.lastName}",
                                      style: pw.TextStyle(
                                          fontSize: 12,
                                          color: PdfColors.black,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(
                                    "Immatricule: ${agent.code}",
                                    style: const pw.TextStyle(
                                      fontSize: 11,
                                    ),
                                  ),
                                  pw.Text(
                                    "Téléphone: ${agent.phone}",
                                    style: const pw.TextStyle(fontSize: 11),
                                  ),
                                  pw.Text(
                                    "Domaine: ${agent.type}",
                                    style: const pw.TextStyle(fontSize: 11),
                                  )
                                ],
                              )
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    height: 70,
                                    width: 70,
                                    child: pw.BarcodeWidget(
                                        color: PdfColors.black,
                                        barcode: pw.Barcode.qrCode(),
                                        data: agent.code),
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      )))
            ],
          ));
    }).toList());

    pdf.addPage(pw.MultiPage(
      /*theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.varelaRoundRegular(),
        bold: await PdfGoogleFonts.varelaRoundRegular(),
        icons: await PdfGoogleFonts.materialIcons(),
      ),*/
      margin: pw.EdgeInsets.all(2),
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [listCarte];
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }

  static void generateQrSite(Site site) async {
    final pdf = pw.Document();
    //get logo

    var image = pw.MemoryImage(
      (await rootBundle.load("assets/logo.png")).buffer.asUint8List(),
    );

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a6,
      build: (context) {
        return pw.Container(
            margin: const pw.EdgeInsets.all(10),
            height: 434,
            width: 283,
            decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.indigo, width: 2.0)),
            child: pw.Column(
              children: [
                pw.SizedBox(height: 10.0),
                pw.Image(image, height: 128, width: 128),
                //QR code
                pw.Container(
                  height: 200,
                  width: 200,
                  child: pw.BarcodeWidget(
                      color: PdfColors.black,
                      barcode: pw.Barcode.qrCode(),
                      data: site.UID),
                ),
                pw.SizedBox(height: 10.0),
                pw.Text(site.name,
                    style: pw.TextStyle(
                        fontSize: 15,
                        color: PdfColors.indigo,
                        fontWeight: pw.FontWeight.bold)),
              ],
            ));
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }

//multiple
  static void generateMiltiQrSite(List<Site> data) async {
    final pdf = pw.Document();
    //get logo
    var image = pw.MemoryImage(
      (await rootBundle.load("assets/logo.png")).buffer.asUint8List(),
    );

    pw.Widget listCarte = pw.Wrap(
        children: data.map((site) {
      pw.Widget contant;

      return pw.Container(
          margin: const pw.EdgeInsets.all(10),
          height: 434,
          width: 283,
          decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.indigo, width: 2.0)),
          child: pw.Column(
            children: [
              pw.SizedBox(height: 10.0),
              pw.Image(image, height: 128, width: 128),
              //QR code
              pw.Container(
                height: 200,
                width: 200,
                child: pw.BarcodeWidget(
                    color: PdfColors.black,
                    barcode: pw.Barcode.qrCode(),
                    data: site.UID),
              ),
              pw.SizedBox(height: 10.0),
              pw.Text(site.name,
                  style: pw.TextStyle(
                      fontSize: 15,
                      color: PdfColors.indigo,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10.0),
            ],
          ));
    }).toList());

    pdf.addPage(pw.MultiPage(
      /*theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.varelaRoundRegular(),
        bold: await PdfGoogleFonts.varelaRoundRegular(),
        icons: await PdfGoogleFonts.materialIcons(),
      ),*/
      margin: const pw.EdgeInsets.all(5.0),
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [listCarte];
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }

  static void generateQrTool(Tool tool) async {
    final pdf = pw.Document();
    //get logo

    var image = pw.MemoryImage(
      (await rootBundle.load("assets/logo.png")).buffer.asUint8List(),
    );

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Container(
            margin: const pw.EdgeInsets.all(10),
            width: 64,
            height: 150,
            decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(5),
                border: pw.Border.all(color: PdfColors.indigo, width: 2.0)),
            child: pw.Column(
              children: [
                pw.SizedBox(height: 10.0),
                pw.Image(image, height: 50, width: 50),
                //QR code
                pw.Container(
                  height: 50,
                  width: 50,
                  child: pw.BarcodeWidget(
                      color: PdfColors.black,
                      barcode: pw.Barcode.qrCode(),
                      data: tool.serialNumber),
                ),
                pw.SizedBox(height: 10.0),
                pw.Text(tool.serialNumber,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.indigo,
                    )),
                pw.SizedBox(height: 10.0),
              ],
            ));
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }

//multiple
  static void generateMiltiQrTool(List<Tool> data) async {
    final pdf = pw.Document();
    //get logo
    var image = pw.MemoryImage(
      (await rootBundle.load("assets/logo.png")).buffer.asUint8List(),
    );

    pw.Widget listCarte = pw.Wrap(
        children: data.map((tool) {
      pw.Widget contant;

      return pw.Container(
          margin: const pw.EdgeInsets.all(10),
          width: 64,
          decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(5),
              border: pw.Border.all(color: PdfColors.indigo, width: 2.0)),
          child: pw.Column(
            children: [
              pw.SizedBox(height: 10.0),
              pw.Image(image, height: 50, width: 50),
              //QR code
              pw.Container(
                height: 50,
                width: 50,
                child: pw.BarcodeWidget(
                    color: PdfColors.black,
                    barcode: pw.Barcode.qrCode(),
                    data: tool.serialNumber),
              ),
              pw.SizedBox(height: 10.0),
              pw.Text(tool.serialNumber,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.indigo,
                  )),
              pw.SizedBox(height: 10.0),
            ],
          ));
    }).toList());

    pdf.addPage(pw.MultiPage(
      /*theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.varelaRoundRegular(),
        bold: await PdfGoogleFonts.varelaRoundRegular(),
        icons: await PdfGoogleFonts.materialIcons(),
      ),*/
      margin: const pw.EdgeInsets.all(5.0),
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [listCarte];
      },
    ));
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }
}

class SiteListToPDF {
  static Future<Uint8List> export(
    List<Site> dataSite,
  ) async {
    final pdf = Document();

    pdf.addPage(MultiPage(
      build: (context) => [
        //Text("Conso part employe"),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(),
        buildInvoice(dataSite),
      ],
      footer: (context) => buildFooter(),
    ));

    return pdf.save();
  }

  static Widget buildFooter() => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          Text("Powered by ${AppConstants.oragnisationName}"),
        ],
      );
  static Widget buildTitle() => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LISTE DES SITES',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          /*Text(
             "Nombre de ticket consommé du "),*/
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );
  static Widget buildInvoice(List<Site> dataSite) {
    final headers = [
      'Nom',
      'Adresse',
      'Contact',
      'Superviseur',
      "Nombre Agent prevu",
      "Statut",
    ];
    dataSite.sort((Site1, Site2) {
      return Site1.name.compareTo(Site2.name);
    });
    final data = dataSite.map((site) {
      return [
        site.name,
        site.adresse,
        //employe.telephone,
        site.phone,
        '${site.supervisor?.firstName} ${site.supervisor?.lastName}',
        site.nbAgent,
        site.actif!?"Actif":"Inactif"
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      //cellHeight: 30,
      cellDecoration: (val, va, de) => const BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
      cellStyle: const TextStyle(fontSize: 10),
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerLeft,
        3: Alignment.centerLeft,
        4: Alignment.centerRight,
      },
    );
  }
}

class AgentListToPDF {
  static Future<Uint8List> export(List<Agent> dataAgent,
      {String title = 'LISTE DES AGENTS'}) async {
    final pdf = Document();

    pdf.addPage(MultiPage(
      margin: const pw.EdgeInsets.all(10),
      build: (context) => [
        //Text("Conso part employe"),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(title),
        buildInvoice(dataAgent),
      ],
      footer: (context) => buildFooter(),
    ));

    return pdf.save();
  }

  static Widget buildFooter() => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          Text("Powered by ${AppConstants.oragnisationName}"),
        ],
      );
  static Widget buildTitle(title) => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          /*Text(
             "Nombre de ticket consommé du "),*/
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );
  static Widget buildInvoice(List<Agent> dataAgent) {
    final headers = [
      'Domaine',
      'Prénom',
      'Nom',
      'Catégorie',
      'Statut',
      'Site',
      'Contact',
    ];
    /*dataAgent.sort((Agent1, Agent2) {
      return Agent1.site!.name.compareTo(Agent2.site!.name);
    });*/
    final data = dataAgent.map((agent) {
      return [
        agent.type,
        agent.firstName,
        //employe.telephone,
        agent.lastName,
        agent.categorie,
        agent.actif! ? "Actif" : "Inactif",
        agent.site?.name,
        agent.phone,
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      //cellHeight: 30,
      cellDecoration: (val, va, de) => const BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
      cellStyle: const TextStyle(fontSize: 10),
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerLeft,
        3: Alignment.centerLeft,
        4: Alignment.centerRight,
      },
    );
  }
}

class PointageSiteListToPDF {
  static Future<Uint8List> export(List<PointingSite> dataPointage,
      {String title = 'LISTE DE POINTAGES SITE'}) async {
    final pdf = Document();

    pdf.addPage(MultiPage(
      //margin: const pw.EdgeInsets.all(5),
      build: (context) => [
        //Text("Conso part employe"),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(title),
        buildInvoice(dataPointage),
      ],
      footer: (context) => buildFooter(),
    ));

    return pdf.save();
  }

  static Widget buildFooter() => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          Text("Powered by ${AppConstants.oragnisationName}"),
        ],
      );
  static Widget buildTitle(title) => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          /*Text(
             "Nombre de ticket consommé du "),*/
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );
  static Widget buildInvoice(List<PointingSite> dataPointage) {
    final headers = [
      'Date',
      'Heure',
      'Site',
      'Superviseur',
      'Contact',
    ];

    final data = dataPointage.map((pointage) {
      return [
        pointage.date.toString().split(" ")[0],
        "${pointage.date.hour}:${pointage.date.minute}:${pointage.date.second}",
        //employe.telephone,
        pointage.site.name,
        "${pointage.supervisor?.firstName} ${pointage.supervisor?.lastName}",
        pointage.supervisor?.phone,
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      //cellHeight: 30,
      cellDecoration: (val, va, de) => const BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
      cellStyle: const TextStyle(fontSize: 10),
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerLeft,
        3: Alignment.centerLeft,
        4: Alignment.centerRight,
      },
    );
  }
}

class PointageToolListToPDF {
  static Future<Uint8List> export(List<PointingTools> dataPointage,
      {String title = 'LISTE DE POINTAGES MATERIEL'}) async {
    final pdf = Document();

    pdf.addPage(MultiPage(
      //margin: const pw.EdgeInsets.all(5),
      build: (context) => [
        //Text("Conso part employe"),
        SizedBox(height: 3 * PdfPageFormat.cm),
        buildTitle(title),
        buildInvoice(dataPointage),
      ],
      footer: (context) => buildFooter(),
    ));

    return pdf.save();
  }

  static Widget buildFooter() => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(),
          SizedBox(height: 2 * PdfPageFormat.mm),
          Text("Powered by ${AppConstants.oragnisationName}"),
        ],
      );
  static Widget buildTitle(title) => pw.Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 0.8 * PdfPageFormat.cm),
          /*Text(
             "Nombre de ticket consommé du "),*/
          SizedBox(height: 0.8 * PdfPageFormat.cm),
        ],
      );
  static Widget buildInvoice(List<PointingTools> dataPointage) {
    final headers = [
      'Date',
      'Heure',
      'Matériel',
      'Site',
      'Superviseur',
      'Contact',
      'Statut',
    ];

    final data = dataPointage.map((pointage) {
      return [
        pointage.date.toString().split(" ")[0],
        "${pointage.date.hour}:${pointage.date.minute}:${pointage.date.second}",
        //employe.telephone,
        pointage.tool.label,
        pointage.tool.site?.name,
        "${pointage.tool.site?.supervisor?.firstName} ${pointage.tool.site?.supervisor?.lastName}",
        pointage.tool.site?.supervisor?.phone,
        pointage.status,
      ];
    }).toList();

    return TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      headerDecoration: const BoxDecoration(color: PdfColors.grey300),
      //cellHeight: 30,
      cellDecoration: (val, va, de) => const BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
      cellStyle: const TextStyle(fontSize: 10),
      cellAlignments: {
        0: Alignment.centerLeft,
        1: Alignment.centerLeft,
        2: Alignment.centerLeft,
        3: Alignment.centerLeft,
        4: Alignment.centerRight,
      },
    );
  }
}
