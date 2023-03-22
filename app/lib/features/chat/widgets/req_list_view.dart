import 'package:flutter/material.dart';

class ReqListView extends StatelessWidget {
  final String name;

  const ReqListView({
    Key? key,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          Row(
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'Decline',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
