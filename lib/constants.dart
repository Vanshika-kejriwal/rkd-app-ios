import 'package:flutter/material.dart';
// import 'dart:core';

// if(kdebugMode){
//   const String baseuri = 'http://192.168.29.164:8000';
// }else{
//   const String baseuri = 'https://api.rkdistributorvns.com';
// }
// const String baseuri = 'http://192.168.1.8:8000';
const String baseuri = 'https://api.rkdistributorvns.com';
const String searchdevbaseuri = '192.168.1.8:8000'; 
const String searchprodbaseuri = 'api.rkdistributorvns.com';
abstract class SearchableScreen {
  void search();
}

class SearchQueryModel extends ChangeNotifier {
  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void updateSearchQuery(String newQuery) {
    _searchQuery = newQuery;
    notifyListeners();
  }
}
// Stepper(
//         elevation: 0,
//         type: StepperType.horizontal,
//         currentStep: _currentstep,
//         onStepTapped: (value) {
//           setState(() {
//             _currentstep = value;
//           });
//         },
//         onStepContinue: (() {
//           if (_currentstep < 2) {
//             setState(() {
//               _currentstep = _currentstep + 1;
//             });
//           }
//         }),
//         onStepCancel: () {
//           if (_currentstep > 0) {
//             setState(() {
//               _currentstep = _currentstep - 1;
//             });
//           }
//         },
//         steps: [
//           Step(
//               title: const Text("Project"),
//               content: Center(
//                 child: SizedBox(
//                   width: swidth * 0.8,
//                   child: Form(
//                       child: Center(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Project Name",
//                               controller: _pnamecontroller,
//                             ),
//                           ),
//                           Padding(
//                               padding: const EdgeInsets.all(5.0),
//                               child: FutureBuilder<List<String>>(
//                                   future: getcusttype(),
//                                   builder: (context, snapshot) {
//                                     if (snapshot.hasData &&
//                                         snapshot.data != null) {
//                                       return DropdownSearch<String>(
//                                         popupProps: const PopupProps.dialog(
//                                             showSelectedItems: true,
//                                             showSearchBox: true),
//                                         // mode: Mode.dialog,
//                                         // showSelectedItems: true,
//                                         items: snapshot.data!,
//                                         dropdownDecoratorProps:
//                                             const DropDownDecoratorProps(
//                                           dropdownSearchDecoration:
//                                               InputDecoration(
//                                             labelText: "Customer Type",
//                                             hintText: "Select a Customer Type",
//                                           ),
//                                         ),
//                                         // dropdownSearchDecoration: const InputDecoration(
//                                         // labelText: "Menu mode",
//                                         // hintText: "country in menu mode",
//                                         // ),
//                                         // popupItemDisabled: isItemDisabled,
//                                         onChanged: (value) {
//                                           setState(() {
//                                             _selectedut = value;
//                                           });
//                                         },
//                                         selectedItem: _selectedut,
//                                       );
//                                     } else {
//                                       return const Center(
//                                           child: CircularProgressIndicator());
//                                     }
//                                   })),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Contact Person Name",
//                               controller: _namecontroller,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Designation",
//                               controller: _desigcontroller,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Address Line 1",
//                               controller: _add1controller,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Adress Line 2",
//                               controller: _add2controller,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Pin Code",
//                               controller: _pincontroller,
//                               keyboardtype: TextInputType.number,
//                               onChanged: (value) async {
//                                 if (value.length == 6) {
//                                   final response = await http.get(
//                                       Uri.parse('$baseuri/api/loca/$value'));
//                                   if (response.statusCode == 200) {
//                                     final body = json.decode(response.body);
//                                     _statecontroller.text = body["STATE"];
//                                     _citycontroller.text = body["CITY"];
//                                     // print("Pincode doesnt exists");
//                                   } else {
//                                     AwesomeDialog(
//                                       context: context,
//                                       dialogType: DialogType.error,
//                                       animType: AnimType.rightSlide,
//                                       headerAnimationLoop: false,
//                                       title: 'Error',
//                                       desc:
//                                           'Pin Code doesnot exist. Please enter a valid Pin Code.',
//                                       btnOkOnPress: () {},
//                                       btnOkIcon: Icons.cancel,
//                                       btnOkColor: Colors.red,
//                                     ).show();
//                                   }
//                                 }
//                               },
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "State",
//                               controller: _statecontroller,
//                               readOnly: true,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "City",
//                               controller: _citycontroller,
//                               readOnly: true,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "District",
//                               controller: _districtcontroller,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Mobile Number",
//                               controller: _mobilecontroller,
//                               keyboardtype: TextInputType.phone,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Email",
//                               controller: _emailcontroller,
//                               keyboardtype: TextInputType.emailAddress,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "GST Number",
//                               controller: _gstcontroller,
//                             ),
//                           ),
//                           if (_selectedut == "Builder")
//                             Padding(
//                               padding: const EdgeInsets.all(5.0),
//                               child: InputField(
//                                 label: "RERA Number",
//                                 controller: _reracontroller,
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   )),
//                 ),
//               )),
//           Step(
//               title: Text("Product"),
//               content: Center(
//                   child: SizedBox(
//                       width: swidth * 0.8,
//                       child: Center(
//                         child: Form(
//                             child: Center(
//                           child: SingleChildScrollView(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Padding(
//                                     padding: const EdgeInsets.all(5.0),
//                                     child: FutureBuilder<List<String>>(
//                                         future: getproduct(),
//                                         builder: (context, snapshot) {
//                                           if (snapshot.hasData &&
//                                               snapshot.data != null) {
//                                             return DropdownSearch<String>(
//                                               popupProps: const PopupProps.dialog(
//                                                   showSelectedItems: true,
//                                                   showSearchBox: true),
//                                               // mode: Mode.dialog,
//                                               // showSelectedItems: true,
//                                               items: snapshot.data!,
//                                               dropdownDecoratorProps:
//                                                   const DropDownDecoratorProps(
//                                                 dropdownSearchDecoration:
//                                                     InputDecoration(
//                                                   labelText: "Product",
//                                                   hintText: "Select a Product",
//                                                 ),
//                                               ),

