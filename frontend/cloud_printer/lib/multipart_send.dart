import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

//void pickFileAndMultipartSend(String? ipAddress) async {
//	FilePickerResult? result = await FilePicker.platform.pickFiles();
//
//	if (result != null) {
//		File file = File(result.files.single.path!);
//		await multipartSend(file.path, ipAddress);
//	} else {
//		//print("User cancelled File Picker!");
//	}
//}

Future<int> multipartSend(String filePath, String? ipAddress, String printerName) async {
	//var uri = Uri.http('127.0.0.1:3000', '/print');
	var uri = Uri.http('$ipAddress:3000', '/print');
	var request = http.MultipartRequest('POST', uri)
    ..headers.addAll({"printer": printerName})
		..files.add(await http.MultipartFile.fromPath(
			'document', filePath
		));
	var response = await request.send();
  return response.statusCode;
	//if (response.statusCode == 200) print("Uploaded!");
}

Future<List<dynamic>> fetchPrinterList(String? ipAddress) async {
  final response = await http.get(
    Uri.parse("http://$ipAddress:3000/printers")
  );

  if (response.statusCode == 200) {
    List<dynamic> printerList = jsonDecode(response.body)["printers"];
    return printerList; 
  }

  return [];
}

void selectPrinter({required String printer, required String ipAddress}) async {
  final response = await http.post(
    Uri.parse("http://$ipAddress:3000/printers"),
    headers: <String, String> {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: printer,
  );

  print(response.body);
}