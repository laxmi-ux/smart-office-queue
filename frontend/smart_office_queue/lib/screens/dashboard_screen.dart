import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:smart_office_queue/main.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedDepartmentId = 1;
  bool isLoading = true;

  Map<String, dynamic>? dashboardData;
  String? errorMessage;

  List<dynamic> queue = [];
  bool queueLoading = false;
  String? queueError;

  bool departmentsLoading = false;

  final List<Map<String, dynamic>> departments = [
    {
      'id': 1,
      'name': 'IT Support',
      'code': 'IT',
      'icon': Icons.computer_outlined,
      'status': 'Active',
    },
    {
      'id': 2,
      'name': 'HR',
      'code': 'HR',
      'icon': Icons.people_outline,
      'status': 'Active',
    },
    {
      'id': 3,
      'name': 'Accounts',
      'code': 'ACC',
      'icon': Icons.account_balance_wallet_outlined,
      'status': 'Paused',
    },
    {
      'id': 4,
      'name': 'Administration',
      'code': 'ADM',
      'icon': Icons.business_outlined,
      'status': 'Active',
    },
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
    loadDepartments();
  }

  // ============================================================
  // LOAD DEPARTMENTS
  // ============================================================

  Future<void> loadDepartments() async {
    if (mounted) {
      setState(() {
        departmentsLoading = true;
      });
    }

    try {
      final data = await ApiService.getDepartments();

      for (final department in data) {
        final id = department['id'];

        final index = departments.indexWhere(
          (item) => item['id'] == id,
        );

        if (index != -1) {
          departments[index]['status'] =
              department['is_paused'] == true
                  ? 'Paused'
                  : 'Active';
        }
      }

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load departments: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          departmentsLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PAUSE / RESUME DEPARTMENT
  // ============================================================

  Future<void> toggleDepartmentPause(
    int departmentId,
    bool currentlyPaused,
  ) async {
    try {
      await ApiService.setDepartmentPause(
        departmentId: departmentId,
        paused: !currentlyPaused,
      );

      await loadDepartments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyPaused
                ? 'Department resumed successfully'
                : 'Department paused successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update department: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await ApiService.getDashboard(
        selectedDepartmentId,
      );

      if (!mounted) return;

      setState(() {
        dashboardData = data;
        isLoading = false;
      });

      await loadQueue();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // ============================================================
  // LOAD QUEUE
  // ============================================================

  Future<void> loadQueue() async {
    if (mounted) {
      setState(() {
        queueLoading = true;
        queueError = null;
      });
    }

    try {
      final data = await ApiService.getQueue(
        selectedDepartmentId,
      );

      if (!mounted) return;

      setState(() {
        queue = data;
        queueLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        queueLoading = false;
        queueError = e.toString();
      });
    }
  }

  // ============================================================
  // GETTERS
  // ============================================================

  Map<String, dynamic> get selectedDepartment {
    return departments.firstWhere(
      (department) =>
          department['id'] == selectedDepartmentId,
      orElse: () => departments.first,
    );
  }

  String get userName {
    return widget.user['name']?.toString() ?? 'User';
  }

  String get userRole {
    return widget.user['role']?.toString() ?? 'STAFF';
  }

  int get waitingCount {
    final value = dashboardData?['waiting_count'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  int get servingCount {
    final value = dashboardData?['serving_count'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  int get completedCount {
    final value = dashboardData?['completed_count'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  int get noShowCount {
    final value = dashboardData?['no_show_count'];

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  double get averageWaitingTime {
    final value =
        dashboardData?['average_waiting_time_minutes'];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  // ============================================================
  // CALL NEXT
  // ============================================================

  Future<void> callNextToken() async {
    try {
      await ApiService.callNext(
        selectedDepartmentId,
      );

      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Next token called successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to call next token: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // COMPLETE TOKEN
  // ============================================================

  Future<void> completeToken(int tokenId) async {
    try {
      await ApiService.completeToken(tokenId);

      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Token completed successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to complete token: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // NO SHOW
  // ============================================================

  Future<void> noShowToken(int tokenId) async {
    try {
      await ApiService.noShowToken(tokenId);

      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No Show recorded successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to record No Show: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TRANSFER TOKEN
  // ============================================================

  Future<void> transferToken(
    int tokenId,
    int toDepartmentId,
  ) async {
    try {
      await ApiService.transferToken(
        tokenId: tokenId,
        toDepartmentId: toDepartmentId,
      );

      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Token transferred successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to transfer token: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TRANSFER DIALOG
  // ============================================================

  Future<void> showTransferDialog(int tokenId) async {
    int? selectedDestinationDepartment;

    final availableDepartments = departments
        .where(
          (department) =>
              department['id'] != selectedDepartmentId,
        )
        .toList();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Transfer Token',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select the department where this visitor should continue.',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<int>(
                    initialValue:
                        selectedDestinationDepartment,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Destination Department',
                      border:
                          OutlineInputBorder(),
                    ),
                    items:
                        availableDepartments.map(
                      (department) {
                        return DropdownMenuItem<int>(
                          value:
                              department['id'] as int,
                          child: Text(
                            department['name']
                                .toString(),
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDestinationDepartment =
                            value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      selectedDestinationDepartment ==
                              null
                          ? null
                          : () async {
                              final destination =
                                  selectedDestinationDepartment!;

                              Navigator.pop(
                                dialogContext,
                              );

                              await transferToken(
                                tokenId,
                                destination,
                              );
                            },
                  child: const Text(
                    'Transfer',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout() {
    ApiService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: RefreshIndicator(
                onRefresh: loadDashboard,
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 28),

                      _buildDepartmentSelector(),

                      const SizedBox(height: 24),

                      _buildStatistics(),

                      const SizedBox(height: 24),

                      _buildQueueSection(),

                      const SizedBox(height: 24),

                      _buildDepartmentStatus(),

                      const SizedBox(height: 24),

                      _buildDepartmentManagementSection(),

                      const SizedBox(height: 30),

                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile =
            constraints.maxWidth < 650;

        return Container(
          height: 72,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Flexible(
                child: Text(
                  'Smart Office',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF111827),
                  ),
                ),
              ),

              const Spacer(),

              IconButton(
                tooltip: 'Refresh',
                onPressed: loadDashboard,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF4B5563),
                ),
              ),

              if (!isMobile) ...[
                const SizedBox(width: 8),

                Container(
                  height: 38,
                  width: 1,
                  color:
                      const Color(0xFFE5E7EB),
                ),

                const SizedBox(width: 16),

                CircleAvatar(
                  radius: 19,
                  backgroundColor:
                      const Color(0xFFE5E7EB),
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0]
                            .toUpperCase()
                        : 'U',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF374151),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      userRole,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),
              ] else ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      const Color(0xFFE5E7EB),
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0]
                            .toUpperCase()
                        : 'U',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF374151),
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],

              IconButton(
                tooltip: 'Logout',
                onPressed: logout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color:
                      Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final small =
            constraints.maxWidth < 650;

        if (small) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Queue Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Manage and monitor today\'s office queues.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Color(0xFF6B7280),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Queue Dashboard',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF111827),
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Manage and monitor today\'s office queues.',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color:
                      const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .calendar_today_outlined,
                    size: 15,
                    color:
                        Color(0xFF6B7280),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _today(),
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w500,
                      color:
                          Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _today() {
    final now = DateTime.now();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // ============================================================
  // DEPARTMENT SELECTOR
  // ============================================================

  Widget _buildDepartmentSelector() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF374151),
          ),
        ),

        const SizedBox(height: 9),

        Container(
          width: 330,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color:
                  const Color(0xFFD1D5DB),
            ),
          ),
          child:
              DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value:
                  selectedDepartmentId,
              isExpanded: true,
              borderRadius:
                  BorderRadius.circular(10),
              dropdownColor:
                  Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              icon: const Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                color:
                    Color(0xFF6B7280),
              ),
              items:
                  departments.map(
                (department) {
                  final int
                      departmentId =
                      department['id']
                          as int;

                  final bool selected =
                      departmentId ==
                          selectedDepartmentId;

                  return DropdownMenuItem<
                      int>(
                    value:
                        departmentId,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                                    0xFFF3F4F6),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child: Icon(
                            department['icon']
                                as IconData,
                            size: 20,
                            color:
                                const Color(
                                    0xFF374151),
                          ),
                        ),

                        const SizedBox(
                          width: 11,
                        ),

                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                department[
                                        'name']
                                    .toString(),
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      Color(
                                          0xFF111827),
                                ),
                              ),

                              const SizedBox(
                                height: 2,
                              ),

                              Text(
                                '${department['code']} Department',
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Color(
                                          0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (selected)
                          const Icon(
                            Icons
                                .check_rounded,
                            size: 19,
                            color:
                                Color(
                                    0xFF111827),
                          ),
                      ],
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  selectedDepartmentId =
                      value;
                });

                loadDashboard();
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    if (isLoading) {
      return Container(
        height: 150,
        alignment:
            Alignment.center,
        decoration:
            _cardDecoration(),
        child:
            const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    if (errorMessage != null) {
      return _errorCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth;

        int columns;

        if (width >= 1200) {
          columns = 5;
        } else if (width >= 750) {
          columns = 3;
        } else {
          columns = 1;
        }

        const spacing = 14.0;

        final cardWidth =
            (width -
                    ((columns - 1) *
                        spacing)) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Waiting',
                value:
                    '$waitingCount',
                subtitle:
                    'Visitors in queue',
                icon:
                    Icons
                        .people_outline_rounded,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Serving',
                value:
                    '$servingCount',
                subtitle:
                    'Currently being served',
                icon:
                    Icons
                        .person_outline_rounded,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Completed',
                value:
                    '$completedCount',
                subtitle:
                    'Completed today',
                icon:
                    Icons
                        .check_circle_outline_rounded,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'No Shows',
                value:
                    '$noShowCount',
                subtitle:
                    'Marked as no-show',
                icon:
                    Icons
                        .person_off_outlined,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Average Wait',
                value:
                    '${averageWaitingTime.toStringAsFixed(0)}m',
                subtitle:
                    'Average waiting time',
                icon:
                    Icons
                        .schedule_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFF3F4F6),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              size: 21,
              color:
                  const Color(0xFF374151),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUEUE SECTION
  // ============================================================

  Widget _buildQueueSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              _buildCurrentlyServing(),

              const SizedBox(height: 18),

              _buildWaitingQueue(),
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child:
                  _buildCurrentlyServing(),
            ),

            const SizedBox(width: 18),

            Expanded(
              flex: 6,
              child:
                  _buildWaitingQueue(),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CURRENTLY SERVING
  // ============================================================

  Widget _buildCurrentlyServing() {
    final servingTokens =
        queue.where((item) {
      return item['status'] ==
          'SERVING';
    }).toList();

    return Container(
      padding:
          const EdgeInsets.all(22),
      decoration:
          _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Currently Serving',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Active visitor being served',
            style: TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF9CA3AF),
            ),
          ),

          const SizedBox(height: 20),

          if (servingTokens.isEmpty)
            _buildNoServingCard()
          else
            ...servingTokens.map(
              (item) {
                final token =
                    Map<String, dynamic>.from(
                  item as Map,
                );

                return _buildServingToken(
                  token,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoServingCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .support_agent_rounded,
            size: 34,
            color:
                Color(0xFF9CA3AF),
          ),

          const SizedBox(height: 10),

          const Text(
            'No visitor currently being served',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.icon(
              onPressed:
                  callNextToken,
              icon: const Icon(
                Icons
                    .skip_next_rounded,
                size: 18,
              ),
              label: const Text(
                'Call Next',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingToken(
    Map<String, dynamic> token,
  ) {
    final tokenNumber =
        token['token_number']
                ?.toString() ??
            '-';

    final visitorName =
        token['visitor_name']
                    ?.toString()
                    .isNotEmpty ==
                true
            ? token['visitor_name']
                .toString()
            : 'Visitor';

    final tokenId =
        token['id'];

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Text(
            tokenNumber,
            style:
                const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            visitorName,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
              color:
                  Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFECFDF5),
              borderRadius:
                  BorderRadius.circular(
                6,
              ),
            ),
            child: const Text(
              'SERVING',
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF047857),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.icon(
              onPressed:
                  tokenId == null
                      ? null
                      : () {
                          completeToken(
                            int.parse(
                              tokenId
                                  .toString(),
                            ),
                          );
                        },
              icon: const Icon(
                Icons.check_rounded,
                size: 18,
              ),
              label:
                  const Text(
                'Complete',
                style:
                    TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child:
                OutlinedButton.icon(
              onPressed:
                  tokenId == null
                      ? null
                      : () {
                          noShowToken(
                            int.parse(
                              tokenId
                                  .toString(),
                            ),
                          );
                        },
              icon: const Icon(
                Icons
                    .person_off_rounded,
                size: 18,
              ),
              label:
                  const Text(
                'No Show',
                style:
                    TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child:
                OutlinedButton.icon(
              onPressed:
                  tokenId == null
                      ? null
                      : () {
                          showTransferDialog(
                            int.parse(
                              tokenId
                                  .toString(),
                            ),
                          );
                        },
              icon: const Icon(
                Icons
                    .swap_horiz_rounded,
                size: 18,
              ),
              label:
                  const Text(
                'Transfer',
                style:
                    TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WAITING QUEUE
  // ============================================================

  Widget _buildWaitingQueue() {
    final waitingTokens =
        queue.where((item) {
      return item['status'] ==
          'WAITING';
    }).toList();

    return Container(
      padding:
          const EdgeInsets.all(22),
      decoration:
          _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Waiting Queue',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(
                                0xFF111827),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Visitors waiting for service',
                      style:
                          TextStyle(
                        fontSize: 11,
                        color:
                            Color(
                                0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                          0xFFF3F4F6),
                  borderRadius:
                      BorderRadius
                          .circular(
                    7,
                  ),
                ),
                child: Text(
                  '$waitingCount waiting',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF374151),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _queueHeader(),

          const Divider(
            height: 18,
            color:
                Color(0xFFE5E7EB),
          ),

          if (queueLoading)
            const Padding(
              padding:
                  EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else if (queueError != null)
            _buildQueueError()
          else if (waitingTokens.isEmpty)
            _buildEmptyQueue()
          else
            ...waitingTokens
                .asMap()
                .entries
                .map(
              (entry) {
                final index =
                    entry.key;

                final token =
                    Map<String, dynamic>.from(
                  entry.value as Map,
                );

                final position =
                    token[
                            'queue_position']
                        is num
                    ? (token[
                                'queue_position']
                            as num)
                        .toInt()
                    : index + 1;

                final tokenNumber =
                    token[
                                'token_number']
                            ?.toString() ??
                        '-';

                final visitor =
                    token[
                                'visitor_name']
                            ?.toString()
                            .isNotEmpty ==
                        true
                    ? token[
                            'visitor_name']
                        .toString()
                    : 'Visitor';

                final eta =
                    token['eta_minutes']
                            is num
                        ? (token[
                                    'eta_minutes']
                                as num)
                            .toInt()
                        : 0;

                final priority =
                    token['priority'] ==
                        true;

                return _queueItem(
                  position: position,
                  token: tokenNumber,
                  visitor: visitor,
                  eta: '$eta min',
                  priority: priority,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQueueError() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 25,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 30,
              color:
                  Color(0xFF6B7280),
            ),

            const SizedBox(height: 8),

            const Text(
              'Unable to load queue',
              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF374151),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              queueError!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    Color(0xFF9CA3AF),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: loadQueue,
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueue() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons
                  .people_outline_rounded,
              size: 32,
              color:
                  Color(0xFF9CA3AF),
            ),

            SizedBox(height: 8),

            Text(
              'No visitors waiting',
              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF4B5563),
              ),
            ),

            SizedBox(height: 4),

            Text(
              'The queue is currently empty.',
              style:
                  TextStyle(
                fontSize: 10,
                color:
                    Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUEUE ITEM
  // ============================================================

  Widget _queueItem({
    required int position,
    required String token,
    required String visitor,
    required String eta,
    required bool priority,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: LayoutBuilder(
        builder:
            (context, constraints) {
          final isMobile =
              constraints.maxWidth <
                  500;

          if (isMobile) {
            return Row(
              children: [
                SizedBox(
                  width: 65,
                  child: Text(
                    token,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(
                              0xFF111827),
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    visitor,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                              0xFF374151),
                    ),
                  ),
                ),

                SizedBox(
                  width: 65,
                  child: priority
                      ? Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                5,
                            vertical:
                                4,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                                    0xFFF3F4F6),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                          child:
                              const Text(
                            'YES',
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  Color(
                                      0xFF374151),
                            ),
                          ),
                        )
                      : const Text(
                          'No',
                          style:
                              TextStyle(
                            fontSize: 11,
                            color:
                                Color(
                                    0xFF9CA3AF),
                          ),
                        ),
                ),

                SizedBox(
                  width: 45,
                  child: Text(
                    eta,
                    textAlign:
                        TextAlign.right,
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(
                              0xFF374151),
                    ),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(
                width: 35,
                child: Text(
                  '$position',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Color(
                            0xFF6B7280),
                  ),
                ),
              ),

              SizedBox(
                width: 85,
                child: Text(
                  token,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                            0xFF111827),
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  visitor,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(
                            0xFF374151),
                  ),
                ),
              ),

              SizedBox(
                width: 80,
                child: priority
                    ? Container(
                        width: 60,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              6,
                          vertical:
                              4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                                  0xFFF3F4F6),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            5,
                          ),
                        ),
                        child:
                            const Text(
                          'PRIORITY',
                          textAlign:
                              TextAlign
                                  .center,
                          style:
                              TextStyle(
                            fontSize: 8,
                            fontWeight:
                                FontWeight
                                    .w700,
                            color:
                                Color(
                                    0xFF374151),
                          ),
                        ),
                      )
                    : const Text(
                        'Normal',
                        style:
                            TextStyle(
                          fontSize: 10,
                          color:
                              Color(
                                  0xFF9CA3AF),
                        ),
                      ),
              ),

              SizedBox(
                width: 65,
                child: Text(
                  eta,
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF374151),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // QUEUE HEADER
  // ============================================================

  Widget _queueHeader() {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final isMobile =
            constraints.maxWidth <
                500;

        if (isMobile) {
          return const Row(
            children: [
              SizedBox(
                width: 65,
                child: Text(
                  'TOKEN',
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF9CA3AF),
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  'VISITOR',
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF9CA3AF),
                  ),
                ),
              ),

              SizedBox(
                width: 65,
                child: Text(
                  'PRIORITY',
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF9CA3AF),
                  ),
                ),
              ),

              SizedBox(
                width: 45,
                child: Text(
                  'ETA',
                  textAlign:
                      TextAlign.right,
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          );
        }

        return const Row(
          children: [
            SizedBox(
              width: 35,
              child: Text(
                '#',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                          0xFF9CA3AF),
                ),
              ),
            ),

            SizedBox(
              width: 85,
              child: Text(
                'TOKEN',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                          0xFF9CA3AF),
                ),
              ),
            ),

            Expanded(
              child: Text(
                'VISITOR',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                          0xFF9CA3AF),
                ),
              ),
            ),

            SizedBox(
              width: 80,
              child: Text(
                'PRIORITY',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                          0xFF9CA3AF),
                ),
              ),
            ),

            SizedBox(
              width: 65,
              child: Text(
                'ETA',
                textAlign:
                    TextAlign.right,
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Color(
                          0xFF9CA3AF),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DEPARTMENT STATUS
  // ============================================================

  Widget _buildDepartmentStatus() {
    return Container(
      padding:
          const EdgeInsets.all(22),
      decoration:
          _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Department Status',
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Current availability of all departments',
            style:
                TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF9CA3AF),
            ),
          ),

          const SizedBox(height: 18),

          if (departmentsLoading)
            const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(15),
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder:
                  (context, constraints) {
                final width =
                    constraints.maxWidth;

                final columns =
                    width >= 900
                        ? 4
                        : width >= 550
                            ? 2
                            : 1;

                const spacing =
                    12.0;

                final itemWidth =
                    (width -
                            ((columns -
                                    1) *
                                spacing)) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children:
                      departments.map(
                    (department) {
                      final active =
                          department[
                                  'status'] ==
                              'Active';

                      return SizedBox(
                        width:
                            itemWidth,
                        child:
                            _departmentStatusItem(
                          department,
                          active,
                        ),
                      );
                    },
                  ).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _departmentStatusItem(
    Map<String, dynamic>
        department,
    bool active,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF9FAFB),
        borderRadius:
            BorderRadius.circular(9),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Icon(
              department['icon']
                  as IconData,
              size: 19,
              color:
                  const Color(
                      0xFF4B5563),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  department['name']
                      .toString(),
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                            0xFF111827),
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape
                                .circle,
                        color: active
                            ? const Color(
                                0xFF374151)
                            : const Color(
                                0xFF9CA3AF),
                      ),
                    ),

                    const SizedBox(
                        width: 5),

                    Text(
                      active
                          ? 'Active'
                          : 'Paused',
                      style:
                          TextStyle(
                        fontSize: 10,
                        color: active
                            ? const Color(
                                0xFF4B5563)
                            : const Color(
                                0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEPARTMENT MANAGEMENT
  // ============================================================

  Widget _buildDepartmentManagementSection() {
    final bool isAdmin =
        widget.user['role'] == 'ADMIN';

    if (!isAdmin) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration:
          _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Department Management',
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Admin can pause or resume departments.',
            style:
                TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF9CA3AF),
            ),
          ),

          const SizedBox(height: 18),

          ...departments.map(
            (department) =>
                buildDepartmentManagement(
              department,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDepartmentManagement(
    Map<String, dynamic>
        department,
  ) {
    final int departmentId =
        department['id'] as int;

    final String departmentName =
        department['name']
            .toString();

    final bool isPaused =
        department['status'] ==
            'Paused';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 0,
      color:
          const Color(0xFFF9FAFB),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(9),
        side:
            const BorderSide(
          color:
              Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              department['icon']
                  as IconData,
              size: 28,
              color:
                  const Color(
                      0xFF374151),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    departmentName,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      fontSize: 14,
                      color:
                          Color(
                              0xFF111827),
                    ),
                  ),

                  const SizedBox(
                      height: 4),

                  Text(
                    isPaused
                        ? 'Paused'
                        : 'Active',
                    style:
                        TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color: isPaused
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton(
              onPressed:
                  departmentsLoading
                      ? null
                      : () {
                          toggleDepartmentPause(
                            departmentId,
                            isPaused,
                          );
                        },
              child: Text(
                isPaused
                    ? 'Resume'
                    : 'Pause',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration:
          _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            size: 38,
            color:
                Color(0xFF6B7280),
          ),

          const SizedBox(height: 10),

          const Text(
            'Unable to load dashboard',
            style:
                TextStyle(
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            errorMessage ??
                'Unknown error',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton(
            onPressed:
                loadDashboard,
            child:
                const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'Smart Office Queue & Token Management System',
        style:
            TextStyle(
          fontSize: 11,
          color:
              Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON CARD STYLE
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(14),
      border: Border.all(
        color:
            const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withValues(
            alpha: 0.025,
          ),
          blurRadius: 8,
          offset:
              const Offset(0, 2),
        ),
      ],
    );
  }
}