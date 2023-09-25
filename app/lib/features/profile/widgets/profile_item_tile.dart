import 'package:flutter/material.dart';

class ProfileItemTile extends StatelessWidget {
  const ProfileItemTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  title,
                  style: TextStyle(color: color),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 19,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
