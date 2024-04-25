import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_printer/expandable_fab.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'package:cloud_printer/multipart_send.dart';
import 'package:open_filex/open_filex.dart';

import 'package:network_discovery/network_discovery.dart';

class FrontPage extends StatefulWidget {
	const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  int _color = 0xff9bdae6;
  String currentTitle = "Medical Documents";
  String currentPrinter = "";
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
    shakeHandWithServer();
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
                onPressed: () {
                  //List<String> printerList = await fetchPrinterList(ipAddress);
                  //showModalBottomSheet(
                  //  context: context,
                  //  builder: builder
                  //  );
                  fetchPrinterList(ipAddress).then(
                    (printerList) {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: printerList.length,
                              itemBuilder: (BuildContext context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.print),
                                  title: Text(printerList[index]),
                                  onTap: () {
                                    currentPrinter = index.toString();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Selecting: ${printerList[index]}"),)
                                    );
                                    selectPrinter(printer: currentPrinter, ipAddress: ipAddress!);
                                    Navigator.pop(context);
                                  }
                                );
                              }
                            ),
                          );
                        }
                        );
                    }
                  );
                  },
                icon: const Icon(Icons.print),
              ),
              ActionButton(
                onPressed: () async {
                  shakeHandWithServer();

                  await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              contentPadding: const EdgeInsets.all(8.0),
                              leading: const Icon(Icons.link),
                              title: Text(addresses[index]),
                              onTap: () {
                                ipAddress = addresses[index];
                                Navigator.pop(context);
                              }
                            );
                          },
                        ),
                      );
                    }
                  );
                  //if (ipAddress != "") {
                  //  openPdfAndPrint(ipAddress);
                  //}
                },
                icon: const Icon(Icons.link),
              ),

              //ActionButton(
              //  onPressed: loadDocumentsDirectory,
              //  icon: const Icon(Icons.file_download),
              //),

              ActionButton(
                onPressed: () {
                  if (ipAddress != "") {
                    openPdfAndPrint(ipAddress);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No server selected!"),
                      )
                    );
                  }
                },
                
                icon: const Icon(Icons.file_open),
              ),

              if (Platform.isAndroid)
                ActionButton(
                  onPressed: () => takePictureAndMakePdf(context: context),
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
                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return SizedBox(
                                    height: 130,
                                    child: ListView(
                                      children: [
                                        ListTile(
                                          contentPadding: const EdgeInsets.all(8),
                                          leading: const Icon(Icons.picture_as_pdf),
                                          title: const Text("Open file"),
                                          onTap: () {
                                            OpenFilex.open(
                                              nameToDir[currentTitle]![index]
                                            );
                                          }
                                        ),
                                        ListTile(
                                          contentPadding: const EdgeInsets.all(8),
                                          leading: const Icon(Icons.print),
                                          title: const Text("Take printout"),
                                          onTap: () {
                                            if (ipAddress != "") {
                                              multipartSend(nameToDir[currentTitle]![index], ipAddress, currentPrinter).then(
                                                (status) {
                                                  String msg = "";
                                                  if (status == 200) {
                                                    msg = "Printing...";
                                                  } else {
                                                    msg = "Print failed...!";
                                                  }

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(msg))
                                                  );
                                                }
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Server not selected!")),
                                              );
                                            }
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: fileTile(
                              fileName: nameToDir[currentTitle]![index]
                            ),
                          );
                        } else {
                            return GestureDetector(
                              onTap: () async {
                                final baseDir = await getApplicationDocumentsDirectory();
                                String baseDirPath = "${baseDir.path}/Cloud Printer/$currentTitle";
                                FilePickerResult? result
                                  = await FilePicker.platform.pickFiles();
                                
                                if (result != null) {
                                  File file = File(result.files.single.path!);
                                  Uint8List bytes = await file.readAsBytes();
                                  String toFilePath = "$baseDirPath/${basename(result.files.single.path!)}";
                                  File toFile = File(toFilePath);

                                  await toFile.create(recursive: true);
                                  await toFile.writeAsBytes(bytes);

                                    setState(() {
                                      nameToDir[currentTitle]!.add(toFilePath);
                                    });
                                }
                              },
                              child: fileTile(fileName: "Add", addNew: true)
                            );
                        }
                      },
                    ),
                  )
                ),
      		  ],
      		),
    	);
	}

  void shakeHandWithServer() async {
    String deviceIp = "";// = await NetworkDiscovery.discoverDeviceIpAddress();
    final interfaces = await NetworkInterface.list();

    for (var interface in interfaces) {
      if (interface.name.contains('w')) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            deviceIp = addr.address;
            break;
          }
        }
      }
    }
    //print("Wireless IP: $ipAddress");
    
    if (deviceIp.isNotEmpty) {
      final String subnet = deviceIp.substring(0, deviceIp.lastIndexOf('.'));

      const port = 3000;
      // final stream = NetworkDiscovery.discover(subnet, port);
      final stream = NetworkDiscovery.discover(subnet, port);
      stream.listen((NetworkAddress addr) {
        if (!addresses.contains(addr.ip)) {
          addresses.add(addr.ip);
        }
      });
      // }).onDone(() => print(addresses));
    }

  }

  void openPdfAndPrint(String? ipAddress) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf']
      );
    
    if (result != null) {
      multipartSend(result.files.single.path!, ipAddress, currentPrinter);  
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

    setState(() {});
  }

  void takePictureAndMakePdf({required context}) async {
      List<String> pictures;

      try {
        pictures = await CunningDocumentScanner.getPictures(isGalleryImportAllowed: true) ?? [];
        if (!mounted) return;
        setState(() {
          _pictures = pictures;
        });
      } catch (exception) {
        //print("Exception caught!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error creating PDF!"))
        );
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

          multipartSend(file.path, ipAddress, currentPrinter);
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