//                                               onChanged: (value) {
//                                                 setState(() {
//                                                   _selectedproduct = value;
//                                                 });
//                                               },
//                                               selectedItem: _selectedproduct,
//                                             );
//                                           } else {
//                                             return const Center(
//                                                 child:
//                                                     CircularProgressIndicator());
//                                           }
//                                         })),
//                                 Padding(
//                                     padding: const EdgeInsets.all(5.0),
//                                     child: FutureBuilder<List<String>>(
//                                         future: getcomp(),
//                                         builder: (context, snapshot) {
//                                           if (snapshot.hasData &&
//                                               snapshot.data != null) {
//                                             return DropdownSearch<String>(
//                                               popupProps: const PopupProps.dialog(
//                                                   showSelectedItems: true,
//                                                   showSearchBox: true),
//                                               // mode: Mode.dialog,
//                                               // showSelectedItems: true,
//                                               items: snapshot.data!,
//                                               dropdownDecoratorProps:
//                                                   const DropDownDecoratorProps(
//                                                 dropdownSearchDecoration:
//                                                     InputDecoration(
//                                                   labelText: "Company",
//                                                   hintText: "Select a Company",
//                                                 ),
//                                               ),

//                                               onChanged: (value) {
//                                                 setState(() {
//                                                   _selectedcomp = value;
//                                                 });
//                                               },
//                                               selectedItem: _selectedcomp,
//                                             );
//                                           } else {
//                                             return const Center(
//                                                 child:
//                                                     CircularProgressIndicator());
//                                           }
//                                         })),
//                               ],
//                             ),
//                           ),
//                         )),
//                       )))),
//           Step(
//               title: Text("Follow-up"),
//               content: Center(
//                 child: SizedBox(
//                   child: Form(
//                       child: Center(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(5),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text("Check In"),
//                                 Checkbox(
//                                   activeColor:  Colors.orange[900],
//                                   checkColor: Colors.white,
//                                   value: _followupcheckin,
//                                   onChanged: (value) {
//                                     setState(() {
//                                       _followupcheckin = value!;
//                                     });
//                                     if (_followupcheckin) {
//                                       _checkindatetime = DateFormat("dd/MM/yyyy")
//                                           .add_jm()
//                                           .format(DateTime.now());
//                                       print(_checkindatetime);
//                                     }
//                                   },
//                                 )
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Follow Up Date",
//                               controller: _fudatecontroller,
//                               readOnly: true,
//                               onTap: () {
//                                 _selectfudate();
//                               },
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Follow Up Time",
//                               controller: _futimecontroller,
//                               readOnly: true,
//                               onTap: () {
//                                 _selectfutime();
//                               },
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Comments",
//                               controller: _commentcontroller,
//                               maxlines: 25,
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(5.0),
//                             child: InputField(
//                               label: "Next Follow Up Date",
//                               controller: _nextfudatecontroller,
//                               readOnly: true,
//                               onTap: () {
//                                 _selectnextfudate();
//                               },
//                             ),
//                           ),
//                           Padding(
//                               padding: const EdgeInsets.all(5.0),
//                               child: FutureBuilder<List<String>>(
//                                   future: getcomp(),
//                                   builder: (context, snapshot) {
//                                     if (snapshot.hasData &&
//                                         snapshot.data != null) {
//                                       return DropdownSearch<String>(
//                                         popupProps: const PopupProps.dialog(
//                                             showSelectedItems: true,
//                                             showSearchBox: true),
//                                         // mode: Mode.dialog,
//                                         // showSelectedItems: true,
//                                         items: snapshot.data!,
//                                         dropdownDecoratorProps:
//                                             const DropDownDecoratorProps(
//                                           dropdownSearchDecoration:
//                                               InputDecoration(
//                                             labelText: "Company",
//                                             hintText: "Select a Company",
//                                           ),
//                                         ),

