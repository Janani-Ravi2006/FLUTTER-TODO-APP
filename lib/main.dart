import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => DateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const TaskScreen(),
          );
        },
      ),
    );
  }
}

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do App"),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(context),
          const SizedBox(height: 10),
          _buildDatePicker(context),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                var selectedDate =
                    Provider.of<DateProvider>(context).selectedDate;
                var tasksForSelectedDate =
                    taskProvider.getTasksForDate(selectedDate);

                return tasksForSelectedDate.isEmpty
                    ? _buildEmptyTaskList()
                    : _buildTaskList(
                        tasksForSelectedDate, taskProvider, selectedDate);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    DateTime selectedDate = Provider.of<DateProvider>(context).selectedDate;
    String formattedDate = DateFormat('MMMM d, y').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formattedDate,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Selected Date",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showAddTaskDialog(context),
            child: const Text("+ Add Task"),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final dateProvider = Provider.of<DateProvider>(context);
    DateTime now = DateTime.now();

    // ✅ Fix: Show past 15 days and next 30 days to allow future months
    List<DateTime> weekDates =
        List.generate(45, (i) => now.add(Duration(days: i - 15)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: weekDates.map((date) {
          bool isSelected =
              DateUtils.isSameDay(dateProvider.selectedDate, date);
          return GestureDetector(
            onTap: () => dateProvider.setSelectedDate(date),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(DateFormat('MMM').format(date),
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black)),
                  const SizedBox(height: 5),
                  Text(date.day.toString(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black)),
                  const SizedBox(height: 5),
                  Text(DateFormat('EEE').format(date),
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyTaskList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 10),
          const Text("You do not have any tasks yet!",
              style: TextStyle(fontSize: 16)),
          const Text("Add new tasks to make your days productive.",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTaskList(
      List<String> tasks, TaskProvider taskProvider, DateTime selectedDate) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(tasks[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                taskProvider.removeTask(selectedDate, index);
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    TextEditingController taskController = TextEditingController();
    DateTime selectedDate =
        Provider.of<DateProvider>(context, listen: false).selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Task"),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: "Enter task name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .addTask(selectedDate, taskController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}

// Task Provider (Manages Task List for Specific Dates)
class TaskProvider extends ChangeNotifier {
  final Map<String, List<String>> _tasksByDate = {};

  List<String> getTasksForDate(DateTime date) {
    String key = DateFormat('yyyy-MM-dd').format(date);
    return _tasksByDate[key] ?? [];
  }

  void addTask(DateTime date, String task) {
    String key = DateFormat('yyyy-MM-dd').format(date);
    _tasksByDate.putIfAbsent(key, () => []).add(task);
    notifyListeners();
  }

  void removeTask(DateTime date, int index) {
    String key = DateFormat('yyyy-MM-dd').format(date);
    _tasksByDate[key]?.removeAt(index);
    notifyListeners();
  }
}

// Date Provider (Manages Selected Date)
class DateProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
