import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priority Scheduler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SchedulerHomePage(),
    );
  }
}

class Process {
  String pid;
  int arrivalTime;
  int burstTime;
  int priority;

  Process(this.pid, this.arrivalTime, this.burstTime, this.priority);
}

class Result {
  final String pid;
  final int tat;
  final int wt;
  final int rt;
  final double averageTat;
  final double averageWt;
  final double averageRt;
  Result(
    this.pid,
    this.tat,
    this.wt,
    this.rt,
    this.averageTat,
    this.averageWt,
    this.averageRt,
  );
}

class ScheduledProcess {
  final String pid;
  final int startTime;
  final int endTime;

  ScheduledProcess(this.pid, this.startTime, this.endTime);
}

class SchedulerHomePage extends StatefulWidget {
  @override
  _SchedulerHomePageState createState() => _SchedulerHomePageState();
}

class _SchedulerHomePageState extends State<SchedulerHomePage> {
  final _formKey = GlobalKey<FormState>();
  final List<Process> _processes = [];
  List<Result> _results = [];
  List<ScheduledProcess> _gantt = [];

  final _pidController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _burstController = TextEditingController();
  final _priorityController = TextEditingController();

  void _addProcess() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _processes.add(
          Process(
            _pidController.text,
            int.parse(_arrivalController.text),
            int.parse(_burstController.text),
            int.parse(_priorityController.text),
          ),
        );
        _pidController.clear();
        _arrivalController.clear();
        _burstController.clear();
        _priorityController.clear();
      });
    }
  }

  void _runScheduler() {
    final n = _processes.length;
    List<int> remainingTime = _processes.map((p) => p.burstTime).toList();
    List<int?> startTimes = List.filled(n, null);
    List<int?> completionTimes = List.filled(n, null);

    List<ScheduledProcess> gantt = [];
    int currentTime = 0;
    int? lastProcessIndex;

    while (completionTimes.contains(null)) {
      List<int> readyIndices = [];
      for (int i = 0; i < n; i++) {
        if (_processes[i].arrivalTime <= currentTime && remainingTime[i] > 0) {
          readyIndices.add(i);
        }
      }

      if (readyIndices.isEmpty) {
        currentTime++;
        continue;
      }

      readyIndices.sort(
        (a, b) => _processes[a].priority.compareTo(_processes[b].priority),
      );
      int currentIndex = readyIndices.first;

      if (lastProcessIndex != currentIndex) {
        gantt.add(
          ScheduledProcess(
            _processes[currentIndex].pid,
            currentTime,
            currentTime + 1,
          ),
        );
      } else {
        gantt[gantt.length - 1] = ScheduledProcess(
          _processes[currentIndex].pid,
          gantt.last.startTime,
          currentTime + 1,
        );
      }

      if (startTimes[currentIndex] == null) {
        startTimes[currentIndex] = currentTime;
      }

      remainingTime[currentIndex]--;
      currentTime++;

      if (remainingTime[currentIndex] == 0) {
        completionTimes[currentIndex] = currentTime;
      }

      lastProcessIndex = currentIndex;
    }

    List<Result> results = [];
    int totalTat = 0;
    int totalWt = 0;
    int totalRt = 0;

    for (int i = 0; i < n; i++) {
      int tat = completionTimes[i]! - _processes[i].arrivalTime;
      int wt = tat - _processes[i].burstTime;
      int rt = startTimes[i]! - _processes[i].arrivalTime;

      totalTat += tat;
      totalWt += wt;
      totalRt += rt;
    }
    double averageTat = totalTat / n;
    double averageWt = totalWt / n;
    double averageRt = totalRt / n;

    for (int i = 0; i < n; i++) {
      int tat = completionTimes[i]! - _processes[i].arrivalTime;
      int wt = tat - _processes[i].burstTime;
      int rt = startTimes[i]! - _processes[i].arrivalTime;
      results.add(
        Result(
          _processes[i].pid,
          tat,
          wt,
          rt,
          averageTat,
          averageWt,
          averageRt,
        ),
      );
    }

    setState(() {
      _results = results;
      _gantt = gantt;
    });
  }

  _getGanttElements() {
    final Map<String, Color> processColors = {};
    final List<Color> colorPalette = [
      Colors.blue.shade300,
      Colors.green.shade200,
      Colors.orange.shade300,
      Colors.deepPurple.shade200,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.amber.shade200,
      Colors.cyan.shade600,
      Colors.indigo.shade300,
      Colors.pink.shade300,
    ];
    int colorIndex = 0;
    var endTime;
    int totalDuration = _gantt.last.endTime.toInt();
    List<Column> ganttElements = [];
    ganttElements.addAll(
      _gantt.map((e) {
        endTime = e.endTime;
        if (!processColors.containsKey(e.pid)) {
          processColors[e.pid] = colorPalette[colorIndex % colorPalette.length];
          colorIndex++;
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: (40 * (e.endTime - e.startTime) / totalDuration) * 10,
                height: 50,
                margin: EdgeInsets.symmetric(horizontal: 1),
                color: processColors[e.pid],
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16, // Larger font for 'P'
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '${e.pid}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12, // Smaller font for pid
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text('${e.startTime}', style: TextStyle(color: Colors.black)),
          ],
        );
      }).toList(),
    );
    ganttElements.add(
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 50,
              margin: EdgeInsets.symmetric(horizontal: 1),
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Text("", style: TextStyle(color: Colors.white)),
            ),
          ),
          Text('$endTime', style: TextStyle(color: Colors.black)),
        ],
      ),
    );
    return ganttElements;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Preemptive Priority Scheduling')),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomInputField(
                      controller: _pidController,
                      labelText: 'Process ID',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter PID';
                        }
                        if (_processes.any((p) => p.pid == value)) {
                          return 'PID must be unique';
                        }
                        return null;
                      },
                    ),

                    CustomInputField(
                      controller: _arrivalController,
                      labelText: 'Arrival Time',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a time';
                        }
                        if (int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a positive number';
                        }
                        return null;
                      },
                    ),
                    CustomInputField(
                      controller: _burstController,
                      labelText: 'Burst Time',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a time';
                        }
                        if (int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a positive number';
                        }
                        return null;
                      },
                    ),
                    CustomInputField(
                      controller: _priorityController,
                      labelText: 'Priority',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter Priority';
                        }
                        if (int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a positive number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addProcess,
                      child: Text('Add Process'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _runScheduler,
                      child: Text('Run Scheduler'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Process List",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ..._processes.map(
                (p) => Text(
                  '${p.pid}: Arrival=${p.arrivalTime}, Burst=${p.burstTime}, Priority=${p.priority}',
                ),
              ),
              SizedBox(height: 20),
              if (_results.isNotEmpty) ...[
                Text("Results", style: Theme.of(context).textTheme.titleLarge),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('PID')),
                    DataColumn(label: Text('TAT')),
                    DataColumn(label: Text('WT')),
                    DataColumn(label: Text('RT')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    // Show all individual results
                    ..._results.map(
                      (res) => DataRow(
                        cells: [
                          DataCell(Text(res.pid)),
                          DataCell(Text(res.tat.toString())),
                          DataCell(Text(res.wt.toString())),
                          DataCell(Text(res.rt.toString())),
                          const DataCell(
                            Text(''),
                          ), // Leave average column blank
                        ],
                      ),
                    ),
                    // Add one row for the average values
                    DataRow(
                      cells: [
                        const DataCell(
                          Text(
                            'Average',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(_results.first.averageTat.toStringAsFixed(2)),
                        ),
                        DataCell(
                          Text(_results.first.averageWt.toStringAsFixed(2)),
                        ),
                        DataCell(
                          Text(_results.first.averageRt.toStringAsFixed(2)),
                        ),
                        const DataCell(
                          Text(''),
                        ), // Optionally remove or use for notes
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  "Gantt Chart",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _getGanttElements()),
                ),
              ],
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  const CustomInputField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 400,
        // height: 100,
        child: TextFormField(
          controller: controller,
          validator:
              validator ?? (value) => value!.isEmpty ? 'Enter a value' : null,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.deepPurple),
          decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 8.0,
            ),
          ),
        ),
      ),
    );
  }
}
