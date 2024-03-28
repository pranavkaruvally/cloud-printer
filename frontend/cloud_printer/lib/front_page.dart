import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class FrontPage extends StatelessWidget {
	const FrontPage({super.key});

	Widget miniFolder({String title="Folder name", int color = 0xffadabf2}) {
			return GestureDetector(
				onTap: () {},
				child: Container(
					margin: const EdgeInsets.only(left: 10.0, right: 10, top: 50, bottom: 50),
					height: 200,
					width: 200,
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(20),
						color: Color(color),
					),
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
      		//backgroundColor: const Color.fromARGB(255, 32, 33, 32),
          backgroundColor: const Color(0xff9bdae6),
      		body: Stack(
      		  children: [
      		    ClipPath(
                clipper: FolderClipper(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  width: MediaQuery.of(context).size.width,
                  child: miniFolderList(context)
                ),
              ),
      		  ],
      		),
    	);
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