//                                         onChanged: (value) {
//                                           setState(() {
//                                             _selectedfollowupby = value;
//                                           });
//                                         },
//                                         selectedItem: _selectedfollowupby,
//                                       );
//                                     } else {
//                                       return const Center(
//                                           child: CircularProgressIndicator());
//                                     }
//                                   })),
//                           Padding(
//                             padding: const EdgeInsets.all(5),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text("Check Out"),
//                                 Checkbox(
//                                   activeColor:  Colors.orange[900],
//                                   checkColor: Colors.white,
//                                   value: _followupcheckout,
//                                   onChanged: (value) {
//                                     setState(() {
//                                       _followupcheckout = value!;
//                                     });
//                                     if (_followupcheckout) {
//                                       _checkoutdatetime = DateFormat("dd/MM/yyyy")
//                                           .add_jm()
//                                           .format(DateTime.now());
//                                     }
//                                   },
//                                 )
//                               ],
//                             ),
//                           ),
//                           if (_isLoading)
//                       const Center(
//                           child:
//                               CircularProgressIndicator(color: Colors.brown)),
//                             Padding(padding: EdgeInsets.all(5),
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                             backgroundColor:
//                                 const Color.fromRGBO(252, 101, 8, 1),
//                             foregroundColor: Colors.white),
//                         child: const Text("Save Details"),
//                               onPressed:(() {
//                                 setState(() {
//                                   _isLoading = true;
//                                 });
//                                 submitdata();
//                               })
//                       ))],
//                       ),
//                     ),
//                   )),
//                 ),
//               )),
//         ]);
//   }

//   Future<void> _selectfudate() async {
//     DateTime? picked = await showDatePicker(
//         context: context,
//         initialDate: DateTime.now(),
//         firstDate: DateTime(1900),
//         lastDate: DateTime(2100));
//     if (picked != null) {
//       setState(() {
//         _fudatecontroller.text = picked.toString().split(" ")[0];
//       });
//     }
//   }

//   Future<void> _selectnextfudate() async {
//     DateTime? picked = await showDatePicker(
//         context: context,
//         initialDate: DateTime.now(),
//         firstDate: DateTime(1900),
//         lastDate: DateTime(2100));
//     if (picked != null) {
//       setState(() {
//         _nextfudatecontroller.text = picked.toString().split(" ")[0];
//       });
//     }
//   }

//   Future<void> _selectfutime() async {
//     showTimePicker(context: context, initialTime: TimeOfDay.now()).then((time) {
//       _futimecontroller.text = (time?.format(context)).toString();
//     });
//   }
// }
