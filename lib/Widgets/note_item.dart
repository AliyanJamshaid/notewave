import 'package:flutter/material.dart';

class NoteItem extends StatelessWidget {
  final String title;
  final String description;
  final String timestamp;

  const NoteItem({
    super.key,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          // clipper: BottomRightCustomClipper(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.black54,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.black54,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Icon(
            Icons.star,
            color: Colors.yellow,
            size: 30,
          ),
        ),
      ],
    );
  }
}

class BottomRightCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    // Start point
    path.moveTo(0, size.height * 0.2);

    // Left edge
    path.lineTo(0, size.height * 0.8);

    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, size.width * 0.1, size.height);

    // Bottom edge
    path.lineTo(size.width * 0.7 - 10, size.height);

    // Bottom-right corner - Made smaller by adjusting the control point
    path.quadraticBezierTo(size.width * 0.7, size.height, size.width * 0.7,
        size.height * 0.95 // Changed from 0.85 to 0.95 for smaller height
        );

    // Right edge curve
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.3, size.width - 10,
        size.height * 0.3);

    // Top-right corner curve
    path.quadraticBezierTo(
        size.width, size.height * 0.3, size.width, size.height * 0.3 - 10);

    // Top right edge
    path.lineTo(size.width, size.height * 0.2);

    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width * 0.9, 0);

    // Top edge
    path.lineTo(size.width * 0.1, 0);

    // Top-left corner
    path.quadraticBezierTo(0, 0, 0, size.height * 0.2);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
