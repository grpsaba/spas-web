import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/models/menu_item_model.dart';

class DrawerMenuConfigService {
  DrawerMenuConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'app_config';
  static const String documentId = 'global';
  static const String drawerMenuItemsField = 'drawerMenuItems';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _documentReference =>
      _firestore.collection(collectionName).doc(documentId);

  Stream<DrawerMenuConfig> watchConfig() {
    return _documentReference.snapshots().map((snapshot) {
      return DrawerMenuConfig.fromJson(snapshot.data() ?? <String, dynamic>{});
    });
  }

  Future<DrawerMenuConfig> getConfig() async {
    final snapshot = await _documentReference.get();
    return DrawerMenuConfig.fromJson(snapshot.data() ?? <String, dynamic>{});
  }

  Future<void> saveEnabledByKey(Map<String, bool> enabledByKey) async {
    await _documentReference.set(
      <String, dynamic>{
        drawerMenuItemsField: Map<String, bool>.from(enabledByKey),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _deleteLegacyDottedFields();
  }

  Future<void> _deleteLegacyDottedFields() async {
    final updates = <Object, Object?>{};

    for (final item in MenuItemModel.menuItems) {
      updates[FieldPath(['$drawerMenuItemsField.${item.configKey}'])] =
          FieldValue.delete();
    }

    if (updates.isNotEmpty) {
      await _documentReference.update(updates);
    }
  }
}

class DrawerMenuConfig {
  const DrawerMenuConfig({required this.enabledByKey});

  const DrawerMenuConfig.defaults() : enabledByKey = const <String, bool>{};

  final Map<String, bool> enabledByKey;

  factory DrawerMenuConfig.fromJson(Map<String, dynamic> json) {
    final rawItems = json[DrawerMenuConfigService.drawerMenuItemsField];
    final items = <String, bool>{};

    if (rawItems is Map) {
      rawItems.forEach((key, value) {
        if (value is bool) {
          items[key.toString()] = value;
        }
      });
    }

    return DrawerMenuConfig(enabledByKey: items);
  }

  bool isEnabled(MenuItemModel item) {
    return enabledByKey[item.configKey] ?? true;
  }
}
