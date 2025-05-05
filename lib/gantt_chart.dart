import 'package:flutter/material.dart';
import 'package:material_charts/material_charts.dart';

import 'main.dart';

class ProcessGanttData extends GanttData {
  final String processId;

  ProcessGanttData({
    required this.processId,
    required DateTime startDate,
    required DateTime endDate,
    required String label,
    required Color color,
    String? description,
    IconData? icon,
    String? tapContent,
  }) : super(
         startDate: startDate,
         endDate: endDate,
         label: label,
         description: description ?? '',
         color: color,
         icon: icon,
         tapContent: tapContent,
       );
}

// Function to convert your Process objects to GanttData objects
List<ProcessGanttData> convertToGanttData(
  List<ScheduledProcess> scheduledProcesses,
) {
  // Create a color map for processes
  final Map<String, Color> processColors = {};
  final List<Color> colorPalette = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
    Colors.pink,
  ];

  int colorIndex = 0;

  // First pass to assign colors
  for (var process in scheduledProcesses) {
    if (!processColors.containsKey(process.pid)) {
      processColors[process.pid] =
          colorPalette[colorIndex % colorPalette.length];
      colorIndex++;
    }
  }

  // Convert to GanttData objects
  return scheduledProcesses.map((process) {
    // Use a reference date (e.g., January 1, 2024)
    final baseDate = DateTime.now();
    final startDate = baseDate.add(Duration(hours: process.startTime));
    final endDate = baseDate.add(Duration(hours: process.endTime));

    return ProcessGanttData(
      processId: process.pid,
      startDate: startDate,
      endDate: endDate,
      label: 'Process ${process.pid}',
      description: 'Start: ${process.startTime}h, End: ${process.endTime}h',
      color: processColors[process.pid]!,
      icon: Icons.memory,
      tapContent:
          'Process ${process.pid} execution time: ${process.endTime - process.startTime} hours',
    );
  }).toList();
}

Widget buildGanttChart(List<ScheduledProcess> scheduledProcesses) {
  final ganttData = convertToGanttData(scheduledProcesses);

  const style = GanttChartStyle(
    lineColor: Color.fromRGBO(96, 125, 139, 1),
    lineWidth: 6,
    pointRadius: 5,
    connectionLineWidth: 2,
    showConnections: true,
    pointColor: Colors.blue,
    connectionLineColor: Colors.grey,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    dateStyle: TextStyle(fontSize: 12, color: Colors.grey),
    animationDuration: Duration(seconds: 1),
    animationCurve: Curves.easeInOut,
    verticalSpacing: 60.0,
  );

  return MaterialGanttChart(
    data: ganttData,
    width: 600,
    height: 300,
    style: style,
    onPointTap: (point) {
      if (point is ProcessGanttData) {
        debugPrint('Tapped on Process ${point.processId}');
      }
    },
  );
}

// Custom Gantt chart specific for process scheduling visualization
class ProcessScheduleGantt extends StatelessWidget {
  final List<ScheduledProcess> scheduledProcesses;

  const ProcessScheduleGantt({Key? key, required this.scheduledProcesses})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the maximum end time to determine the chart width
    int maxEndTime = 0;
    for (var process in scheduledProcesses) {
      if (process.endTime > maxEndTime) {
        maxEndTime = process.endTime;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Process Execution Timeline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(height: 300, child: buildGanttChart(scheduledProcesses)),
        const SizedBox(height: 20),
        _buildLegend(context, scheduledProcesses),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, List<ScheduledProcess> processes) {
    // Create a set of unique process IDs
    final Set<String> uniqueProcessIds = processes.map((p) => p.pid).toSet();

    // Create a color map for processes (same logic as in convertToGanttData)
    final Map<String, Color> processColors = {};
    final List<Color> colorPalette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
      Colors.pink,
    ];

    int colorIndex = 0;
    for (var pid in uniqueProcessIds) {
      processColors[pid] = colorPalette[colorIndex % colorPalette.length];
      colorIndex++;
    }

    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children:
          uniqueProcessIds.map((pid) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: processColors[pid]),
                const SizedBox(width: 8),
                Text(
                  'Process $pid',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }).toList(),
    );
  }
}

// For compatibility with your existing code - renamed to avoid conflict
Widget createGanttChartFromProcesses(List<Process> processes) {
  // This is a simplified version that doesn't reflect actual preemptive scheduling
  // It's just for demonstration when you don't have scheduled data yet

  final List<ScheduledProcess> scheduledProcesses = [];
  int currentTime = 0;

  for (var process in processes) {
    if (process.arrivalTime > currentTime) {
      currentTime = process.arrivalTime;
    }

    scheduledProcesses.add(
      ScheduledProcess(
        process.pid,
        currentTime,
        currentTime + process.burstTime,
      ),
    );

    currentTime += process.burstTime;
  }

  return ProcessScheduleGantt(scheduledProcesses: scheduledProcesses);
}
