import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path/path.dart' as p;
// import 'package:file_picker/file_picker.dart';

class Pdfview extends StatefulWidget {
  String? type;
  File? file;
  String? ac;
  String? doclink;
  List<String>? mobileNumbers;
  String? sno;

  Pdfview(
      {super.key,
      this.file,
      this.type,
      this.ac,
      this.doclink,
      this.mobileNumbers, this.sno});

  @override
  State<Pdfview> createState() => _PdfviewState();
}

class _PdfviewState extends State<Pdfview> {
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  String? _selectedPhoneNumber;
  final TextEditingController _mobcontroller = TextEditingController();
  late List<TextEditingController> _controllers;

  Future<void> _saveFileToDownloadsStream(
      BuildContext context, File sourceFile) async {
    // 1. Check if the source file exists
    if (!await sourceFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Source file not found.')),
      );
      return;
    }

    // 2. Determine a suggested filename
    String suggestedFileName = p.basename(sourceFile.path);

    try {
      // 3. Trigger the native save dialog using the readStream
      String? path = await FilePicker.saveFile(
        dialogTitle: 'Save PDF Document',
        fileName: suggestedFileName,
        // *** Use readStream instead of bytes ***
        bytes: await sourceFile.readAsBytes(),
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // 4. Check the result and show feedback
      if (path != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF saved successfully'),
              // duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save operation canceled.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving PDF')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final List<String> mobileNumbers = widget.mobileNumbers ?? [];

    // 🎯 CRITICAL CHANGE: Calculate total fields as length + 1
    final int numberOfFields = mobileNumbers.length + 1;

    // 1. Initialize controllers list with the new count
    _controllers = List.generate(
      numberOfFields,
      (index) => TextEditingController(),
    );

    // 2. Pre-populate existing mobile numbers (only up to the original list length)
    for (int i = 0; i < mobileNumbers.length; i++) {
      _controllers[i].text = mobileNumbers[i];
    }

    // The last controller (at index mobileNumbers.length) will remain empty,
    // ready for the user to input the extra number.
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Background(
        appbar: true,
        childs: SfPdfViewer.file(widget.file!),
        appbartitle: Text(widget.file!.path.split('/').last),
        appbaractions: [
          //download btn,
          IconButton(
              onPressed: () =>
                  _saveFileToDownloadsStream(context, widget.file!),
              icon: const Icon(Icons.download)),
          // share btn
          IconButton(
              onPressed: () async {
                // Share.shareFiles([widget.file!.path], text: 'Here is your PDF document.');
                if (await widget.file!.exists() == false) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: File not found.')),
                    );
                  }
                  return;
                }
                var sharedpref = await SharedPreferences.getInstance();
                var ut = sharedpref.getString("UT");
                var name = sharedpref.getString("NAME");
                var sharebymob = sharedpref.getString("Mobile");
                if (ut!.toLowerCase() == "employee" ||
                    ut.toLowerCase() == "admin") {
                  var mob =
                      await openDialog("Send ${widget.type}", "Mobile Number");
                  if (mob != null &&
                      mob.isNotEmpty &&
                      await widget.file!.exists()) {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.loading,
                      title: 'Please wait',
                      text: 'Sharing ${widget.type}...',
                      barrierDismissible: false,
                    );
                    var request = http.MultipartRequest(
                        "POST", Uri.parse('$baseuri/api/sharefile/'));
                    request.fields["AC"] = widget.ac!;
                    request.fields["DOC_LINK"] = widget.doclink ?? "";
                    request.fields["MOBILE"] = mob;
                    request.fields["SHAREDBY"] = "${name!} - ${sharebymob!}";
                    request.fields["TYPE"] = widget.type!;
                    request.fields["SNO"] = widget.sno ?? "";
                    var multipart = await http.MultipartFile.fromPath(
                        "pdf", widget.file!.path,
                        filename: p.basename(widget.file!.path));
                    request.files.add(multipart);
                    final resp = await request.send();
                    if (resp.statusCode == 200) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.success,
                          title: 'Success',
                          text: '${widget.type} shared successfully!',
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'Error',
                          text: 'Failed to share ${widget.type}.',
                        );
                      }
                    }
                  }
                } else {
                  try {
                    SharePlus.instance.share(ShareParams(
                        files: [XFile(widget.file!.path)],
                        text: 'Here is your invoice.'));
                    Future.microtask(() async {
                      // WAIT a much longer, safer duration before attempting the delete.
                      await Future.delayed(const Duration(seconds: 2));

                      try {
                        // Attempt the silent delete.
                        await widget.file!.delete();
                      } on FileSystemException catch (cleanupError) {
                        // 3. SILENTLY CONSUME the errno 39 exception
                        if (cleanupError.osError?.errorCode == 39) {
                          // The cleanup failed again, but we catch it silently.
                          // No print statements here—the goal is silence and continuity.
                        } else {
                          // Log other critical errors to a service like Firebase Crashlytics
                          // instead of printing (for Release Mode).
                        }
                      } catch (_) {
                        // Catch any other unexpected error silently.
                      }
                    });
                  } on FileSystemException catch (e) {
                    // Catch the known cleanup error but do nothing (ignore it)
                    if (e.osError?.errorCode != 39) {
                      // Check for the Directory not empty error code
                      rethrow; // Re-throw other unexpected FileSystemExceptions
                    } else {
                      // print('Warning: Clean-up failed (errno 39 - Directory not empty). Ignoring exception.');
                    }
                  } catch (e) {
                    // Handle other potential exceptions
                    if (kDebugMode) {
                      print('An unexpected error occurred during sharing: $e');
                    }
                  }
                }
              },
              icon: const Icon(Icons.share)),
        ]);
  }

  Future<String?> openDialog(title, lablel) => showDialog(
        // barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use List.generate to create widgets for ALL controllers
              ...List.generate(
                _controllers.length,
                (index) {
                  final controller = _controllers[index];

                  String label = "Mobile #${index + 1}";

                  // Optionally, label the last field differently
                  if (index == _controllers.length - 1) {
                    label = "Add New Mobile";
                  }

                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: InputField(
                      label: label,
                      controller: controller,
                      sufficon: index == _controllers.length - 1
                          ? IconButton(
                              onPressed: () async {
                                Contact? contact =
                                    await _contactPicker.selectPhoneNumber();
                                setState(() {
                                  _selectedPhoneNumber =
                                      contact?.selectedPhoneNumber;
                                  if (_selectedPhoneNumber != null) {
                                    var phno = _selectedPhoneNumber!
                                        .replaceAll(" ", "");
                                    controller.text =
                                        phno.substring(phno.length - 10);
                                    _selectedPhoneNumber = null;
                                  }
                                });
                              },
                              icon: const Icon(Icons.contacts))
                          : IconButton(
                              onPressed: () {
                                // setState(() {
                                controller.clear();
                                // });
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  final List<String> nonEmptyMobiles = _controllers
                      .map((controller) => controller.text
                          .trim()) // Get text and remove whitespace
                      .where(
                          (text) => text.isNotEmpty) // Filter out empty strings
                      .toList();

                  // Join the list into a single comma-separated string to return
                  final String resultString = nonEmptyMobiles.join(',');

                  // Return the joined string
                  // Use resultString if non_empty_mobiles is not empty, otherwise null
                  Navigator.of(context)
                      .pop(resultString.isNotEmpty ? resultString : null);
                },
                child: const Text("SUBMIT"))
          ],
        ),
      );
}
