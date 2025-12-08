import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import '../services/api_service.dart';
import '../widgets/rmc_enrollment_card.dart';
import '../constants/rmc_status.dart';
import 'rmc_details_page.dart';
import 'completed_rmc_details_page.dart';
import 'main_navigation.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

class RmcStatusPage extends StatefulWidget {
  final List<RmcEnrollment>? filteredEnrollments;
  final String? pageTitle;
  final String? statusFilter;

  const RmcStatusPage({
    super.key,
    this.filteredEnrollments,
    this.pageTitle,
    this.statusFilter,
  });

  @override
  State<RmcStatusPage> createState() => _RmcStatusPageState();
}

class _RmcStatusPageState extends State<RmcStatusPage> with WidgetsBindingObserver, HideOnScrollMixin {
  List<RmcEnrollment> _enrollments = [];
  bool _isLoading = true;
  String? _error;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    WidgetsBinding.instance.addObserver(this);
    // Always load fresh data from API to ensure current status
    _loadActiveEnrollments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeHideOnScroll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data when app comes back to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      _loadActiveEnrollments();
    }
  }

  Future<void> _loadActiveEnrollments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<RmcEnrollment> enrollments;

      // If filtered enrollments were provided and this is the first load, use them
      // Otherwise, fetch fresh data from API
      if (widget.filteredEnrollments != null && !_hasLoadedOnce) {
        enrollments = widget.filteredEnrollments!;
      } else {
        // Fetch fresh data from API
        final allEnrollments = await ApiService().fetchActiveRmcEnrollments();

        // Apply appropriate filtering based on page title and status filter
        if (widget.pageTitle == 'In Progress') {
          // Apply "In Progress" filter: exclude Completed, Closed, Not Started, and pre-step statuses
          enrollments = allEnrollments.where((e) {
            final status = e.status.trim().toLowerCase();
            return status != 'closed' &&
                   status != 'completed' &&
                   status != 'not started' &&
                   status != 'stopped using' &&
                   status != 'mfr contacted';
          }).toList();
        } else if (widget.pageTitle == 'Completed') {
          // Apply "Completed" filter: include both Completed and Closed
          enrollments = allEnrollments.where((e) {
            final status = e.status.trim().toLowerCase();
            return status == 'completed' || status == 'closed';
          }).toList();
        } else if (widget.statusFilter != null) {
          // Apply exact status filter (case-insensitive)
          enrollments = allEnrollments.where((e) =>
            e.status.trim().toLowerCase() == widget.statusFilter!.trim().toLowerCase()
          ).toList();
        } else {
          // No filter, show all
          enrollments = allEnrollments;
        }
      }

      if (!mounted) return;

      setState(() {
        _enrollments = enrollments;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load RMC enrollments: $e';
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3547),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.pageTitle ?? 'RMC Status',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFF1D3547),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadActiveEnrollments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _enrollments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 80,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Active Recalls',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start managing a recall from the recall details page',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadActiveEnrollments,
                        child: Column(
                          children: [
                            // Instructional text for "Not Started" status
                            if (widget.statusFilter?.trim().toLowerCase() == 'not started')
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                color: const Color(0xFF2A4A5C),
                                child: const Text(
                                  'Clicking on a recall starts the recall process',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            // Recall cards list
                            Expanded(
                              child: ListView.builder(
                                controller: hideOnScrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _enrollments.length,
                                itemBuilder: (context, index) {
                                  final recall = _enrollments[index];
                                  return _buildRecallCard(recall);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2C3E50),
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: Colors.white54,
          currentIndex: 2,
          elevation: 8,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 0),
                  ),
                  (route) => false,
                );
                break;
              case 1:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 1),
                  ),
                  (route) => false,
                );
                break;
              case 2:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 2),
                  ),
                  (route) => false,
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecallCard(RmcEnrollment enrollment) {
    return FutureBuilder<RecallData>(
      future: ApiService().fetchRecallById(enrollment.recallId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF2A4A5C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final recall = snapshot.data!;

        return RmcEnrollmentCard(
          recall: recall,
          enrollment: enrollment,
          onTap: () async {
            // Check if enrollment is completed or closed using helper method
            final isCompleted = RmcStatus.isCompletion(enrollment.status);

            if (isCompleted) {
              // Navigate to Completed RMC Details page (timeline view)
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompletedRmcDetailsPage(
                    recall: recall,
                    enrollment: enrollment,
                  ),
                ),
              );
            } else {
              // Navigate to RMC Details page (active workflow page) for active enrollments
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RmcDetailsPage(
                    recall: recall,
                    enrollment: enrollment,
                  ),
                ),
              );
            }

            // Reload data after returning to reflect any status changes
            await _loadActiveEnrollments();
          },
        );
      },
    );
  }
}
