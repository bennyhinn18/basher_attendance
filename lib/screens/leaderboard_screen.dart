import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final leaderboard = await _supabaseService.getLeaderboard();
      setState(() {
        _leaderboardData = leaderboard;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty
              ? _buildEmptyState()
              : _buildLeaderboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No points data available yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: [
        _buildTopThree(),
        const Divider(height: 32),
        Expanded(
          child: _buildLeaderboardList(),
        ),
      ],
    );
  }

  Widget _buildTopThree() {
    final topThree = _leaderboardData.take(3).toList();
    if (topThree.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1)
            _buildTopPosition(topThree[1], 2, Colors.grey.shade400, 80),
          if (topThree.isNotEmpty)
            _buildTopPosition(topThree[0], 1, Colors.amber, 100),
          if (topThree.length > 2)
            _buildTopPosition(topThree[2], 3, Colors.brown.shade300, 60),
        ],
      ),
    );
  }

  Widget _buildTopPosition(Map<String, dynamic> data, int position, Color color, double height) {
    final name = data['members']['name'] as String;
    final points = data['points'] as int;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: position == 1 ? 30 : 25,
            backgroundColor: color,
            child: Text(
              position.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: position == 1 ? 24 : 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.split(' ').first,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$points pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.builder(
      itemCount: _leaderboardData.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final data = _leaderboardData[index];
        final name = data['members']['name'] as String;
        final rollNumber = data['members']['roll_number'] as String;
        final points = data['points'] as int;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 
                  ? [Colors.amber, Colors.grey.shade400, Colors.brown.shade300][index]
                  : Colors.blue.shade100,
              child: Text('${index + 1}'),
            ),
            title: Text(name),
            subtitle: Text('Roll No: $rollNumber'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$points pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
