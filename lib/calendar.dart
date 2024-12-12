import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final String description;

  Event({
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.description,
  });
}

class CalendarPage {
  static Future<void> showEventDialog(BuildContext context) async {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();
    DateTime? _startDate;
    DateTime? _endDate;

    Future<void> _selectDate(BuildContext context, bool isStartDate) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      }
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Event'),
          content: Container(
            width: MediaQuery.of(context).size.width *
                0.4, // Adjust the width as needed
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    alignLabelWithHint:
                        true, // Ensures the label stays at the top
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint:
                        true, // Ensures the label stays at the top
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(_startDate == null
                          ? 'Select Start Date'
                          : 'Start Date: ${_startDate!.toLocal()}'
                              .split(' ')[0]),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(_endDate == null
                          ? 'Select End Date'
                          : 'End Date: ${_endDate!.toLocal()}'.split(' ')[0]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_startDate != null &&
                    _endDate != null &&
                    _titleController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty) {
                  // Sanitize the title to be used as a document ID
                  String sanitizedTitle = _titleController.text
                      .replaceAll('/', '')
                      .replaceAll('\\', '')
                      .replaceAll('.', '')
                      .replaceAll(' ', '_');

                  // Add the event to Firestore with the title as the document ID
                  await FirebaseFirestore.instance
                      .collection('CalendarEvents')
                      .doc(sanitizedTitle)
                      .set({
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'startDate': _startDate,
                    'endDate': _endDate,
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            )
          ],
        );
      },
    );
  }
}
