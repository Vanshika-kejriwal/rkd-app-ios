import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class TransportForm extends StatefulWidget {
  final List<PendingTransport> selectedInvoices;
  const TransportForm({super.key, required this.selectedInvoices});

  @override
  State<TransportForm> createState() => _TransportFormState();
}

class _TransportFormState extends State<TransportForm> {
  bool _isloading = false;
  late TextEditingController _tnameAddController;
  late TextEditingController _tmobAddController;
  String? selectedtname;
  String? selectedtmobile;
  late Future<List<String>> _namelist;
  final List<String> _tmobile = [];
  late TextEditingController _biltydateController;
  late TextEditingController _biltynumberController;
  File? _biltyImage; // Single image
  final List<File> _goodsImages = []; // Up to 3 images

  final ImagePicker _picker = ImagePicker();
  final int _maxGoodsImages = 3;

  Future<List<String>> gettname() async {
    var resp = await http.get(Uri.parse(
        '$baseuri/api/gettname/?deltype=${widget.selectedInvoices.first.deltype}'));
    if (resp.statusCode == 200) {
      List<dynamic> data = jsonDecode(resp.body);
      return data.map((item) => item['Name'] as String).toList();
    } else {
      throw Exception('Failed to load transport names');
    }
  }

  Future<List<String>> gettmobile() async {
    var resp = await http
        .get(Uri.parse('$baseuri/api/gettmobile/?tname=$selectedtname'));
    if (resp.statusCode == 200) {
      List<dynamic> data = jsonDecode(resp.body);
      return data.map((item) => item['Mobile'] as String).toList();
    } else {
      throw Exception('Failed to load transport mobile numbers');
    }
  }

  @override
  void initState() {
    super.initState();
    _tnameAddController = TextEditingController();
    _tmobAddController = TextEditingController();
    _biltydateController = TextEditingController();
    _biltynumberController = TextEditingController();
    _namelist = gettname();
  }

