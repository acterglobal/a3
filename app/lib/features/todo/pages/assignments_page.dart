import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({Key? key}) : super(key: key);

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Atlas.arrow_left_circle,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'My assignments',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemBuilder: (context, index) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oct 19 at 3:36am',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Web application on design',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Owner: '),
                            Text('David Chunli'),
                          ],
                        ),
                        Row(
                          children: [
                            Text('View Assigned'),
                            SizedBox(width: 8),
                            Icon(Atlas.arrow_right_circle, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
