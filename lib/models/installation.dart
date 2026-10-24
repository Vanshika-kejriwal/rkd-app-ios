class InstallItem {
  final String code;
  final String mc; // Added mc property
  final String leadid; // Added leadid property
  final String name;
  final String subCategoryName;
  final String? id; // Optional id property

  InstallItem({
    required this.code,
    required this.mc,
    required this.leadid,
    required this.name,
    required this.subCategoryName,
    this.id,
  });

  // Generates a combined unique key, e.g., "CODE_MC"
  String get uniqueKey => "${code}_$mc";
 
 List<Map<String, dynamic>> get questions {
    return _productQuestions[subCategoryName.toLowerCase()] ?? [];
  }
}

final Map<String, List<Map<String, dynamic>>> _productQuestions = {
  "electric backup": [
    {"q": "Element Wattage (per Piece)", "type": "text"},
    {"q": "No of elements Installed", "type": "text"},
    
  ],
  "heat pump tank": [
    {"q": "Pre Insulated?", "type": "dropdown"},
    {"q": "Insulation Date", "type": "date"},
    
  ],
  "heat pump": [
    {"q": "Inlet Water Hardness", "type": "text"},
    {
      "q": "Water Temprature Inlet / Outlet",
      "type": "split",
      "labels": ["Inlet", "Outlet"]
    },
    {"q": "Circulation Pump Installed?", "type": "dropdown"},
    {"q": "Return Pump Load Check (Amp)", "type": "text"},
    {
      "q": "Return Pump panel on/off setting",
      "type": "split",
      "labels": ["On Time", "Off Time"]
    },
    {
      "q": "Gas Pressure Suction / Discharge",
      "type": "split",
      "labels": ["Suction", "Discharge"]
    },
    
  ],
  "water treatment": [
    
    {"q": "Water Hardness - Input/Output", "type": "split", "labels": ["Input Hardness", "Output Hardness"]},
    {"q": " Water TDS - Input/Output", "type": "split", "labels": ["Input TDS", "Output TDS"]},
    {"q": "Initial Salt Quantity", "type": "text"},
    {"q": "Flow Rate", "type": "text"},
  ],
  "rfid software": [
    {"q": "Software Installed?", "type": "dropdown"},
    
    {"q": "Software Start Date", "type": "date"},
    {"q": "Software End Date", "type": "date"},
    
  ],
  "pressure tank": [
   
    
    {"q": "Pressure Tank Air Check", "type": "text"},
  
    
  ],
  "pressure pumps": [
    {"q": "Pressure Set", "type": "text"},
    {"q": "Float Switch Installed?", "type": "dropdown"},
    
    {"q": "Panel Callibration Done", "type": "dropdown"},
    {"q": "Running Load (amp)", "type": "text"},
    
  ],
  "other pumps": [
    {"q": "Installed For?", "type": "pump type"},
    {"q": "Callibration Done", "type": "dropdown"},
    {"q": "Running Load (amp)", "type": "text"},
    
  ],
  "smart panel": [
    {"q": "Callibration Done", "type": "dropdown"},
    {"q": "Running Load (amp)", "type": "text"},
     {"q": "On Time Set", "type": "text"},
      {"q": "Off Time Set", "type": "text"},
    
    
    
  ],
  
};