  _showoptionsbottomsheet(BuildContext context, {String fieldType = 'bilty'}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  // Implement camera functionality here
                  _pickImage(ImageSource.camera, fieldType);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  // Implement gallery functionality here
                  _pickImage(ImageSource.gallery, fieldType);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, String fieldType) async {
    try {
      if (fieldType == 'bilty') {
        // --- BILTY LOGIC (Single Image Only) ---
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _biltyImage = File(pickedFile.path);
          });
        }
      } else if (fieldType == 'goods') {
        // --- GOODS PICS LOGIC (Max 3 Images) ---
        if (source == ImageSource.camera) {
          if (_goodsImages.length >= _maxGoodsImages) {
            _showMaxLimitAlert();
            return;
          }

          final XFile? pickedFile = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );

          if (pickedFile != null) {
            setState(() {
              _goodsImages.add(File(pickedFile.path));
            });
          }
        } else {
          // Multi-image selection from Gallery
          final List<XFile> pickedFiles = await _picker.pickMultiImage(
            imageQuality: 80,
          );

          if (pickedFiles.isNotEmpty) {
            int availableSlots = _maxGoodsImages - _goodsImages.length;

            if (pickedFiles.length > availableSlots) {
              _showMaxLimitAlert();
              setState(() {
                _goodsImages.addAll(
                  pickedFiles
                      .take(availableSlots)
                      .map((xFile) => File(xFile.path)),
                );
              });
            } else {
              setState(() {
                _goodsImages.addAll(
                  pickedFiles.map((xFile) => File(xFile.path)),
                );
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showMaxLimitAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Maximum Limit Reached"),
          content: const Text("You can only upload up to 3 goods images."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      childs: SafeArea(
          child: Center(
              child: SizedBox(
                  child: Form(
                      child: Center(
                          child: SingleChildScrollView(
                              child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: FutureBuilder<List<String>>(
              future: _namelist,
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (asyncSnapshot.hasError) {
                  return Text('Error: ${asyncSnapshot.error}');
                } else if (!asyncSnapshot.hasData ||
                    asyncSnapshot.data!.isEmpty) {
                  return const Text('No transport names available');
                }
                return DropdownSearch<String>(
                  items: (filter, loadProps) => asyncSnapshot.data!,
                  selectedItem: selectedtname,
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: 'Select or Add Transport Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: PopupProps.dialog(
                    showSearchBox: true,
                    dialogProps: const DialogProps(
                      barrierDismissible: true,
                      barrierLabel:
                          "Dismiss", // Allows tapping outside to dismiss
                    ),
                    // Add a custom widget at the bottom of the popup for adding new items
                    containerBuilder: (ctx, popupWidget) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _tnameAddController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add new item...',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    final newItem =
                                        _tnameAddController.text.trim();
                                    if (newItem.isNotEmpty &&
                                        !asyncSnapshot.data!
                                            .contains(newItem)) {
                                      setState(() {
                                        asyncSnapshot.data!.add(newItem);
                                        selectedtname = newItem;
                                      });
                                      _tnameAddController.clear();
                                      // Close the popup/menu
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Flexible(child: popupWidget),
                        ],
                      );
                    },
                  ),
                  onSelected: (value) {
                    setState(() {
                      selectedtname = value;
                    });
                    gettmobile().then((mobile) {
                      setState(() {
                        selectedtmobile = mobile.isEmpty ? null : mobile.first;
                      });
                    });
                  },
                );
              }),
        ),
        Padding(
            padding: const EdgeInsets.all(5.0),
            child: DropdownSearch<String>(
              items: (filter, loadProps) => _tmobile,
              selectedItem: selectedtmobile,
              decoratorProps: const DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: 'Select or Add Transport Mobile Number',
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: PopupProps.dialog(
                showSearchBox: true,
                dialogProps: const DialogProps(
                  barrierDismissible: true,
                  barrierLabel: "Dismiss", // Allows tapping outside to dismiss
                ),
                // Add a custom widget at the bottom of the popup for adding new items
                containerBuilder: (ctx, popupWidget) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _tmobAddController,
                                decoration: const InputDecoration(
                                  hintText: 'Add new item...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final newItem = _tmobAddController.text.trim();
                                if (newItem.isNotEmpty &&
                                    !_tmobile.contains(newItem)) {
                                  setState(() {
                                    _tmobile.add(newItem);
                                    selectedtmobile = newItem;
                                  });
                                  _tmobAddController.clear();
                                  // Close the popup/menu
                                  Navigator.pop(ctx);
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(child: popupWidget),
                    ],
                  );
                },
              ),
              onSelected: (value) {
                setState(() {
                  selectedtmobile = value;
                });
              },
            )),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
              label: "Bilty Number", controller: _biltynumberController),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
            label: "Bilty Date",
            controller: _biltydateController,
            readOnly: true,
            onTap: () => showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            ).then((date) {
              if (date != null) {
                setState(() {
                  _biltydateController.text =
                      DateFormat('dd/MM/yyyy').format(date);
                });
              }
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
            label: "Upload Bilty",
            readOnly: true,
            onTap: () {
              // Implement file picker logic here
              _showoptionsbottomsheet(context, fieldType: 'bilty');
            },
          ),
        ),
        _biltyImage != null
            ? Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.file(
                  _biltyImage!,
                  height: 150,
                ),
              )
            : const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
            label: "Upload Goods Pics (Max 3)",
            readOnly: true,
            onTap: () {
              // Implement file picker logic here
              _showoptionsbottomsheet(context, fieldType: 'goods');
            },
          ),
        ),
        _goodsImages.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(5.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _goodsImages.map((image) {
                    return Stack(
                      children: [
                        Image.file(
                          image,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _goodsImages.remove(image);
                              });
                            },
                            child: Container(
                              color: Colors.black54,
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              )
            : const SizedBox.shrink(),
        if (_isloading) Center(child: const CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(252, 101, 8, 1),
                                  foregroundColor: Colors.white),
              onPressed:_isloading? null: () async {
                setState(() {
                  _isloading = true;
                });

                var url = Uri.parse('$baseuri/api/updatepickup/');
                var request = http.MultipartRequest("POST", url);

                // 1. Add Text Fields
                request.fields["Pickup_no"] =
                    widget.selectedInvoices.first.pickupno;
                request.fields["tname"] = selectedtname!;
                request.fields["tmobile"] = selectedtmobile!;
                request.fields["biltynumber"] = _biltynumberController.text;
                request.fields["biltydate"] = _biltydateController.text;

                // 2. Attach single Bilty Image file
                if (_biltyImage != null) {
                  request.files.add(await http.MultipartFile.fromPath(
                    'biltyimage', // Backend field name matching request.FILES
                    _biltyImage!.path,
                    filename: path.basename(_biltyImage!.path),
                  ));
                }

                // 3. Attach Multiple Goods Pictures into an array
                for (var i = 0; i < _goodsImages.length; i++) {
                  request.files.add(await http.MultipartFile.fromPath(
                    'goodsimages', // Keep key name identical; Django will read it as a list
                    _goodsImages[i].path,
                    filename: path.basename(_goodsImages[i].path),
                  ));
                }

                // 4. Fire Request
                try {
                  var streamedResponse = await request.send();
                  var response =
                      await http.Response.fromStream(streamedResponse);

                  // if (response.statusCode == 202) {
                  //   print("Upload queued successfully!");
                  // } else {
                  //   print("Upload failed: ${response.body}");
                  // }
                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
                    if (mounted) {
                      setState(() {
                        _isloading = false;
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Data saved successfully"),
                        backgroundColor: Colors.green[400]));
                    Navigator.pop(context);
                  } else {
                    if (mounted) {
                      setState(() {
                        _isloading = false;
                      });
                    }
                    if (kDebugMode) {
                      print("Upload failed: ${response.body}");
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Something Went Wrong"),
                        backgroundColor: Colors.red));
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print("Network Error: $e");
                  }
                }

                // if (response.statusCode == 200 || response.statusCode == 201) {
                //   if (mounted) {
                //     setState(() {
                //       _isloading = false;
                //     });
                //   }
                //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //       content: const Text("Data saved successfully"),
                //       backgroundColor: Colors.green[400]));
                //   Navigator.pop(context);
                // } else {
                //   if (mounted) {
                //     setState(() {
                //       _isloading = false;
                //     });
                //   }
                //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //       content: const Text("Something Went Wrong"),
                //       backgroundColor: Colors.red));
                // }
              },
              child: Text("Save Detail")),
        )
      ]))))))),
      appbar: true,
      appbartitle: Text("Goods Pickup Form"),
      appbaractions: [],
    );
  }
}
