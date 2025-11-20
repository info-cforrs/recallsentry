import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class USStateMap extends StatelessWidget {
  final String productDistribution;
  final String? distributionMapUrl;

  const USStateMap({
    required this.productDistribution,
    this.distributionMapUrl,
    super.key,
  });

  // Parse state names from the product distribution text
  Set<String> _parseStates() {
    final text = productDistribution.toUpperCase();
    final states = <String>{};

    // Map of state names to abbreviations
    final stateMap = {
      'ALABAMA': 'AL', 'ALASKA': 'AK', 'ARIZONA': 'AZ', 'ARKANSAS': 'AR',
      'CALIFORNIA': 'CA', 'COLORADO': 'CO', 'CONNECTICUT': 'CT', 'DELAWARE': 'DE',
      'FLORIDA': 'FL', 'GEORGIA': 'GA', 'HAWAII': 'HI', 'IDAHO': 'ID',
      'ILLINOIS': 'IL', 'INDIANA': 'IN', 'IOWA': 'IA', 'KANSAS': 'KS',
      'KENTUCKY': 'KY', 'LOUISIANA': 'LA', 'MAINE': 'ME', 'MARYLAND': 'MD',
      'MASSACHUSETTS': 'MA', 'MICHIGAN': 'MI', 'MINNESOTA': 'MN', 'MISSISSIPPI': 'MS',
      'MISSOURI': 'MO', 'MONTANA': 'MT', 'NEBRASKA': 'NE', 'NEVADA': 'NV',
      'NEW HAMPSHIRE': 'NH', 'NEW JERSEY': 'NJ', 'NEW MEXICO': 'NM', 'NEW YORK': 'NY',
      'NORTH CAROLINA': 'NC', 'NORTH DAKOTA': 'ND', 'OHIO': 'OH', 'OKLAHOMA': 'OK',
      'OREGON': 'OR', 'PENNSYLVANIA': 'PA', 'RHODE ISLAND': 'RI', 'SOUTH CAROLINA': 'SC',
      'SOUTH DAKOTA': 'SD', 'TENNESSEE': 'TN', 'TEXAS': 'TX', 'UTAH': 'UT',
      'VERMONT': 'VT', 'VIRGINIA': 'VA', 'WASHINGTON': 'WA', 'WEST VIRGINIA': 'WV',
      'WISCONSIN': 'WI', 'WYOMING': 'WY',
    };

    // Check for full state names
    stateMap.forEach((stateName, abbrev) {
      if (text.contains(stateName)) {
        states.add(abbrev);
      }
    });

    // Check for state abbreviations
    final abbrevPattern = RegExp(r'\b([A-Z]{2})\b');
    final matches = abbrevPattern.allMatches(text);
    for (final match in matches) {
      final abbrev = match.group(1)!;
      if (stateMap.values.contains(abbrev)) {
        states.add(abbrev);
      }
    }

    // Check for "nationwide" or "all states"
    if (text.contains('NATIONWIDE') || text.contains('ALL STATES') ||
        text.contains('ALL 50 STATES') || text.contains('NATIONALLY')) {
      states.addAll(stateMap.values);
    }

    return states;
  }

  @override
  Widget build(BuildContext context) {
    final highlightedStates = _parseStates();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D3547),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 959 / 593,
          child: Stack(
            children: [
              // Display pre-rendered PNG if available, otherwise fall back to SVG
              Positioned.fill(
                child: (distributionMapUrl != null && distributionMapUrl!.isNotEmpty)
                    ? Image.network(
                        distributionMapUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to SVG if PNG fails to load
                          return _buildSVGMap(context, highlightedStates);
                        },
                      )
                    : _buildSVGMap(context, highlightedStates),
              ),
              // State count indicator badge at top
              _buildStateBadge(highlightedStates),
            ],
          ),
        ),
      ),
    );
  }

  // Build SVG map with dynamic state coloring (fallback method)
  Widget _buildSVGMap(BuildContext context, Set<String> highlightedStates) {
    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(context).loadString('assets/images/us_map.svg'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String svgString = snapshot.data!;

          // First, set all states to white
          svgString = svgString.replaceAllMapped(
            RegExp('<path([^>]*?)id="([A-Z]{2})"([^>]*?)(/?)>', caseSensitive: false),
            (match) {
              final beforeId = match.group(1) ?? '';
              final stateId = match.group(2) ?? '';
              final afterId = match.group(3) ?? '';
              final selfClosing = match.group(4) ?? '';

              // Remove any existing fill or fill-opacity attributes
              String cleaned = (beforeId + afterId)
                  .replaceAll(RegExp(r'\s*fill="[^"]*"'), '')
                  .replaceAll(RegExp(r'\s*fill-opacity="[^"]*"'), '');

              // Add white fill for all states
              return '<path$cleaned id="$stateId" fill="#FFFFFF" fill-opacity="0.8"$selfClosing>';
            },
          );

          // Then, override with red for highlighted states
          for (final state in highlightedStates) {
            svgString = svgString.replaceAllMapped(
              RegExp('<path([^>]*?)id="$state"([^>]*?)(/?)>', caseSensitive: false),
              (match) {
                final beforeId = match.group(1) ?? '';
                final afterId = match.group(2) ?? '';
                final selfClosing = match.group(3) ?? '';

                // Remove any existing fill or fill-opacity attributes
                String cleaned = (beforeId + afterId)
                    .replaceAll(RegExp(r'\s*fill="[^"]*"'), '')
                    .replaceAll(RegExp(r'\s*fill-opacity="[^"]*"'), '');

                // Add red fill attributes
                return '<path$cleaned id="$state" fill="#E53935" fill-opacity="0.7"$selfClosing>';
              },
            );
          }

          return SvgPicture.string(
            svgString,
            fit: BoxFit.contain,
          );
        } else if (snapshot.hasError) {
          return CustomPaint(
            painter: USMapPainter(highlightedStates: highlightedStates),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // Build state count badge overlay
  Widget _buildStateBadge(Set<String> highlightedStates) {
    if (highlightedStates.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE53935), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              highlightedStates.length == 50
                  ? 'All 50 States'
                  : '${highlightedStates.length} ${highlightedStates.length == 1 ? 'State' : 'States'} Affected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter to overlay red color on affected states
class StateHighlightPainter extends CustomPainter {
  final Set<String> highlightedStates;

  StateHighlightPainter({required this.highlightedStates});

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightedStates.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE53935).withValues(alpha: 0.6);

    // Get state paths scaled to widget size
    final statePaths = _getStatePaths(size);

    // Draw only highlighted states with red overlay
    for (final state in highlightedStates) {
      final path = statePaths[state];
      if (path != null) {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(StateHighlightPainter oldDelegate) {
    return oldDelegate.highlightedStates != highlightedStates;
  }

  // Same state path generation as USMapPainter
  Map<String, Path> _getStatePaths(Size size) {
    final scaleX = size.width / 2000;
    final scaleY = size.height / 1200;

    Path createPath(List<Offset> points) {
      final path = Path();
      if (points.isEmpty) return path;

      path.moveTo(points[0].dx * scaleX, points[0].dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      path.close();
      return path;
    }

    return {
      'WA': createPath([const Offset(60, 50), const Offset(220, 50), const Offset(220, 180), const Offset(60, 180)]),
      'OR': createPath([const Offset(60, 190), const Offset(220, 190), const Offset(220, 320), const Offset(60, 320)]),
      'CA': createPath([const Offset(60, 330), const Offset(180, 330), const Offset(200, 560), const Offset(180, 660), const Offset(60, 630)]),
      'MT': createPath([const Offset(230, 60), const Offset(490, 50), const Offset(490, 180), const Offset(230, 190)]),
      'ID': createPath([const Offset(230, 200), const Offset(360, 200), const Offset(370, 330), const Offset(230, 330)]),
      'WY': createPath([const Offset(370, 190), const Offset(580, 190), const Offset(580, 330), const Offset(380, 330)]),
      'NV': createPath([const Offset(190, 330), const Offset(360, 330), const Offset(350, 540), const Offset(210, 560)]),
      'UT': createPath([const Offset(370, 340), const Offset(480, 340), const Offset(480, 520), const Offset(360, 520)]),
      'CO': createPath([const Offset(490, 340), const Offset(700, 340), const Offset(700, 520), const Offset(490, 520)]),
      'AZ': createPath([const Offset(220, 570), const Offset(470, 550), const Offset(470, 720), const Offset(280, 740), const Offset(220, 680)]),
      'NM': createPath([const Offset(480, 530), const Offset(700, 530), const Offset(700, 740), const Offset(480, 740)]),
      'ND': createPath([const Offset(590, 70), const Offset(790, 70), const Offset(790, 160), const Offset(590, 160)]),
      'SD': createPath([const Offset(590, 170), const Offset(790, 170), const Offset(790, 300), const Offset(590, 300)]),
      'NE': createPath([const Offset(590, 310), const Offset(870, 310), const Offset(870, 430), const Offset(590, 430)]),
      'KS': createPath([const Offset(710, 440), const Offset(960, 440), const Offset(960, 560), const Offset(710, 560)]),
      'OK': createPath([const Offset(710, 570), const Offset(960, 570), const Offset(960, 690), const Offset(710, 690)]),
      'TX': createPath([const Offset(710, 700), const Offset(970, 700), const Offset(1010, 930), const Offset(920, 1020), const Offset(720, 980), const Offset(680, 820)]),
      'MN': createPath([const Offset(800, 100), const Offset(1000, 100), const Offset(1000, 230), const Offset(880, 240), const Offset(800, 200)]),
      'IA': createPath([const Offset(880, 250), const Offset(1060, 250), const Offset(1060, 380), const Offset(880, 380)]),
      'MO': createPath([const Offset(880, 390), const Offset(1110, 390), const Offset(1110, 530), const Offset(970, 530), const Offset(880, 500)]),
      'AR': createPath([const Offset(970, 540), const Offset(1110, 540), const Offset(1110, 660), const Offset(970, 660)]),
      'LA': createPath([const Offset(980, 670), const Offset(1140, 670), const Offset(1160, 780), const Offset(1020, 810), const Offset(980, 770)]),
      'WI': createPath([const Offset(1010, 90), const Offset(1140, 90), const Offset(1140, 250), const Offset(1070, 250), const Offset(1010, 230)]),
      'IL': createPath([const Offset(1070, 260), const Offset(1180, 260), const Offset(1180, 470), const Offset(1120, 480), const Offset(1070, 440)]),
      'MI': createPath([const Offset(1150, 100), const Offset(1280, 100), const Offset(1300, 180), const Offset(1260, 260), const Offset(1190, 250), const Offset(1150, 200)]),
      'IN': createPath([const Offset(1190, 270), const Offset(1280, 270), const Offset(1280, 430), const Offset(1190, 440)]),
      'OH': createPath([const Offset(1290, 270), const Offset(1410, 270), const Offset(1420, 400), const Offset(1290, 410)]),
      'KY': createPath([const Offset(1190, 450), const Offset(1430, 430), const Offset(1430, 510), const Offset(1190, 520)]),
      'TN': createPath([const Offset(1120, 490), const Offset(1430, 520), const Offset(1430, 600), const Offset(1120, 600)]),
      'MS': createPath([const Offset(1120, 610), const Offset(1230, 610), const Offset(1230, 770), const Offset(1150, 780), const Offset(1120, 740)]),
      'AL': createPath([const Offset(1240, 610), const Offset(1350, 610), const Offset(1370, 790), const Offset(1240, 790)]),
      'GA': createPath([const Offset(1360, 610), const Offset(1490, 610), const Offset(1510, 790), const Offset(1380, 790)]),
      'FL': createPath([const Offset(1380, 800), const Offset(1520, 800), const Offset(1600, 1000), const Offset(1550, 1080), const Offset(1440, 1040), const Offset(1380, 970)]),
      'SC': createPath([const Offset(1440, 570), const Offset(1570, 570), const Offset(1580, 660), const Offset(1500, 670), const Offset(1440, 640)]),
      'NC': createPath([const Offset(1440, 470), const Offset(1640, 470), const Offset(1640, 560), const Offset(1570, 560), const Offset(1440, 550)]),
      'VA': createPath([const Offset(1440, 420), const Offset(1650, 410), const Offset(1660, 460), const Offset(1440, 460)]),
      'WV': createPath([const Offset(1420, 410), const Offset(1520, 370), const Offset(1540, 430), const Offset(1430, 440)]),
      'PA': createPath([const Offset(1430, 280), const Offset(1630, 280), const Offset(1640, 380), const Offset(1530, 380), const Offset(1430, 360)]),
      'NY': createPath([const Offset(1440, 120), const Offset(1650, 120), const Offset(1660, 270), const Offset(1440, 270)]),
      'VT': createPath([const Offset(1670, 100), const Offset(1730, 100), const Offset(1730, 200), const Offset(1670, 200)]),
      'NH': createPath([const Offset(1740, 90), const Offset(1790, 90), const Offset(1790, 200), const Offset(1740, 200)]),
      'ME': createPath([const Offset(1740, 20), const Offset(1840, 20), const Offset(1860, 80), const Offset(1840, 190), const Offset(1800, 200), const Offset(1740, 160)]),
      'MA': createPath([const Offset(1670, 210), const Offset(1840, 210), const Offset(1850, 270), const Offset(1670, 270)]),
      'RI': createPath([const Offset(1820, 250), const Offset(1850, 250), const Offset(1850, 290), const Offset(1820, 290)]),
      'CT': createPath([const Offset(1670, 280), const Offset(1790, 280), const Offset(1790, 330), const Offset(1670, 330)]),
      'NJ': createPath([const Offset(1640, 290), const Offset(1700, 290), const Offset(1710, 380), const Offset(1650, 380)]),
      'DE': createPath([const Offset(1650, 350), const Offset(1680, 350), const Offset(1680, 400), const Offset(1650, 400)]),
      'MD': createPath([const Offset(1540, 390), const Offset(1660, 390), const Offset(1670, 420), const Offset(1540, 420)]),
      'AK': createPath([const Offset(40, 840), const Offset(220, 840), const Offset(230, 1000), const Offset(80, 1020), const Offset(40, 980)]),
      'HI': createPath([const Offset(250, 960), const Offset(390, 960), const Offset(390, 1040), const Offset(250, 1040)]),
    };
  }
}

// Fallback painter using simplified state shapes
class USMapPainter extends CustomPainter {
  final Set<String> highlightedStates;

  USMapPainter({required this.highlightedStates});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.5);

    // Get state paths
    final statePaths = _getStatePaths(size);

    // Draw all states
    for (final entry in statePaths.entries) {
      final state = entry.key;
      final path = entry.value;

      // Determine color
      if (highlightedStates.contains(state)) {
        final bounds = path.getBounds();
        paint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE53935),
            const Color(0xFFC62828),
          ],
        ).createShader(bounds);
      } else {
        paint.shader = null;
        paint.color = Colors.grey.withValues(alpha: 0.25);
      }

      canvas.drawPath(path, paint);
      canvas.drawPath(path, borderPaint);
    }
  }

  Map<String, Path> _getStatePaths(Size size) {
    final scaleX = size.width / 2000;
    final scaleY = size.height / 1200;

    Path createPath(List<Offset> points) {
      final path = Path();
      if (points.isEmpty) return path;

      path.moveTo(points[0].dx * scaleX, points[0].dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      path.close();
      return path;
    }

    return {
      'WA': createPath([const Offset(60, 50), const Offset(220, 50), const Offset(220, 180), const Offset(60, 180)]),
      'OR': createPath([const Offset(60, 190), const Offset(220, 190), const Offset(220, 320), const Offset(60, 320)]),
      'CA': createPath([const Offset(60, 330), const Offset(180, 330), const Offset(200, 560), const Offset(180, 660), const Offset(60, 630)]),
      'MT': createPath([const Offset(230, 60), const Offset(490, 50), const Offset(490, 180), const Offset(230, 190)]),
      'ID': createPath([const Offset(230, 200), const Offset(360, 200), const Offset(370, 330), const Offset(230, 330)]),
      'WY': createPath([const Offset(370, 190), const Offset(580, 190), const Offset(580, 330), const Offset(380, 330)]),
      'NV': createPath([const Offset(190, 330), const Offset(360, 330), const Offset(350, 540), const Offset(210, 560)]),
      'UT': createPath([const Offset(370, 340), const Offset(480, 340), const Offset(480, 520), const Offset(360, 520)]),
      'CO': createPath([const Offset(490, 340), const Offset(700, 340), const Offset(700, 520), const Offset(490, 520)]),
      'AZ': createPath([const Offset(220, 570), const Offset(470, 550), const Offset(470, 720), const Offset(280, 740), const Offset(220, 680)]),
      'NM': createPath([const Offset(480, 530), const Offset(700, 530), const Offset(700, 740), const Offset(480, 740)]),
      'ND': createPath([const Offset(590, 70), const Offset(790, 70), const Offset(790, 160), const Offset(590, 160)]),
      'SD': createPath([const Offset(590, 170), const Offset(790, 170), const Offset(790, 300), const Offset(590, 300)]),
      'NE': createPath([const Offset(590, 310), const Offset(870, 310), const Offset(870, 430), const Offset(590, 430)]),
      'KS': createPath([const Offset(710, 440), const Offset(960, 440), const Offset(960, 560), const Offset(710, 560)]),
      'OK': createPath([const Offset(710, 570), const Offset(960, 570), const Offset(960, 690), const Offset(710, 690)]),
      'TX': createPath([const Offset(710, 700), const Offset(970, 700), const Offset(1010, 930), const Offset(920, 1020), const Offset(720, 980), const Offset(680, 820)]),
      'MN': createPath([const Offset(800, 100), const Offset(1000, 100), const Offset(1000, 230), const Offset(880, 240), const Offset(800, 200)]),
      'IA': createPath([const Offset(880, 250), const Offset(1060, 250), const Offset(1060, 380), const Offset(880, 380)]),
      'MO': createPath([const Offset(880, 390), const Offset(1110, 390), const Offset(1110, 530), const Offset(970, 530), const Offset(880, 500)]),
      'AR': createPath([const Offset(970, 540), const Offset(1110, 540), const Offset(1110, 660), const Offset(970, 660)]),
      'LA': createPath([const Offset(980, 670), const Offset(1140, 670), const Offset(1160, 780), const Offset(1020, 810), const Offset(980, 770)]),
      'WI': createPath([const Offset(1010, 90), const Offset(1140, 90), const Offset(1140, 250), const Offset(1070, 250), const Offset(1010, 230)]),
      'IL': createPath([const Offset(1070, 260), const Offset(1180, 260), const Offset(1180, 470), const Offset(1120, 480), const Offset(1070, 440)]),
      'MI': createPath([const Offset(1150, 100), const Offset(1280, 100), const Offset(1300, 180), const Offset(1260, 260), const Offset(1190, 250), const Offset(1150, 200)]),
      'IN': createPath([const Offset(1190, 270), const Offset(1280, 270), const Offset(1280, 430), const Offset(1190, 440)]),
      'OH': createPath([const Offset(1290, 270), const Offset(1410, 270), const Offset(1420, 400), const Offset(1290, 410)]),
      'KY': createPath([const Offset(1190, 450), const Offset(1430, 430), const Offset(1430, 510), const Offset(1190, 520)]),
      'TN': createPath([const Offset(1120, 490), const Offset(1430, 520), const Offset(1430, 600), const Offset(1120, 600)]),
      'MS': createPath([const Offset(1120, 610), const Offset(1230, 610), const Offset(1230, 770), const Offset(1150, 780), const Offset(1120, 740)]),
      'AL': createPath([const Offset(1240, 610), const Offset(1350, 610), const Offset(1370, 790), const Offset(1240, 790)]),
      'GA': createPath([const Offset(1360, 610), const Offset(1490, 610), const Offset(1510, 790), const Offset(1380, 790)]),
      'FL': createPath([const Offset(1380, 800), const Offset(1520, 800), const Offset(1600, 1000), const Offset(1550, 1080), const Offset(1440, 1040), const Offset(1380, 970)]),
      'SC': createPath([const Offset(1440, 570), const Offset(1570, 570), const Offset(1580, 660), const Offset(1500, 670), const Offset(1440, 640)]),
      'NC': createPath([const Offset(1440, 470), const Offset(1640, 470), const Offset(1640, 560), const Offset(1570, 560), const Offset(1440, 550)]),
      'VA': createPath([const Offset(1440, 420), const Offset(1650, 410), const Offset(1660, 460), const Offset(1440, 460)]),
      'WV': createPath([const Offset(1420, 410), const Offset(1520, 370), const Offset(1540, 430), const Offset(1430, 440)]),
      'PA': createPath([const Offset(1430, 280), const Offset(1630, 280), const Offset(1640, 380), const Offset(1530, 380), const Offset(1430, 360)]),
      'NY': createPath([const Offset(1440, 120), const Offset(1650, 120), const Offset(1660, 270), const Offset(1440, 270)]),
      'VT': createPath([const Offset(1670, 100), const Offset(1730, 100), const Offset(1730, 200), const Offset(1670, 200)]),
      'NH': createPath([const Offset(1740, 90), const Offset(1790, 90), const Offset(1790, 200), const Offset(1740, 200)]),
      'ME': createPath([const Offset(1740, 20), const Offset(1840, 20), const Offset(1860, 80), const Offset(1840, 190), const Offset(1800, 200), const Offset(1740, 160)]),
      'MA': createPath([const Offset(1670, 210), const Offset(1840, 210), const Offset(1850, 270), const Offset(1670, 270)]),
      'RI': createPath([const Offset(1820, 250), const Offset(1850, 250), const Offset(1850, 290), const Offset(1820, 290)]),
      'CT': createPath([const Offset(1670, 280), const Offset(1790, 280), const Offset(1790, 330), const Offset(1670, 330)]),
      'NJ': createPath([const Offset(1640, 290), const Offset(1700, 290), const Offset(1710, 380), const Offset(1650, 380)]),
      'DE': createPath([const Offset(1650, 350), const Offset(1680, 350), const Offset(1680, 400), const Offset(1650, 400)]),
      'MD': createPath([const Offset(1540, 390), const Offset(1660, 390), const Offset(1670, 420), const Offset(1540, 420)]),
      'AK': createPath([const Offset(40, 840), const Offset(220, 840), const Offset(230, 1000), const Offset(80, 1020), const Offset(40, 980)]),
      'HI': createPath([const Offset(250, 960), const Offset(390, 960), const Offset(390, 1040), const Offset(250, 1040)]),
    };
  }

  @override
  bool shouldRepaint(USMapPainter oldDelegate) {
    return oldDelegate.highlightedStates != highlightedStates;
  }
}
