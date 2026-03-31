import 'package:flutter/material.dart';
import 'user_avatar.dart';

class UserAvatarCell extends StatelessWidget {
  final String name;
  final double avatarRadius;
  final String? subtitle;

  const UserAvatarCell({
    super.key,
    required this.name,
    this.avatarRadius = 14,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: name, radius: avatarRadius),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ],
    );
  }
}
