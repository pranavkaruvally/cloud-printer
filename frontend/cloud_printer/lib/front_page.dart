import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_printer/expandable_fab.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'package:cloud_printer/multipart_send.dart';


class FrontPage extends StatefulWidget {
	const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  int _color = 0xff9bdae6;
  String currentTitle = "Medical Documents";
  List<String> _pictures = [], addresses = [];
  String? ipAddress = "";

  List<String> medicalDocuments = [];
  List<String> educationalDocuments = [];
  List<String> vehicleDocuments = [];
  List<String> personalDocuments = [];
  List<String> otherDocuments = [];

  Map<String, List<String>> nameToDir = {
      "Medical Documents": [],
      "Educational Documents": [],
      "Vehicle Documents": [],
      "Personal Documents": [],
      "Other Documents": [],
  };

  @override
  void initState() {
    super.initState();
    nameToDir = {
      "Medical Documents": medicalDocuments,
      "Educational Documents": educationalDocuments,
      "Vehicle Documents": vehicleDocuments,
      "Personal Documents": personalDocuments,
      "Other Documents": otherDocuments,
    };
    loadDocumentsDirectory();
  }

	Widget miniFolder({String title="Folder name", int color = 0xff9bdae6}) {
			return GestureDetector(
				onTap: () {
          setState(() {
            _color = color;
            currentTitle = title;
          });
        },

				child: Container(
				  margin: const EdgeInsets.only(left: 10.0, right: 10, top: 50, bottom: 50),
				  height: 200,
				  width: 200,
				  decoration: BoxDecoration(
				    borderRadius: BorderRadius.circular(20),
				    color: Color(color),
				  ),
				child: SizedBox(
                  //constraints: const BoxConstraints(
                   height: 200,
                   width: 200,
                  //),
                  child: Stack(
                    children: [
                      Align(
                        alignment: const Alignment(-0.99, -0.9),
                        child: Container(
                          margin: const EdgeInsets.all(15),
                          child: const Icon(
                            Icons.folder,	
                            color: Color.fromARGB(255, 32, 33, 32),
                            size: 22.0,
                          ),
                        )
                      ),
                      Align(
                        alignment: const Alignment(-0.99, -0.2),
                        child: Container(
                          margin: const EdgeInsets.all(15),
                          child: Text(title,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 32, 33, 32),
                              fontSize: 18,
                              fontWeight: FontWeight.w700
                            ),
                          ),
                        )
                      ),
                    ]
                  ),
                ),
				),
			);
	}

	Widget miniFolderList(BuildContext context) {
          return Container(
                    //height: MediaQuery.of(context).size.height * 0.45,
                    padding: const EdgeInsets.only(bottom: 100),
                    decoration: const BoxDecoration(
                      color: Color(0xff212120),
                    ), 
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      children: [
                        miniFolder(title: "Medical Documents", color: 0xff9bdae6),
                            miniFolder(title: "Educational Documents", color: 0xffa6ebd0),
                            miniFolder(title: "Vehicle Documents", color: 0xfff9e6b5),
                            miniFolder(title: "Personal Documents", color: 0xffebd1de),
                            miniFolder(title: "Other Documents", color: 0xffedebe2),
                            
                      ]
                    ),
        );
	}

  Widget fileTile({required String fileName, bool addNew=false}) {
    String modifiedFileName = basename(fileName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: (addNew == false) 
          ? <Widget> [
              const Icon(
                size: 60,
                Icons.picture_as_pdf
              ),
              Text(modifiedFileName, overflow: TextOverflow.ellipsis),
          ]
          : <Widget> [
              const Icon(
                size: 60,
                Icons.add,
              ),
              const Text("New"),
          ],
      )
    );
  }

	@override
	Widget build(BuildContext context) {
		return Scaffold(
          floatingActionButton: ExpandableFab(
            distance: 112,
            children: [
              ActionButton(
                onPressed: () => openPdfAndPrint(ipAddress),
                icon: const Icon(Icons.file_open),
              ),

              ActionButton(
                onPressed: loadDocumentsDirectory,
                icon: const Icon(Icons.file_download),
              ),

              ActionButton(
                onPressed: () { 
                  shakeHandWithServer(ipAddress);
                }
                ,
                icon: const Icon(Icons.insert_photo),
              ),

              if (Platform.isAndroid)
                ActionButton(
                  onPressed: takePictureAndMakePdf,
                  icon: const Icon(Icons.camera),
                ),
            ]
          ),
          backgroundColor: Color(_color),
      		body: Stack(
      		  children: [
      		    SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: ClipPath(
                  clipper: FolderClipper(),
                  child: miniFolderList(context)
                ),
              ),
              //if (otherDocuments.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: (nameToDir[currentTitle]?.length)! + 1,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        if (index < nameToDir[currentTitle]!.length) {
                          return fileTile(fileName: nameToDir[currentTitle]![index]);
                        } else {
                          return fileTile(fileName: "Add", addNew: true);
                        }
                      },
                    ),
                  )
                ),
      		  ],
      		),
    	);
	}

  void shakeHandWithServer(String? ipAddress) async {
    final info = NetworkInfo();
    String ipAddress = await info.getWifiBroadcast() ?? "";

    if (ipAddress == "") {
      print("Error: broadcast ip unassigned");
    }
    var destinationAddress = InternetAddress(ipAddress.toString());

    RawDatagramSocket.bind(InternetAddress.anyIPv4, 3000).then(
      (RawDatagramSocket udpSocket) {
        udpSocket.broadcastEnabled = true;
        udpSocket.listen((e) {
          Datagram? dg = udpSocket.receive();

          if (dg != null) {
            print("received from address: ${dg.address.address}");
            addresses.add(dg.address.address);
          }
        }); 

        List<int> data = utf8.encode('TEST');
        udpSocket.send(data, destinationAddress, 3000);
      });
  }

  void openPdfAndPrint(String? ipAddress) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowedExtensions: ['pdf']);
    
    if (addresses.isNotEmpty) {
      ipAddress = addresses[0];
    }

    if (result != null) {
      multipartSend(result.files.single.path!, ipAddress);  
    }
  }


  void loadDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();

    final medicalDocumentsFolder = Directory("${appDir.path}/Cloud Printer/Medical Documents");
    final educationalDocumentsFolder = Directory("${appDir.path}/Cloud Printer/Educational Documents");
    final vehicleDocumentsFolder = Directory("${appDir.path}/Cloud Printer/Vehicle Documents");
    final personalDocumentsFolder = Directory("${appDir.path}/Cloud Printer/Personal Documents");
    final otherDocumentsFolder = Directory("${appDir.path}/Cloud Printer/Other Documents");


    if (!(await medicalDocumentsFolder.exists())) {
      await medicalDocumentsFolder.create(recursive: true);
      await educationalDocumentsFolder.create(recursive: true);
      await vehicleDocumentsFolder.create(recursive: true);
      await personalDocumentsFolder.create(recursive: true);
      await otherDocumentsFolder.create(recursive: true);
    }

    await for (var doc in medicalDocumentsFolder.list(recursive: true, followLinks: false)) {
      medicalDocuments.add(doc.path);
    }

    await for (var doc in educationalDocumentsFolder.list(recursive: true, followLinks: false)) {
      educationalDocuments.add(doc.path);
    }

    await for (var doc in vehicleDocumentsFolder.list(recursive: true, followLinks: false)) {
      vehicleDocuments.add(doc.path);
    }

    await for (var doc in personalDocumentsFolder.list(recursive: true, followLinks: false)) {
      personalDocuments.add(doc.path);
    }

    await for (var doc in otherDocumentsFolder.list(recursive: true, followLinks: false)) {
      otherDocuments.add(doc.path);
    }

    print("MD: $medicalDocuments");
    print("ED: $educationalDocuments");
    print("VD: $vehicleDocuments");
    print("PD: $personalDocuments");
    print("OD: $otherDocuments");

    setState(() {});
  }

  void takePictureAndMakePdf() async {
      List<String> pictures;

      try {
        pictures = await CunningDocumentScanner.getPictures(isGalleryImportAllowed: true) ?? [];
        if (!mounted) return;
        setState(() {
          _pictures = pictures;
        });
      } catch (exception) {
        print("Exception caught!");
      } 

      if (_pictures.isNotEmpty) {
        final pdf = pw.Document();

        for (String picture in _pictures) {
          final image = pw.MemoryImage(
            File(picture).readAsBytesSync()
          );

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context pcontext) {
                return pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Image(image)
                );
              }
            )
          );
        }

          final output = await getTemporaryDirectory();
          final file = File("${output.path}/${DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecond)}");
          await file.writeAsBytes(await pdf.save());

          multipartSend(file.path, ipAddress);
      }
  }
}

class FolderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, 0.90*size.height);
    path.quadraticBezierTo(0.025*size.width, 0.80*size.height, 0.08*size.width, 0.80*size.height);
    path.lineTo(0.30 * size.width, 0.80 * size.height);
    //path.quadraticBezierTo(0.40*size.width, 0.80*size.height, 0.45*size.width, 0.96*size.height);
    path.cubicTo(0.35*size.width, 0.80*size.height, 0.405*size.width, 0.92*size.height, 0.46*size.width, 0.94*size.height);
    path.lineTo(0.93*size.width, 0.94*size.height);
    path.cubicTo(0.97*size.width, 0.94*size.height, 0.99*size.width, 0.97*size.height, size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(oldClipper) => true; 
}