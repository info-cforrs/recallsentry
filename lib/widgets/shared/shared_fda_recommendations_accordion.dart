import 'package:flutter/material.dart';

class SharedRecommendationsAccordion extends StatefulWidget {
  final String recommendationsActions;
  final String remedy;
  const SharedRecommendationsAccordion({
    required this.recommendationsActions,
    required this.remedy,
    super.key,
  });

  @override
  State<SharedRecommendationsAccordion> createState() =>
      _SharedRecommendationsAccordionState();
}

class _SharedRecommendationsAccordionState
    extends State<SharedRecommendationsAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recommendations',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.remove : Icons.add,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Builder(
                builder: (context) {
                  final hasRecommendations = widget.recommendationsActions
                      .trim()
                      .isNotEmpty;
                  final hasRemedy = widget.remedy.trim().isNotEmpty;
                  if (!hasRecommendations && !hasRemedy) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'No recommendations specified.',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                        textAlign: TextAlign.left,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendations/Actions:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasRecommendations
                            ? widget.recommendationsActions
                            : 'Not specified',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Remedy:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasRemedy ? widget.remedy : 'Not specified',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
