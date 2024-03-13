import 'dart:async';

import 'package:file_selector_web/file_selector_web.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:spas_web/services/loading.dart';
import 'package:transparent_image/transparent_image.dart';

/// Enum representing the upload task types the example app supports.
enum UploadType {
  /// Uploads a randomly generated string (as a file) to Storage.
  string,

  /// Uploads a file from the device.
  file,

  /// Clears any tasks from the list.
  clear,
}

class UploadTaskManager extends StatefulWidget {
  // ignore: public_member_api_docs
  UploadTaskManager(
      {Key? key,
      required this.onUploaded,
      required this.ref,
      required this.onSelected})
      : super(key: key);
  Function(String link) onUploaded;
  Function(String extention) onSelected;
  String ref;
  @override
  State<StatefulWidget> createState() {
    return _TaskManager();
  }
}
// variable to hold image to be displayed

//method to load image and update `uploadedImage`

class _TaskManager extends State<UploadTaskManager> {
  /// The user selects a file, and the task is added to the list.
  UploadTask? _task;
  String _downlink = "";
  bool _uploaded = false;
  Future<UploadTask?> uploadFile() async {
    //final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    FileSelectorWeb fsw = FileSelectorWeb();
    var xfile = await fsw.openFile();
    if (xfile == null) {
      return null;
    }

    UploadTask uploadTask;

    // Create a Reference to the file
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(widget.ref)
        .child('/${xfile.name}');

    widget.onSelected(xfile.name.split(".").last);
    /* final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': file.path},
    );*/

    uploadTask = ref.putData(await xfile.readAsBytes());

    return Future.value(uploadTask);
  }

  Future<void> _downloadLink(Reference ref) async {
    _downlink = await ref.getDownloadURL();
    widget.onUploaded(_downlink);
    setState(() {});
  }

  Future<void> _delete(Reference ref) async {
    await ref.delete();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: [
        _task == null
            ? const SizedBox.shrink()
            : StreamBuilder(
                stream: _task?.snapshotEvents,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    switch (snapshot.data?.state) {
                      case null:
                        return const SizedBox.shrink();
                      case TaskState.paused:
                        return const SizedBox.shrink();
                      case TaskState.running:
                        return Loading(size: 64, inline: true);
                      case TaskState.success:
                        _downloadLink(snapshot.data!.ref);
                        _uploaded = true;
                        //return const SizedBox.shrink();
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text("Document chargé!",
                                textAlign: TextAlign.center),
                          ),
                        );
                        return FadeInImage.memoryNetwork(
                            fit: BoxFit.cover,
                            placeholder: kTransparentImage,
                            image: _downlink);

                      case TaskState.canceled:
                        return const SizedBox.shrink();
                      case TaskState.error:
                        return Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.white),
                        );
                    }
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
        const SizedBox(
          height: 10,
        ),
        _uploaded
            ? const SizedBox.shrink()
            : TextButton(
                style: TextButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.5)),
                onPressed: () async {
                  _task = await uploadFile();

                  setState(() {});
                },
                child: const Text(
                  "Ajouter un fichier",
                  style: TextStyle(color: Colors.white),
                )),
      ],
    );
  }
}
