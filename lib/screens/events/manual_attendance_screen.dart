import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/member.dart';
import '../../models/attendance_record.dart';
import '../../services/supabase_service.dart';

class ManualAttendanceScreen extends StatefulWidget {
  final Event event;

  const ManualAttendanceScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  List<int> _selectedMemberIds = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = await _supabaseService.getMembers();
      setState(() {
        _members = members;
        _filteredMembers = members;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading members: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members.where((member) {
          return member.name.toLowerCase().contains(query.toLowerCase()) ||
              member.rollNumber.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleMemberSelection(int memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  Future<void> _submitAttendance() async {
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      for (var memberId in _selectedMemberIds) {
        final member = _members.firstWhere((m) => m.id == memberId);
        final record = AttendanceRecord(
          memberId: memberId,
          eventId: widget.event.id,
          timestamp: DateTime.now(), // Add this line
          rollNumber: member.rollNumber,
          type: 'manual',
        );
        await _supabaseService.recordAttendance(record);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance recorded successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording attendance: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Attendance'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Members',
                hintText: 'Enter name or roll number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterMembers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterMembers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? _buildEmptyState()
                    : _buildMembersList(),
          ),
          if (_selectedMemberIds.isNotEmpty)
            _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No members found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return ListView.builder(
      itemCount: _filteredMembers.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        final isSelected = _selectedMemberIds.contains(member.id);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
              : null,
          child: CheckboxListTile(
            title: Text(member.name),
            subtitle: Text('Roll No: ${member.rollNumber}'),
            value: isSelected,
            onChanged: (_) => _toggleMemberSelection(member.id),
            secondary: CircleAvatar(
              child: Text(member.name.substring(0, 1)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedMemberIds.length} members selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAttendance,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
