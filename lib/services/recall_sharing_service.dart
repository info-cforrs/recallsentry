import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_data.dart';

class RecallSharingService {
  /// Generate a shareable text message for a recall
  String generateShareText(RecallData recall) {
    final buffer = StringBuffer();

    buffer.writeln('🚨 Recall Alert: ${recall.productName}');
    buffer.writeln();
    buffer.writeln('Brand: ${recall.brandName}');
    buffer.writeln('Category: ${recall.category}');
    buffer.writeln('Date Issued: ${_formatDate(recall.dateIssued)}');

    if (recall.riskLevel.isNotEmpty) {
      buffer.writeln('Risk Level: ${recall.riskLevel}');
    }

    if (recall.recallClassification.isNotEmpty) {
      buffer.writeln('Classification: ${recall.recallClassification}');
    }

    if (recall.description.isNotEmpty && recall.description.length < 200) {
      buffer.writeln();
      buffer.writeln('Description: ${recall.description}');
    }

    if (recall.recallUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('More info: ${recall.recallUrl}');
    }

    buffer.writeln();
    buffer.writeln('Shared from RecallSentry');

    return buffer.toString();
  }

  /// Generate email body content for a recall
  String generateEmailBody(RecallData recall) {
    final buffer = StringBuffer();

    buffer.writeln('I wanted to share this important recall information with you:');
    buffer.writeln();
    buffer.writeln('Product: ${recall.productName}');
    buffer.writeln('Brand: ${recall.brandName}');
    buffer.writeln('Category: ${recall.category}');
    buffer.writeln('Date Issued: ${_formatDate(recall.dateIssued)}');

    if (recall.riskLevel.isNotEmpty) {
      buffer.writeln('Risk Level: ${recall.riskLevel}');
    }

    if (recall.recallClassification.isNotEmpty) {
      buffer.writeln('Classification: ${recall.recallClassification}');
    }

    if (recall.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Description:');
      buffer.writeln(recall.description);
    }

    if (recall.recommendations.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Recommendations:');
      buffer.writeln(recall.recommendations);
    }

    if (recall.recallUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('For more information, visit:');
      buffer.writeln(recall.recallUrl);
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Shared from RecallSentry - Your Recall Safety Companion');

    return buffer.toString();
  }

  /// Generate email subject for a recall
  String generateEmailSubject(RecallData recall) {
    return 'Recall Alert: ${recall.brandName} ${recall.productName}';
  }

  /// Share recall via email
  Future<bool> shareViaEmail(RecallData recall, {String? recipientEmail}) async {
    try {
      final subject = Uri.encodeComponent(generateEmailSubject(recall));
      final body = Uri.encodeComponent(generateEmailBody(recall));

      final emailUrl = recipientEmail != null && recipientEmail.isNotEmpty
          ? 'mailto:$recipientEmail?subject=$subject&body=$body'
          : 'mailto:?subject=$subject&body=$body';

      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Share recall via SMS
  Future<bool> shareViaSMS(RecallData recall, {String? phoneNumber}) async {
    try {
      final message = Uri.encodeComponent(generateShareText(recall));

      final smsUrl = phoneNumber != null && phoneNumber.isNotEmpty
          ? 'sms:$phoneNumber?body=$message'
          : 'sms:?body=$message';

      final uri = Uri.parse(smsUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Show share dialog with multiple options
  void showShareDialog(BuildContext context, RecallData recall) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.share, color: Color(0xFF64B5F6)),
              SizedBox(width: 12),
              Text(
                'Share Recall',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose how you would like to share this recall:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              // Email option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.email,
                    color: Color(0xFF64B5F6),
                  ),
                ),
                title: const Text(
                  'Email',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Send via email app',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  final success = await shareViaEmail(recall);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Opening email app...'
                              : 'Could not open email app',
                        ),
                        backgroundColor: success
                            ? const Color(0xFF4CAF50)
                            : Colors.red,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              // SMS option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sms,
                    color: Color(0xFF64B5F6),
                  ),
                ),
                title: const Text(
                  'Text Message',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Send via SMS',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  final success = await shareViaSMS(recall);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Opening messaging app...'
                              : 'Could not open messaging app',
                        ),
                        backgroundColor: success
                            ? const Color(0xFF4CAF50)
                            : Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
