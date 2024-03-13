import 'package:spas_web/generated/assets.dart';

class ExtentionLogo {
  final List<String> imageExtention = [
    "jpeg",
    "jpg",
    "png",
    "gif",
    "tif",
    "psd"
  ];
  final List<String> pdfExtention = [
    "pdf",
  ];
  String getLogo({required String extention}) {
    String ext = extention.toLowerCase();
    if (imageExtention
            .indexWhere((element) => element.toLowerCase().contains(ext)) !=
        -1) {
      return Assets.assetsImageLogo;
    } else {
      if (pdfExtention
              .indexWhere((element) => element.toLowerCase().contains(ext)) !=
          -1) {
        return Assets.assetsPdfLogo;
      } else {
        return Assets.assetsFileLogo;
      }
    }
  }
}
