import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'visitor_queue_status_screen.dart';

class CustomerTokenScreen extends StatefulWidget {
  const CustomerTokenScreen({super.key});

  @override
  State<CustomerTokenScreen> createState() =>
      _CustomerTokenScreenState();
}

class _CustomerTokenScreenState
    extends State<CustomerTokenScreen> {
  final TextEditingController visitorNameController =
      TextEditingController();

  int selectedDepartmentId = 1;
  bool priority = false;
  bool loading = false;
  bool cancelling = false;

  Map<String, dynamic>? generatedToken;

  final List<Map<String, dynamic>> departments = [
    {
      'id': 1,
      'name': 'IT Support',
      'code': 'IT',
    },
    {
      'id': 2,
      'name': 'HR',
      'code': 'HR',
    },
    {
      'id': 3,
      'name': 'Accounts',
      'code': 'ACC',
    },
    {
      'id': 4,
      'name': 'Administration',
      'code': 'ADM',
    },
  ];

  Future<void> generateToken() async {
    final visitorName =
        visitorNameController.text.trim();

    if (visitorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter visitor name'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final data = await ApiService.createToken(
        departmentId: selectedDepartmentId,
        visitorName: visitorName,
        priority: priority,
      );

          if (!mounted) return;

      setState(() {
        generatedToken = data;
        loading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisitorQueueStatusScreen(
            tokenId: int.parse(
              data['id'].toString(),
            ),
            departmentId: int.parse(
              data['department_id'].toString(),
            ),
            tokenNumber:
                data['token_number'].toString(),
            visitorName:
                data['visitor_name']?.toString() ??
                    visitorName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate token: $e',
          ),
        ),
      );
    }
  }

  Future<void> cancelToken() async {
    if (generatedToken == null) return;

    final tokenId = generatedToken!['id'];

    if (tokenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Token ID is not available',
          ),
        ),
      );
      return;
    }

    setState(() {
      cancelling = true;
    });

    try {
      final data = await ApiService.cancelToken(
        int.parse(tokenId.toString()),
      );

      if (!mounted) return;

      setState(() {
        generatedToken = {
          ...generatedToken!,
          ...data,
          'status': 'CANCELLED',
        };
        cancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Token cancelled successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to cancel token: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    visitorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenStatus =
        generatedToken?['status']?.toString() ??
            'WAITING';

    final isCancelled =
        tokenStatus == 'CANCELLED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Generate Token'),
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF111827),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 500,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Visitor Token',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter your details and generate a queue token.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Visitor Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller:
                            visitorNameController,
                        decoration:
                            const InputDecoration(
                          hintText:
                              'Enter your name',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Department',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      DropdownButtonFormField<int>(
                        initialValue:
                            selectedDepartmentId,
                        decoration:
                            const InputDecoration(
                          border:
                              OutlineInputBorder(),
                        ),
                        items: departments
                            .map((department) {
                          return DropdownMenuItem<int>(
                            value:
                                department['id']
                                    as int,
                            child: Text(
                              department['name']
                                  as String,
                            ),
                          );
                        }).toList(),
                        onChanged: generatedToken !=
                                null
                            ? null
                            : (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setState(() {
                                  selectedDepartmentId =
                                      value;
                                });
                              },
                      ),

                      const SizedBox(height: 12),

                      CheckboxListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Priority Token',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Priority visitors are called before normal visitors.',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        value: priority,
                        onChanged: generatedToken !=
                                null
                            ? null
                            : (value) {
                                setState(() {
                                  priority =
                                      value ??
                                          false;
                                });
                              },
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              loading ||
                                      generatedToken !=
                                          null
                                  ? null
                                  : generateToken,
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Generate Token',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (generatedToken != null) ...[
                  const SizedBox(height: 24),

                  Container(
                    padding:
                        const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Token',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Color(0xFF6B7280),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          generatedToken![
                                      'token_number']
                                  ?.toString() ??
                              '-',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Status: $tokenStatus',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color: isCancelled
                                ? const Color(
                                    0xFFDC2626,
                                  )
                                : const Color(
                                    0xFF047857,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          isCancelled
                              ? 'This token has been cancelled.'
                              : 'Please wait for your token to be called.',
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color:
                                Color(0xFF6B7280),
                          ),
                        ),

                        if (!isCancelled) ...[
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  cancelling
                                      ? null
                                      : cancelToken,
                              icon: cancelling
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .cancel_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                cancelling
                                    ? 'Cancelling...'
                                    : 'Cancel Token',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}