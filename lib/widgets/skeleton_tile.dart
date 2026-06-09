import 'package:flutter/material.dart';

class SkeletonTile extends StatefulWidget {
  const SkeletonTile({super.key});

  @override
  State<SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _anim = ColorTween(
      begin: const Color(0xFFE0E0E0),
      end: const Color(0xFFF5F5F5),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final c = _anim.value!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(color: c, width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    _Bar(color: c, width: 180, height: 12),
                    const SizedBox(height: 4),
                    _Bar(color: c, width: 140, height: 12),
                    const SizedBox(height: 12),
                    _Bar(color: c, width: 90, height: 30, radius: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double radius;

  const _Bar({
    required this.color,
    required this.width,
    required this.height,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
