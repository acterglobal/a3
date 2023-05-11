import 'package:flutter/material.dart';

class SpaceResultCard extends StatelessWidget {
  final String? title;
  final String? members;

  const SpaceResultCard({
    super.key, this.title, this.members,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(10),),
      child: Container(
        margin: const EdgeInsets.all(5),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(5.0),
              child: CircleAvatar(
                radius: 25,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title!,style: const TextStyle(fontSize: 15)),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: members!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: 4),
                        ),
                        const TextSpan(
                          text: 'Members',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}