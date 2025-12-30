import 'dart:convert';
import 'dart:html';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:universal_html/html.dart' as html;

import '../model.dart';

class ZoneRapportPointage {
  static void printRepport(List<Map<String, dynamic>> pointages) async {
    final pdf = pw.Document();
    Map<String, dynamic> pointageSite = pointages.first;
    ZoneMember zoneMember = pointageSite['zoneMember'];
    int nbSite = pointageSite['nbSite'];
    List<Map<String, dynamic>> pointing = pointageSite['Pointages'];

    pw.Widget header = pw.Row(children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        width: 60,
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Text("Chefs de zone", style: const pw.TextStyle(fontSize: 6)),
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
        ZoneMember zoneMember = pointageSite['zoneMember'];
        int nbSite = pointageSite['nbSite'];
        List<Map<String, dynamic>> pointing = pointageSite['Pointages'];

        return pw.Row(children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            width: 60,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text("${zoneMember.firstName} ${zoneMember.lastName}",
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
    int nbJours = 0;
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
    nbJours = pointing.length;
    //titre
    DateTime date = pointing.first["date"];
    sheet
        .getRangeByIndex(1, 1)
        .setText("Pointages du ${date.month}/${date.year}");
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 18;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
//header
    int colIndex = 6;
    sheet.getRangeByIndex(2, 1).setText("Chefs de zone");
    sheet.getRangeByIndex(2, 1).cellStyle = style;

    sheet.getRangeByIndex(2, 2).setText("Pointage Max");
    sheet.getRangeByIndex(2, 2).cellStyle = style;

    sheet.getRangeByIndex(2, 3).setText("Pointage éffectué");
    sheet.getRangeByIndex(2, 3).cellStyle = style;

    sheet.getRangeByIndex(2, 4).setText("Performance");
    sheet.getRangeByIndex(2, 4).cellStyle = style;

    sheet.getRangeByIndex(2, 5).setText("Nombre de site");
    sheet.getRangeByIndex(2, 5).cellStyle = style;

    for (Map<String, dynamic> p in pointing) {
      DateTime date = p["date"];
      sheet.getRangeByIndex(2, colIndex).setValue(date.day);
      sheet.getRangeByIndex(2, colIndex).cellStyle = style;
      colIndex++;
    }

    style.fontSize = 10;
    style.bold = false;
    style.backColor = "#FFFFFF";

    for (Map<String, dynamic> pointage in pointages) {
      rowIndex++;
      int colIndex = 6;
      ZoneMember zoneMember = pointage['zoneMember'];
      int nbSite = pointage['nbSite'];
      int maxPointage = nbSite * nbJours;

      int nbPointages = 0;
      List<Map<String, dynamic>> pointings = pointage['Pointages'];

      for (var element in pointings) {
        int nbPointage = element["nbPointage"];
        nbPointages += nbPointage;
      }
      //calcul du pourcentage du nombre de pointage
      double performance =
          maxPointage == 0 ? 0 : nbPointages * 100 / maxPointage;

      sheet
          .getRangeByIndex(rowIndex, 1)
          .setText("${zoneMember.firstName} ${zoneMember.lastName}");
      sheet.getRangeByIndex(rowIndex, 1).columnWidth = 12;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.color =
          '#000000';
      sheet.getRangeByIndex(rowIndex, 2).setValue(maxPointage);
      sheet.getRangeByIndex(rowIndex, 2).columnWidth = 12;

      sheet.getRangeByIndex(rowIndex, 2).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 2).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 2).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 2).cellStyle.borders.all.color =
          '#000000';
      sheet.getRangeByIndex(rowIndex, 3).setValue(nbPointages);
      sheet.getRangeByIndex(rowIndex, 3).columnWidth = 12;

      sheet.getRangeByIndex(rowIndex, 3).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.borders.all.color =
          '#000000';

      sheet
          .getRangeByIndex(rowIndex, 4)
          .setValue("${performance.toStringAsFixed(2)}%");
      sheet.getRangeByIndex(rowIndex, 4).columnWidth = 12;

      sheet.getRangeByIndex(rowIndex, 4).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.borders.all.color =
          '#000000';

      sheet.getRangeByIndex(rowIndex, 5).setValue(nbSite);
      sheet.getRangeByIndex(rowIndex, 5).columnWidth = 12;
      sheet.getRangeByIndex(rowIndex, 5).cellStyle.backColor = "#00afff";
      sheet.getRangeByIndex(rowIndex, 5).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 5).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 5).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 5).cellStyle.borders.all.color =
          '#000000';

      for (Map<String, dynamic> point in pointings) {
        DateTime date = point["date"];
        int nbPointage = point["nbPointage"];
        sheet
            .getRangeByIndex(rowIndex, colIndex)
            .setValue(nbPointage == 0 ? "" : nbPointage);
        sheet.getRangeByIndex(rowIndex, colIndex).cellStyle = style;
        colIndex++;
      }
    }
