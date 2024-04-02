import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_printer/expandable_fab.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cloud_printer/multipart_send.dart';


class FrontPage extends StatefulWidget {
	const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  int _color = 0xff9bdae6;
  List<String> _pictures = [];

	Widget miniFolder({String title="Folder name", int color = 0xff9bdae6}) {
			return GestureDetector(
				onTap: () {
          setState(() {
            _color = color;
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

	@override
	Widget build(BuildContext context) {
		return Scaffold(
          floatingActionButton: ExpandableFab(
            distance: 112,
            children: [
              ActionButton(
                onPressed: openPdfAndPrint,
                icon: const Icon(Icons.file_open),
              ),

              ActionButton(
                onPressed: () => {},
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
      		    ClipPath(
                clipper: FolderClipper(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: MediaQuery.of(context).size.height * 0.45,
                  width: MediaQuery.of(context).size.width,
                  child: miniFolderList(context)
                ),
              ),
      		  ],
      		),
    	);
	}

  void openPdfAndPrint() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowedExtensions: ['pdf']);

    if (result != null) {
      multipartSend(result.files.single.path!);  
    }
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

          multipartSend(file.path);
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