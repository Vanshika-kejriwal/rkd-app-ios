import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class Saltbilling {
  Saltbilling({required this.ac, required this.name, this.tel1, this.tel2, this.tel3, this.installationDate, this.lastServiceDate, this.lastSaltBillingDate, this.lastSaltBilledQty, this.avgSaltConsumption, this.saltLeftDays});
  final String ac;
  final String name;
  final String? tel1;
  final String? tel2;
  final String? tel3;
  final String? installationDate;
  final String? lastServiceDate;
  final String? lastSaltBillingDate;
  final String? lastSaltBilledQty;
  final String? avgSaltConsumption;
  final String? saltLeftDays;
  

  // Map API JSON map elements cleanly into concrete model property states
  factory Saltbilling.fromJson(Map<String, dynamic> json) {
    return Saltbilling(
      ac: json['AC'] ?? '',
      name: json['NAME'] ?? '',
      tel1: json['TEL1'] ?? '',
      tel2: json['TEL2'] ?? '',
      tel3: json['TEL3'] ?? '',
      installationDate: json['Installation Date'] ?? '',
      lastServiceDate: json['last Service Date'] ?? '',
      lastSaltBillingDate: json['last Salt Billing Date'] ?? '',
      lastSaltBilledQty: json['Last Salt Billed Qty'].toString() ?? '',
      avgSaltConsumption: json['Average Monthly Consumption (kg)'].toString() ?? '',
      saltLeftDays: json['Days Left'].toString() ?? '',
    );
  }
}

class SaltBillDataSource extends DataGridSource {
  SaltBillDataSource({required List<Saltbilling> employeeData}) {
    _updateDataGridRows(employeeData);
  }

  List<DataGridRow> _dataGridRows = [];

  // Updates data in-place and triggers smooth UI redraw without flickering
  void updateData(List<Saltbilling> employeeData) {
    _updateDataGridRows(employeeData);
    notifyListeners();
  }

  void _updateDataGridRows(List<Saltbilling> employeeData) {
    _dataGridRows = employeeData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'AC', value: e.ac.toString() ?? ''),
              DataGridCell<String>(columnName: 'NAME', value: e.name.toString() ?? ''),
              DataGridCell<String>(columnName: 'TEL1', value: e.tel1?.toString() ?? ''),
              DataGridCell<String>(columnName: 'TEL2', value: e.tel2?.toString() ?? ''),
              DataGridCell<String>(columnName: 'TEL3', value: e.tel3?.toString() ?? ''),
              DataGridCell<String>(columnName: 'Installation Date', value: e.installationDate?.toString() ?? ''),
              DataGridCell<String>(columnName: 'Last Service Date', value: e.lastServiceDate?.toString() ?? ''),
              DataGridCell<String>(columnName: 'Last Salt Billing Date', value: e.lastSaltBillingDate?.toString() ?? ''),
              DataGridCell<String>(columnName: 'Last Salt Billed Qty', value: e.lastSaltBilledQty?.toString() ?? ''),
              DataGridCell<String>(columnName: 'Average Monthly Consumption (kg)', value: e.avgSaltConsumption?.toString() ?? ''),
              DataGridCell<String>(columnName: 'Days Left', value: e.saltLeftDays?.toString() ?? ''),
            ]))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        if (e.columnName == 'AC') {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(8.0),
            child: Text(e.value.toString()),
          );
        }
        if (e.columnName == 'NAME') {
          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(8.0),
            child: Text(e.value.toString()),
          );
        }
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Text(e.value.toString()),
        );
      }).toList(),
    );
  }
}