//Save and launch the excel.
    final List<int> bytes = workbook.saveAsStream();
    var file = File(bytes, "PointageSiteParZone.xlsx");

//Dispose the document.
    workbook.dispose();
//Save and launch file.

    final content = base64Encode(bytes);
    final anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", "PointageSiteParZone.xlsx")
      ..click();
  }

  static void printMonthlySiteRepportToExcel(
      List<Map<String, dynamic>> pointages) {
    pointages.sort((p1, p2) {
      int nbPointage1 = p1['nbPointage'];
      int nbPointage2 = p2['nbPointage'];
      return nbPointage2.compareTo(nbPointage1);
    });
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

    //titre
    String periode = pointages.first["date"];
    sheet.getRangeByIndex(1, 1).setText("Pointages site du $periode");
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 18;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
//header

    sheet.getRangeByIndex(2, 1).setText("Sites");
    sheet.getRangeByIndex(2, 1).cellStyle = style;

    sheet.getRangeByIndex(2, 2).setText("Superviseur 1");
    sheet.getRangeByIndex(2, 2).cellStyle = style;

    sheet.getRangeByIndex(2, 3).setText("Superviseur 2");
    sheet.getRangeByIndex(2, 3).cellStyle = style;

    sheet.getRangeByIndex(2, 4).setText("Nombre de visite");
    sheet.getRangeByIndex(2, 4).cellStyle = style;

    style.fontSize = 10;
    style.bold = false;
    style.backColor = "#FFFFFF";

    for (Map<String, dynamic> pointage in pointages) {
      rowIndex++;

      Site site = pointage['site'];
      int nbPointage = pointage['nbPointage'];

      sheet.getRangeByIndex(rowIndex, 1).setText(site.name);
      sheet.getRangeByIndex(rowIndex, 1).columnWidth = 12;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 1).cellStyle.borders.all.color =
          '#000000';
      sheet.getRangeByIndex(rowIndex, 2).setText(
          "${site.supervisor?.firstName} ${site.supervisor?.lastName}");
      sheet.getRangeByIndex(rowIndex, 2).columnWidth = 12;

      sheet.getRangeByIndex(rowIndex, 2).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 2).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 2).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 2).cellStyle.borders.all.color =
          '#000000';
      sheet.getRangeByIndex(rowIndex, 3).setText(
          "${site.supervisor_2?.firstName ?? ""} ${site.supervisor_2?.lastName ?? ""}");
      sheet.getRangeByIndex(rowIndex, 3).columnWidth = 12;

      sheet.getRangeByIndex(rowIndex, 3).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.borders.all.color =
          '#000000';

      sheet.getRangeByIndex(rowIndex, 4).setValue(nbPointage);
      sheet.getRangeByIndex(rowIndex, 4).columnWidth = 12;

      sheet.getRangeByIndex(rowIndex, 4).cellStyle.fontSize = 10;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.bold = false;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.borders.all.lineStyle =
          LineStyle.thin;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.borders.all.color =
          '#000000';
    }
//Save and launch the excel.
    final List<int> bytes = workbook.saveAsStream();
    var file = File(bytes, "ZonePointageSiteParMois.xlsx");

//Dispose the document.
    workbook.dispose();
