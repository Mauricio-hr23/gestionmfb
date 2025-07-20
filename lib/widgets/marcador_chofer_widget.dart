import 'package:flutter/material.dart';

class MarcadorChoferWidget extends StatelessWidget {
  final String nombre;
  final String? fotoUrl;
  final VoidCallback onTap;

  const MarcadorChoferWidget({
    required this.nombre,
    this.fotoUrl,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
                shape: BoxShape.circle,
              ),
              child: fotoUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(fotoUrl!),
                      radius: 22,
                    )
                  : CircleAvatar(
                      radius: 22,
                      child: Icon(Icons.person, size: 24),
                    ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Text(
                nombre,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
