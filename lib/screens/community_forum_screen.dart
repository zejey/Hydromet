import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  bool _isLoggedIn = false;
  String _selectedTab = 'Weather Reports';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authManager = AuthManager();
    await authManager.initialize();
    
    if (mounted) {
      setState(() {
        _isLoggedIn = authManager.isLoggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: const Text('Community Forum'),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/b.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade700.withValues(alpha: 0.8),
                Colors.blue.shade900.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: _showNewPostDialog,
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      'Weather Reports',
      'Safety Tips',
      'Local News',
      'Community Chat',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: tabs.map((tab) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == tab
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: _selectedTab == tab ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'Weather Reports':
        return _buildWeatherReports();
      case 'Safety Tips':
        return _buildSafetyTips();
      case 'Local News':
        return _buildLocalNews();
      case 'Community Chat':
        return _buildCommunityChat();
      default:
        return _buildWeatherReports();
    }
  }

  Widget _buildWeatherReports() {
    final reports = [
      {
        'user': 'Maria Santos',
        'time': '2 hours ago',
        'location': 'Brgy. San Vicente',
        'report': 'Heavy rain and flooding observed along Maharlika Highway. Water level reached ankle-deep near the market area.',
        'image': 'assets/flood.jpg',
        'likes': 12,
        'comments': 5,
      },
      {
        'user': 'Juan Dela Cruz',
        'time': '4 hours ago',
        'location': 'Brgy. Poblacion',
        'report': 'Clear skies now but strong winds earlier. Some tree branches down near the church.',
        'image': 'assets/clear_day.jpg',
        'likes': 8,
        'comments': 3,
      },
      {
        'user': 'Anna Reyes',
        'time': '6 hours ago',
        'location': 'Brgy. Riverside',
        'report': 'Laguna de Bay water level rising. Residents near the shore are advised to monitor closely.',
        'image': 'assets/rainy.jpg',
        'likes': 15,
        'comments': 7,
      },
    ];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildSafetyTips() {
    final tips = [
      {
        'user': 'DRRMO San Pedro',
        'time': '1 day ago',
        'title': 'Flood Preparedness Checklist',
        'content': 'Keep emergency supplies ready: flashlight, battery radio, first aid kit, and bottled water for 3 days.',
        'icon': Icons.security,
        'likes': 25,
        'comments': 8,
      },
      {
        'user': 'Barangay Captain Torres',
        'time': '2 days ago',
        'title': 'Typhoon Season Reminders',
        'content': 'Secure loose items around your house, check drainage systems, and have evacuation plans ready.',
        'icon': Icons.warning,
        'likes': 18,
        'comments': 12,
      },
      {
        'user': 'Health Center',
        'time': '3 days ago',
        'title': 'Water Safety During Floods',
        'content': 'Avoid wading through floodwater. If you must, use a stick to check depth and watch for manholes.',
        'icon': Icons.health_and_safety,
        'likes': 22,
        'comments': 6,
      },
    ];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        final tip = tips[index];
        return _buildTipCard(tip);
      },
    );
  }

  Widget _buildLocalNews() {
    final news = [
      {
        'user': 'San Pedro LGU',
        'time': '3 hours ago',
        'title': 'New Flood Control System Operational',
        'content': 'The newly installed pumping station at Brgy. Nueva is now operational and will help reduce flooding in the area.',
        'image': 'assets/b.jpg',
        'likes': 45,
        'comments': 15,
      },
      {
        'user': 'PAGASA Laguna',
        'time': '1 day ago',
        'title': 'Weather Update: Rainy Season Extended',
        'content': 'Expected continuation of rainy weather until December. Residents are advised to stay vigilant.',
        'image': 'assets/rainy.jpg',
        'likes': 32,
        'comments': 9,
      },
      {
        'user': 'Barangay Council',
        'time': '2 days ago',
        'title': 'Community Emergency Drill Schedule',
        'content': 'Monthly emergency drill scheduled for next Saturday at 2 PM. All residents are encouraged to participate.',
        'image': 'assets/logo.png',
        'likes': 28,
        'comments': 11,
      },
    ];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: news.length,
      itemBuilder: (context, index) {
        final newsItem = news[index];
        return _buildNewsCard(newsItem);
      },
    );
  }

  Widget _buildCommunityChat() {
    final messages = [
      {
        'user': 'Pedro Gonzales',
        'time': '5 minutes ago',
        'message': 'Anyone else hearing the thunder? Seems like another storm is coming.',
        'replies': 3,
      },
      {
        'user': 'Lisa Mendoza',
        'time': '10 minutes ago',
        'message': 'The drainage near our area needs cleaning. Who can we contact?',
        'replies': 7,
      },
      {
        'user': 'Carlos Ramos',
        'time': '15 minutes ago',
        'message': 'Thank you to everyone who helped during last week\'s flooding. Bayanihan spirit!',
        'replies': 12,
      },
      {
        'user': 'Elena Cruz',
        'time': '30 minutes ago',
        'message': 'Weather looking good for the weekend. Perfect for the community event.',
        'replies': 5,
      },
    ];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildChatMessage(message);
            },
          ),
        ),
        if (_isLoggedIn) _buildChatInput(),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['user'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${report['time']} • ${report['location']}',
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
            const SizedBox(height: 12),
            Text(
              report['report'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                report['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.grey[600], size: 20),
                const SizedBox(width: 4),
                Text('${report['likes']}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, color: Colors.grey[600], size: 20),
                const SizedBox(width: 4),
                Text('${report['comments']}'),
                const Spacer(),
                TextButton(
                  onPressed: () => _showComments(report),
                  child: const Text('View Comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade700,
                  child: Icon(tip['icon'], color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['user'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        tip['time'],
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
            const SizedBox(height: 12),
            Text(
              tip['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tip['content'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.grey[600], size: 20),
                const SizedBox(width: 4),
                Text('${tip['likes']}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, color: Colors.grey[600], size: 20),
                const SizedBox(width: 4),
                Text('${tip['comments']}'),
                const Spacer(),
                TextButton(
                  onPressed: () => _showComments(tip),
                  child: const Text('View Comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> newsItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.announcement, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newsItem['user'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        newsItem['time'],
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
            const SizedBox(height: 12),
            Text(
              newsItem['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              newsItem['content'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                newsItem['image'],
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up, color: Colors.grey[600], size: 20),
                const SizedBox(width: 4),
                Text('${newsItem['likes']}'),
                const SizedBox(width: 16),
                Icon(Icons.comment, color: Colors.grey[600], size: 20),
                const SizedBox(width: 4),
                Text('${newsItem['comments']}'),
                const Spacer(),
                TextButton(
                  onPressed: () => _showComments(newsItem),
                  child: const Text('View Comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 16,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['user'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        message['time'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message['message'],
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.reply, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${message['replies']} replies',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showChatReplies(message),
                  child: const Text('Reply', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.green.shade700,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                // Handle send message
                _showSnackBar('Message sent!');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['Weather Report', 'Safety Tip', 'Local News', 'General Discussion']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Post created successfully!');
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showComments(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comments'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildCommentTile('Ana Torres', '2 hours ago', 'Very helpful information, thank you!'),
              _buildCommentTile('Carlos Mendez', '1 hour ago', 'I saw the same thing in our area.'),
              _buildCommentTile('Maria Santos', '30 minutes ago', 'Stay safe everyone!'),
            ],
          ),
        ),
        actions: [
          if (_isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar('Comment added!');
              },
              child: const Text('Add Comment'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChatReplies(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replies'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              _buildCommentTile('Rico Santos', '8 minutes ago', 'Yes, I heard it too. Better prepare.'),
              _buildCommentTile('Elena Cruz', '5 minutes ago', 'Already secured our windows.'),
              _buildCommentTile('Jun Reyes', '2 minutes ago', 'Thanks for the heads up!'),
            ],
          ),
        ),
        actions: [
          if (_isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnackBar('Reply sent!');
              },
              child: const Text('Reply'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(String user, String time, String comment) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.green,
        radius: 16,
        child: Icon(Icons.person, color: Colors.white, size: 16),
      ),
      title: Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
      dense: true,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