//Save and launch file.

    final content = base64Encode(bytes);
    final anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", "ZonePointageSiteParMois.xlsx")
      ..click();
  }

  /// Génère un rapport résumé RH avec formatage conditionnel
  /// 
  /// Colonnes: Superviseur, Manager, Sites assignés, Visites effectuées, 
  /// Attendu, Différence, Visites manquées, Commentaire
  /// 
  /// [pointages] - Liste des données de pointage par chef de zone
  /// [startDate] - Date de début de la période
  /// [endDate] - Date de fin de la période
  static void printHRSummaryReportToExcel(
      List<Map<String, dynamic>> pointages,
      DateTime startDate,
      DateTime endDate) {
    
    // Calculer le nombre de jours dans la période
    final int nbDays = endDate.difference(startDate).inDays + 1;
    
    // Préparer les données avec calculs
    List<Map<String, dynamic>> summaryData = [];
    
    for (var pointage in pointages) {
      ZoneMember zoneMember = pointage['zoneMember'];
      int nbSite = pointage['nbSite'];
      List<Map<String, dynamic>> pointings = pointage['Pointages'];
      
      // Calculer le total des visites effectuées
      int completedVisits = 0;
      for (var p in pointings) {
        completedVisits += (p['nbPointage'] as int);
      }
      
      // Calculs selon les règles
      int expected = nbSite * nbDays;
      int difference = expected - completedVisits;
      int missedVisits = difference > 0 ? difference : 0;
      int daysBehind = nbSite > 0 ? (difference / nbSite).floor() : 0;
      if (daysBehind < 0) daysBehind = 0;
      
      // Générer le commentaire
      String comment;
      if (difference <= 0) {
        comment = "Objectif atteint";
      } else if (daysBehind == 0) {
        comment = "Objectif atteint";
      } else if (daysBehind == 1) {
        comment = "Moins de 1 jour de retard";
      } else {
        comment = "Moins de $daysBehind jours de retard";
      }
      
      summaryData.add({
        'zoneMember': zoneMember,
        'manager': zoneMember.zone?.name ?? '-',
        'assignedSites': nbSite,
        'completedVisits': completedVisits,
        'expected': expected,
        'difference': difference,
        'missedVisits': missedVisits,
        'daysBehind': daysBehind,
        'comment': comment,
      });
    }
    
    // Trier par différence décroissante (plus grand retard en premier)
    summaryData.sort((a, b) {
      int diffA = a['difference'] as int;
      int diffB = b['difference'] as int;
      return diffB.compareTo(diffA);
    });
    
    // Créer le workbook Excel
    var workbook = Workbook();
    var sheet = workbook.worksheets[0];
    sheet.name = 'Résumé RH';
    sheet.showGridlines = true;
    
    // Style pour l'en-tête
    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.borders.all.lineStyle = LineStyle.thin;
    headerStyle.borders.all.color = '#000000';
    headerStyle.fontSize = 12;
    headerStyle.bold = true;
    headerStyle.backColor = "#4472C4";
    headerStyle.fontColor = "#FFFFFF";
    headerStyle.hAlign = HAlignType.center;
    
    // Styles pour le formatage conditionnel
    final Style greenStyle = workbook.styles.add('greenStyle');
    greenStyle.borders.all.lineStyle = LineStyle.thin;
    greenStyle.borders.all.color = '#000000';
    greenStyle.fontSize = 10;
    greenStyle.backColor = "#C6EFCE";
    greenStyle.fontColor = "#006100";
    
    final Style yellowStyle = workbook.styles.add('yellowStyle');
    yellowStyle.borders.all.lineStyle = LineStyle.thin;
    yellowStyle.borders.all.color = '#000000';
    yellowStyle.fontSize = 10;
    yellowStyle.backColor = "#FFEB9C";
    yellowStyle.fontColor = "#9C5700";
    
    final Style orangeStyle = workbook.styles.add('orangeStyle');
    orangeStyle.borders.all.lineStyle = LineStyle.thin;
    orangeStyle.borders.all.color = '#000000';
    orangeStyle.fontSize = 10;
    orangeStyle.backColor = "#FFCC99";
    orangeStyle.fontColor = "#974706";
    
    final Style redStyle = workbook.styles.add('redStyle');
    redStyle.borders.all.lineStyle = LineStyle.thin;
    redStyle.borders.all.color = '#000000';
    redStyle.fontSize = 10;
    redStyle.backColor = "#FFC7CE";
    redStyle.fontColor = "#9C0006";
    
    // Titre du rapport
    String dateRange = "${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')}.${startDate.year.toString().substring(2)} au ${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year.toString().substring(2)}";
    sheet.getRangeByIndex(1, 1, 1, 8).merge();
    sheet.getRangeByIndex(1, 1).setText("Rapport des visites des Superviseurs du $dateRange");
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(1, 1).cellStyle.hAlign = HAlignType.center;
    
    // En-têtes des colonnes
    final headers = [
      'Superviseur',
      'Manager',
      'Sites assignés',
      'Visites effectuées',
      'Attendu',
      'Différence',
      'Visites manquées',
      'Commentaire'
    ];
    
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(3, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(3, i + 1).cellStyle = headerStyle;
      sheet.getRangeByIndex(3, i + 1).columnWidth = i == 0 || i == 7 ? 20 : 15;
    }
    
    // Données
    int rowIndex = 3;
    for (var data in summaryData) {
      rowIndex++;
      
      ZoneMember zoneMember = data['zoneMember'];
      int daysBehind = data['daysBehind'];
      int difference = data['difference'];
      
      // Déterminer le style selon le retard
      Style rowStyle;
      if (difference <= 0) {
        rowStyle = greenStyle;
      } else if (daysBehind <= 1) {
        rowStyle = yellowStyle;
      } else if (daysBehind <= 4) {
        rowStyle = orangeStyle;
      } else {
        rowStyle = redStyle;
      }
      
      // Superviseur
      sheet.getRangeByIndex(rowIndex, 1).setText("${zoneMember.firstName} ${zoneMember.lastName}");
      sheet.getRangeByIndex(rowIndex, 1).cellStyle = rowStyle;
      
      // Manager (Zone)
      sheet.getRangeByIndex(rowIndex, 2).setText(data['manager']);
      sheet.getRangeByIndex(rowIndex, 2).cellStyle = rowStyle;
      
      // Sites assignés
      sheet.getRangeByIndex(rowIndex, 3).setNumber(data['assignedSites'].toDouble());
      sheet.getRangeByIndex(rowIndex, 3).cellStyle = rowStyle;
      sheet.getRangeByIndex(rowIndex, 3).cellStyle.hAlign = HAlignType.center;
      
      // Visites effectuées
      sheet.getRangeByIndex(rowIndex, 4).setNumber(data['completedVisits'].toDouble());
      sheet.getRangeByIndex(rowIndex, 4).cellStyle = rowStyle;
      sheet.getRangeByIndex(rowIndex, 4).cellStyle.hAlign = HAlignType.center;
      
      // Attendu
      sheet.getRangeByIndex(rowIndex, 5).setNumber(data['expected'].toDouble());
      sheet.getRangeByIndex(rowIndex, 5).cellStyle = rowStyle;
      sheet.getRangeByIndex(rowIndex, 5).cellStyle.hAlign = HAlignType.center;
      
      // Différence
      sheet.getRangeByIndex(rowIndex, 6).setNumber(data['difference'].toDouble());
      sheet.getRangeByIndex(rowIndex, 6).cellStyle = rowStyle;
      sheet.getRangeByIndex(rowIndex, 6).cellStyle.hAlign = HAlignType.center;
      
      // Visites manquées
      sheet.getRangeByIndex(rowIndex, 7).setNumber(data['missedVisits'].toDouble());
      sheet.getRangeByIndex(rowIndex, 7).cellStyle = rowStyle;
      sheet.getRangeByIndex(rowIndex, 7).cellStyle.hAlign = HAlignType.center;
      
      // Commentaire
      sheet.getRangeByIndex(rowIndex, 8).setText(data['comment']);
      sheet.getRangeByIndex(rowIndex, 8).cellStyle = rowStyle;
    }
    
    // Sauvegarder et télécharger
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    
    final content = base64Encode(bytes);
    final fileName = "Rapport_RH_Superviseurs_$dateRange.xlsx".replaceAll(' ', '_');
    AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,$content")
      ..setAttribute("download", fileName)
      ..click();
  }
}
