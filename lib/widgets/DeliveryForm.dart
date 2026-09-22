import 'dart:convert';
import 'dart:io';

import 'package:business_app/constants.dart';
import 'package:business_app/models/utils.dart';
import 'package:business_app/widgets/background.dart';
import 'package:business_app/widgets/input_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class DeliveryForm extends StatefulWidget {
  final List<PendingTransport> selectedInvoices;
  const DeliveryForm({super.key, required this.selectedInvoices});

  @override
  State<DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<DeliveryForm> {
  final TextEditingController _otpController = TextEditingController();
  bool _isloading = false;
  final ImagePicker _picker = ImagePicker();
  final int _maxGoodsImages = 3;
  final List<File> _goodsImages = [];
  File? _delrecImage;
  String? _taskid;
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  bool _openotpfield = false;
  String? selectedtname;
  String? selectedtmobile;
  Future<List<String>>? _namelist;
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  String? _selectedPhoneNumber;
  final TextEditingController _nameAddController = TextEditingController();

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
      if (fieldType == 'delrec') {
        // --- BILTY LOGIC (Single Image Only) ---
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _delrecImage = File(pickedFile.path);
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

  Future<List<String>> getDeliveryNames() async {
    try {
      var response = await http.get(Uri.parse(
          '$baseuri/api/getdeliverynames/?pickup_no=${widget.selectedInvoices.first.pickupno}'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item['DELTON'] as String).toList();
      } else {
        throw Exception('Failed to load delivery names');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching delivery names: $e");
      }
      return [];
    }
  }

  Future<String> gettmobile() async {
    try {
      var response = await http.get(Uri.parse(
          '$baseuri/api/getdelmobile/?delton=${selectedtname ?? ''}'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first['DELTOM'] as String;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching mobile number: $e");
      }
    }
    return '';
  }

  @override
  initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _namelist = getDeliveryNames();
    if (widget.selectedInvoices[0].extramob != null) {
      _mobileController.text = widget.selectedInvoices[0].extramob!;
    }
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
                                if (widget.selectedInvoices.isNotEmpty) // Adjust variable name based on your single item property
        Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Selected Delivery Details:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200, // Limits height and allows scrolling if content is large
                ),
                child: SingleChildScrollView(
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    elevation: 0,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name (Bold)
                          Text(
                            widget.selectedInvoices[0].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // City and Delivery Type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Invoices: ${widget.selectedInvoices[0].invoices}",
                                style: const TextStyle(fontSize: 12, color: Colors.black),
                              ),
                              Text(
                                "Type: ${widget.selectedInvoices[0].deltype ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.selectedInvoices.first.deltype == "By Hand")
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
        if (widget.selectedInvoices.first.deltype == "By Hand")
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
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
            label: "Upload Delivery Receiving",
            readOnly: true,
            onTap: () {
              // Implement file picker logic here
              _showoptionsbottomsheet(context, fieldType: 'delrec');
            },
          ),
        ),
        _delrecImage != null
            ? Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.file(
                  _delrecImage!,
                  height: 150,
                ),
              )
            : const SizedBox.shrink(),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: FutureBuilder<List<String>>(
              future: _namelist,
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (asyncSnapshot.hasError) {
                  return Text('Error: ${asyncSnapshot.error}');
                }

                return DropdownSearch<String>(
                  items: (filter, loadProps) => asyncSnapshot.data!,
                  selectedItem: selectedtname,
                  decoratorProps: const DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: 'Select or Add Delivery To Name',
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
                                    controller: _nameAddController,
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
                                        _nameAddController.text.trim();
                                    if (newItem.isNotEmpty &&
                                        !asyncSnapshot.data!
                                            .contains(newItem)) {
                                      setState(() {
                                        asyncSnapshot.data!.add(newItem);
                                        selectedtname = newItem;
                                      });
                                      _nameAddController.clear();
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
                        _mobileController.text = mobile;
                      });
                    });
                  },
                );
              }),
        ),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: InputField(
            label: "Mobile Number",
            keyboardtype: TextInputType.phone,
            controller: _mobileController,
            sufficon: IconButton(
                onPressed: () async {
                  Contact? contact = await _contactPicker.selectPhoneNumber();
                  setState(() {
                    _selectedPhoneNumber = contact?.selectedPhoneNumber;
                    if (_selectedPhoneNumber != null) {
                      var phno = _selectedPhoneNumber!.replaceAll(" ", "");
                      _mobileController.text = phno.substring(phno.length - 10);
                      _selectedPhoneNumber = null;
                    }
                  });
                },
                icon: const Icon(Icons.contacts)),
          ),
        ),
        if (_isloading) Center(child: const CircularProgressIndicator()),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                  foregroundColor: Colors.white),
              onPressed:_isloading? null: () async {
                setState(() {
                  _isloading = true;
                });

                var url = Uri.parse('$baseuri/api/updatedelivery/');
                var request = http.MultipartRequest("POST", url);

                // 1. Add Text Fields
                request.fields["Pickup_no"] =
                    widget.selectedInvoices.first.pickupno;
                request.fields["name"] = selectedtname ?? '';
                request.fields["mobile"] = _mobileController.text;

                // 2. Attach single Delivery Receipt Image file
                if (_delrecImage != null) {
                  request.files.add(await http.MultipartFile.fromPath(
                    'delrecimage', // Backend field name matching request.FILES
                    _delrecImage!.path,
                    filename: path.basename(_delrecImage!.path),
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
                  var body = json.decode(response.body);
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
                        _openotpfield = true;
                        _taskid = body['task_id'];
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Data saved successfully"),
                        backgroundColor: Colors.green[400]));
                    // Navigator.pop(context);
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
                  print("Network Error: $e");
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
              child: Text("Save and send OTP")),
        ),
        if (_openotpfield)
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: InputField(label: "Enter OTP", controller: _otpController),
          ),
        if (_openotpfield)
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(252, 101, 8, 1),
                    foregroundColor: Colors.white),
                onPressed:_isloading? null: () async {
                  setState(() {
                    _isloading = true;
                  });

                  // 2. Fire Request
                  try {
                    var response = await http.patch(
                      Uri.parse('$baseuri/api/updatedelivery/'),
                      body: {
                        "Pickup_no": widget.selectedInvoices.first.pickupno,
                        "mobile": _mobileController.text,
                        "otp": _otpController.text,
                        "task_id": _taskid
                      },
                    );

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      if (mounted) {
                        setState(() {
                          _isloading = false;
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("OTP verified successfully"),
                          backgroundColor: Colors.green[400]));
                      Navigator.pop(context);
                    } else {
                      if (mounted) {
                        setState(() {
                          _isloading = false;
                        });
                      }
                      if (kDebugMode) {
                        print("OTP verification failed: ${response.body}");
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("Invalid OTP"),
                          backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print("Network Error: $e");
                    }
                  }
                },
                child: Text("Verify OTP")),
          ),
      ]))))))),
      appbar: true,
      appbartitle: Text("Goods Delivery Form"),
      appbaractions: [],
    );
  }
}
