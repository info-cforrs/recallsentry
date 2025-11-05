import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/api_service.dart';
import '../widgets/usda_rmc_status_card.dart';
import 'usda_recall_details_pagev2.dart';

class RmcListPage extends StatefulWidget {
  final List<RecallData>? filteredRecalls;
  final String? pageTitle;

  const RmcListPage({
    super.key,
    this.filteredRecalls,
    this.pageTitle,
  });

  @override
  State<RmcListPage> createState() => _RmcListPageState();
}

class _RmcListPageState extends State<RmcListPage> {
  List<RecallData> _activeRecalls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // If filtered recalls are provided, use them; otherwise fetch all active recalls
    if (widget.filteredRecalls != null) {
      setState(() {
        _activeRecalls = widget.filteredRecalls!;
        _isLoading = false;
      });
    } else {
      _loadActiveRecalls();
    }
  }

  Future<void> _loadActiveRecalls() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch only active recalls from the backend (where status != 'Not Started')
      final activeRecalls = await ApiService().fetchActiveRecalls();

      setState(() {
        _activeRecalls = activeRecalls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load active recalls: $e';
        _isLoading = false;
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
          widget.pageTitle ?? 'Recall Management Center List',
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
                          onPressed: _loadActiveRecalls,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _activeRecalls.isEmpty
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
                        onRefresh: _loadActiveRecalls,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activeRecalls.length,
                          itemBuilder: (context, index) {
                            final recall = _activeRecalls[index];
                            return _buildRecallCard(recall);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildRecallCard(RecallData recall) {
    return GestureDetector(
      onTap: () {
        // Navigate to recall details page
        if (recall.agency == 'USDA') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UsdaRecallDetailsPageV2(recall: recall),
            ),
          );
        }
        // TODO: Add navigation for FDA, CPSC, NHTSA recalls when their pages are ready
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: USDARmcStatusCard(recall: recall),
      ),
    );
  }
}
