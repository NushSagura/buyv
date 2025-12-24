import 'package:flutter/material.dart';
import '../reels/reels_screen.dart';
import '../../../domain/models/reel_model.dart';

class SearchReelsScreen extends StatefulWidget {
  final bool disableNetworkImages;
  const SearchReelsScreen({super.key, this.disableNetworkImages = false});

  @override
  State<SearchReelsScreen> createState() => _SearchReelsScreenState();
}

class _SearchReelsScreenState extends State<SearchReelsScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ReelModel> _mockReels = [
    ReelModel(
      id: '1',
      userId: 'user1',
      username: 'ahmed_shop',
      userProfileImage: 'assets/images/profile.png',
      isUserVerified: true,
      videoUrl: 'https://dl.dropboxusercontent.com/scl/fi/r5iwu55alyisg4jqd1vgu/997140902_tk.mp4?rlkey=g687oi0n7sd4ragrvn5oe29kq&st=v17hcbvn&dl=0',
      thumbnailUrl: 'assets/images/img.png',
      caption: 'Latest fashion trends for this season! 🔥',
      hashtags: const ['fashion', 'shopping', 'new'],
      musicId: 'music1',
      musicTitle: 'Trending Song',
      musicArtist: 'Artist Name',
      product: null,
      likesCount: 1250,
      commentsCount: 89,
      sharesCount: 45,
      viewsCount: 15000,
      isLiked: false,
      isBookmarked: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      duration: 30,
      metadata: const {},
    ),
    ReelModel(
      id: '2',
      userId: 'user2',
      username: 'fashion_store',
      userProfileImage: 'assets/images/profile.png',
      isUserVerified: true,
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      thumbnailUrl: 'assets/images/img_1.png',
      caption: 'Special offer on summer collection 🌞',
      hashtags: const ['discounts', 'clothes', 'summer'],
      musicId: 'music2',
      musicTitle: 'Summer Vibes',
      musicArtist: 'DJ Cool',
      product: null,
      likesCount: 980,
      commentsCount: 64,
      sharesCount: 22,
      viewsCount: 9000,
      isLiked: false,
      isBookmarked: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      duration: 25,
      metadata: const {},
    ),
  ];

  String _query = '';

  List<ReelModel> get _filteredReels {
    if (_query.isEmpty) return _mockReels;
    final q = _query.toLowerCase();
    return _mockReels.where((r) {
      final caption = r.caption.toLowerCase();
      final user = r.username.toLowerCase();
      final hash = r.hashtags.join(' ').toLowerCase();
      return caption.contains(q) || user.contains(q) || hash.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Reels')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type search keyword or hashtag...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredReels.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final reel = _filteredReels[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: widget.disableNetworkImages
                        ? null
                        : NetworkImage(reel.userProfileImage),
                    child: widget.disableNetworkImages
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(reel.username),
                  subtitle: Text(reel.caption),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReelsScreen(targetReelId: reel.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}