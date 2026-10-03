import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VisitorQueueStatusScreen extends StatefulWidget {
  final int tokenId;
  final int departmentId;
  final String tokenNumber;
  final String visitorName;

  const VisitorQueueStatusScreen({
    super.key,
    required this.tokenId,
    required this.departmentId,
    required this.tokenNumber,
    required this.visitorName,
  });

  @override
  State<VisitorQueueStatusScreen> createState() =>
      _VisitorQueueStatusScreenState();
}

class _VisitorQueueStatusScreenState
    extends State<VisitorQueueStatusScreen> {
  Map<String, dynamic>? tokenData;

 List<dynamic> queue = [];
bool loading = true;
String? errorMessage;
Timer? refreshTimer;

// This can change when the token is transferred
// to another department.
late int currentDepartmentId;

 @override
void initState() {
  super.initState();

  currentDepartmentId = widget.departmentId;

  loadStatus();

  refreshTimer = Timer.periodic(
    const Duration(seconds: 5),
    (_) {
      loadStatus();
    },
  );
}

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

Future<void> loadStatus() async {
  try {
    // Get the latest status of the visitor's token.
    final statusData = await ApiService.getTokenStatus(
      widget.tokenId,
    );

    final status = statusData['status'];

    // Update department in case the token was transferred.
    final latestDepartmentId = statusData['department_id'];

    if (latestDepartmentId != null) {
      currentDepartmentId =
          int.parse(latestDepartmentId.toString());
    }

    List<dynamic> queueData = [];

    // Get live queue only while the token is active.
    if (status == 'WAITING' || status == 'SERVING') {
      queueData = await ApiService.getVisitorQueue(
        currentDepartmentId,
      );
    }

    // Find this visitor's token inside the live queue.
    Map<String, dynamic>? queueToken;

    for (final item in queueData) {
      if (item['id'].toString() ==
          widget.tokenId.toString()) {
        queueToken = Map<String, dynamic>.from(item);
        break;
      }
    }

    // Combine token status + queue information.
    final combinedTokenData = Map<String, dynamic>.from(
      statusData,
    );

    if (queueToken != null) {
      combinedTokenData.addAll(queueToken);
    }

    if (!mounted) return;

    setState(() {
      tokenData = combinedTokenData;
      queue = queueData;
      loading = false;
      errorMessage = null;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      loading = false;
      errorMessage = e.toString();
    });
  }
}
  Future<void> cancelToken() async {
    try {
      await ApiService.cancelToken(widget.tokenId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token cancelled successfully'),
        ),
      );

      await loadStatus();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel token: $e'),
        ),
      );
    }
  }

  Future<void> confirmCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Token?'),
          content: const Text(
            'Are you sure you want to cancel your token?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('YES, CANCEL'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await cancelToken();
    }
  }

  String getStatusText() {
    if (tokenData == null) {
      return 'NOT IN QUEUE';
    }

    final status = tokenData!['status'];

    switch (status) {
      case 'WAITING':
        return 'WAITING';
      case 'SERVING':
        return 'NOW SERVING';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'CANCELLED':
        return 'CANCELLED';
      case 'NO_SHOW':
        return 'NO SHOW';
      default:
        return status?.toString() ?? 'UNKNOWN';
    }
  }

  Color getStatusColor() {
    if (tokenData == null) {
      return Colors.grey;
    }

    switch (tokenData!['status']) {
      case 'WAITING':
        return Colors.orange;
      case 'SERVING':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      case 'NO_SHOW':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int get queuePosition {
    final value = tokenData?['queue_position'];

    if (value == null) {
      return 0;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  int get peopleAhead {
    if (queuePosition <= 0) {
      return 0;
    }

    return queuePosition - 1;
  }

  List<dynamic> get trackerQueue {
    if (queue.isEmpty) {
      return [];
    }

    // Show a small window around the visitor's token.
    final visitorIndex = queue.indexWhere(
      (item) =>
          item['id'].toString() ==
          widget.tokenId.toString(),
    );

    if (visitorIndex == -1) {
      return queue.take(7).toList();
    }

    final start = visitorIndex - 2 < 0
        ? 0
        : visitorIndex - 2;

    final end = start + 7 > queue.length
        ? queue.length
        : start + 7;

    return queue.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final status = tokenData?['status'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Track My Token'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadStatus,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),

            const Icon(
              Icons.confirmation_number_outlined,
              size: 65,
              color: Colors.blue,
            ),

            const SizedBox(height: 10),

            const Text(
              'Your Token',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              widget.tokenNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              widget.visitorName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 22),

            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              _buildErrorCard()
            else ...[
              _buildStatusCard(status),

              if (status == 'WAITING') ...[
                const SizedBox(height: 16),
                _buildQueueSummary(),
                const SizedBox(height: 16),
                _buildQueueTracker(),
              ],

              if (status == 'SERVING') ...[
                const SizedBox(height: 16),
                _buildServingCard(),
              ],

              if (status == 'COMPLETED') ...[
                const SizedBox(height: 16),
                _buildCompletedCard(),
              ],

              if (status == 'CANCELLED') ...[
                const SizedBox(height: 16),
                _buildCancelledCard(),
              ],

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: loadStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('REFRESH STATUS'),
              ),

              if (status == 'WAITING') ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: confirmCancel,
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text('CANCEL TOKEN'),
                ),
              ],

              const SizedBox(height: 15),

              const Text(
                'Queue status updates automatically every 5 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String? status) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              getStatusText(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: getStatusColor(),
              ),
            ),

            if (status == 'WAITING') ...[
              const SizedBox(height: 8),
              const Text(
                'Your place in the queue is being tracked live.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueueSummary() {
    final eta =
        tokenData?['eta_minutes']?.toString() ?? '0';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'QUEUE SUMMARY',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    Icons.people_outline,
                    'People Ahead',
                    peopleAhead.toString(),
                  ),
                ),

                Container(
                  height: 55,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                Expanded(
                  child: _summaryItem(
                    Icons.confirmation_number_outlined,
                    'Your Position',
                    queuePosition.toString(),
                  ),
                ),

                Container(
                  height: 55,
                  width: 1,
                  color: Colors.grey.shade300,
                ),

                Expanded(
                  child: _summaryItem(
                    Icons.access_time,
                    'Estimated Wait',
                    '$eta min',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 25,
          color: Colors.blue,
        ),

        const SizedBox(height: 7),

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueTracker() {
    final items = trackerQueue;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'QUEUE PROGRESS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            ...items.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final item = entry.value;

                final isMe =
                    item['id'].toString() ==
                        widget.tokenId.toString();

                final itemStatus =
                    item['status']?.toString() ??
                        'WAITING';

                final isServing =
                    itemStatus == 'SERVING';

                final isCompleted =
                    itemStatus == 'COMPLETED';

                final isLast =
                    index == items.length - 1;

                return _buildTrackerItem(
                  tokenNumber:
                      item['token_number']?.toString() ??
                          '-',
                  isMe: isMe,
                  isServing: isServing,
                  isCompleted: isCompleted,
                  isLast: isLast,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerItem({
    required String tokenNumber,
    required bool isMe,
    required bool isServing,
    required bool isCompleted,
    required bool isLast,
  }) {
    IconData icon;
    Color color;

    if (isMe) {
      icon = Icons.person;
      color = Colors.blue;
    } else if (isServing) {
      icon = Icons.record_voice_over;
      color = Colors.green;
    } else if (isCompleted) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.radio_button_unchecked;
      color = Colors.grey;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 35,
                color: Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 2,
              bottom: 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tokenNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isMe
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isMe
                          ? Colors.blue
                          : const Color(
                              0xFF374151,
                            ),
                    ),
                  ),
                ),

                if (isMe)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  )
                else if (isServing)
                  const Text(
                    'SERVING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else if (isCompleted)
                  const Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                else
                  const Text(
                    'WAITING',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServingCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.campaign,
              size: 50,
              color: Colors.green.shade700,
            ),

            const SizedBox(height: 10),

            Text(
              'NOW SERVING',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please proceed to the counter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.blue,
            ),
            SizedBox(height: 10),
            Text(
              'COMPLETED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your service has been completed.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledCard() {
    return Card(
      color: Colors.red.shade50,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.cancel,
              size: 50,
              color: Colors.red,
            ),
            SizedBox(height: 10),
            Text(
              'CANCELLED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your token has been cancelled.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 45,
              color: Colors.red,
            ),

            const SizedBox(height: 10),

            const Text(
              'Unable to load queue status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadStatus,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}