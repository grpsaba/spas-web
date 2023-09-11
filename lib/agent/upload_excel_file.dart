import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:spas_web/services/agent.dart';

import '../model.dart';

class UploadExcel {
  int codeClIndex;
  int firstNameClIndex;
  int lastNameClIndex;
  int contactClIndex;
  int sartRowIndex;
  Site? site;
  String type;
  String domaine;
  UploadExcel(
      {required this.site,
      required this.type,
      required this.domaine,
      required this.codeClIndex,
      required this.contactClIndex,
      required this.firstNameClIndex,
      required this.lastNameClIndex,
      required this.sartRowIndex});
  Future<Excel?> upload() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );

    /// file might be picked

    if (pickedFile != null) {
      var bytes = pickedFile.files.single.bytes;
      var excel = Excel.decodeBytes(bytes!.toList());
      return excel;
    } else {
      return null;
    }
  }

  Future<void> crateAgentFromExcel(Excel excel) async {
    List<List<Data?>> newRows = [];
    String table = excel.tables.keys.first;
    for (int i = sartRowIndex; i <= excel.tables[table]!.rows.length - 1; i++) {
      newRows.add(excel.tables[table]!.rows[i]);
    }
    for (var row in newRows) {
      String firstName = row[firstNameClIndex]?.value.toString() ?? "";
      String lastName = row[lastNameClIndex]?.value.toString() ?? "";
      String code = row[codeClIndex]?.value.toString() ?? "";
      String contact = row[contactClIndex]?.value.toString() ?? "";

      Agent agent = Agent(
          code: code,
          firstName: firstName,
          lastName: lastName,
          phone: contact,
          email: "",
          tracking: false,
          site: site,
          categorie: domaine,
          type: type,
          actif: false);
      if (kDebugMode) {
        print(agent.toJson());
      }
      await AgentService().add(agent);
    }
  }
}
