import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {


  final GestureTapCallback onPressed;
  final String text;

  const CustomButton({Key? key,
    required this.onPressed, required this.text}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CustomButtonState();
  }

}

class CustomButtonState extends State<CustomButton> {




  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 35,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                    color: Colors.blue),
              ),
            ),
            TextButton(
                onPressed: widget.onPressed,
                child:Text(
                  widget.text,
                  style: const TextStyle(color: Colors.white),
                ))
          ],
        ),
      ),
    );
  }

}
