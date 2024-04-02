import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void pickFileAndMultipartSend() async {
	FilePickerResult? result = await FilePicker.platform.pickFiles();

	if (result != null) {
		File file = File(result.files.single.path!);
		await multipartSend(file.path);
	} else {
		print("User cancelled File Picker!");
	}
}

Future<void> multipartSend(String filePath) async {
	//var uri = Uri.http('127.0.0.1:3000', '/print');
	var uri = Uri.http('192.168.220.55:3000', '/print');
	var request = http.MultipartRequest('POST', uri)
		..files.add(await http.MultipartFile.fromPath(
			'document', filePath
		));
	var response = await request.send();
	if (response.statusCode == 200) print("Uploaded!");
}