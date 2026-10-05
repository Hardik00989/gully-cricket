import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/matches/domain/cricket_match.dart';

class TeamLogo extends StatelessWidget {
  const TeamLogo({super.key, required this.name, this.url = ''});
  final String name, url;
  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(child: Text(CricketMatch.initials(name)));
    if (url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      width: 40,
      height: 40,
      imageBuilder: (_, image) => CircleAvatar(backgroundImage: image),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
