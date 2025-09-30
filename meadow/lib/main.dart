import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:meadow/controllers/app_settings_controller.dart';
import 'package:meadow/controllers/tasks_controller.dart';
import 'package:meadow/controllers/theme_controller.dart';
import 'package:meadow/controllers/video_transcript_controller.dart';
import 'package:meadow/controllers/workspace_controller.dart';
import 'package:meadow/controllers/model_manager_controller.dart';
import 'package:meadow/integrations/comfyui/comfyui_service.dart';
import 'package:meadow/services/update_check_service.dart';
import 'package:meadow/widgets/pages/main_layout.dart';
import 'package:flutter/foundation.dart';

void main() {
  // Initialize controllers
  Get.put(ThemeController());
  Get.put(WorkspaceController());
  Get.put(AppSettingsController());
  Get.put(TasksController());
  Get.put(VideoTranscriptController());

  // Initialize ModelManagerController only on desktop platforms
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    Get.put(ModelManagerController());
  }

  // Initialize simplified ComfyUI service
  Get.put(ComfyUIService());

  // Initialize update check service
  Get.put(UpdateCheckService());

  runApp(const MyApp());
}

const Color lightPrimary = Color(0xFFf74780); // Apple Blue
const Color lightAccent = Color(0xFFFF9500); // Apple Orange
const Color lightBackground = Color(0xFFF2F2F7); // Apple System Gray 6
const Color lightSurface = Colors.white;
const Color lightOnPrimary = Colors.white;
const Color lightOnSecondary = Colors.black;
const Color lightOnBackground = Color(0xFF1C1C1E); // Apple System Gray (Dark)
const Color lightOnSurface = Color(0xFF1C1C1E); // Apple System Gray (Dark)

const Color darkPrimary = Color(0xFFf74780); // Apple Blue (Dark Mode)
const Color darkAccent = Color(0xFFFF9F0A); // Apple Orange (Dark Mode)
const Color darkBackground = Color(0xFF000000);
const Color darkSurface = Color(0xFF1C1C1E); // Apple System Gray (Dark)
const Color darkOnPrimary = Colors.white;
const Color darkOnSecondary = Colors.black;
const Color darkOnBackground = Color(0xFFE5E5EA); // Apple System Gray 6 (Light)
const Color darkOnSurface = Color(0xFFE5E5EA); // Apple System Gray 6 (Light)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get theme controller
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meadow Studio',
        themeMode: themeController.themeMode.value,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: lightPrimary,
          scaffoldBackgroundColor: lightBackground,
          appBarTheme: const AppBarTheme(
            backgroundColor:
                Colors.white, // Or lightPrimary for a colored AppBar
            foregroundColor: lightOnSurface, // Text/icon color on AppBar
            elevation: 0.5,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold, // Slightly less bold
              color: lightOnSurface,
            ),
            iconTheme: IconThemeData(color: lightPrimary), // Icons in AppBar
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: lightPrimary,
            unselectedLabelColor: Colors.grey, // Softer unselected color
            indicatorColor: lightPrimary,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: lightPrimary,
            onPrimary: lightOnPrimary,
            secondary: lightAccent,
            onSecondary: lightOnSecondary,
            error: Colors.redAccent,
            onError: Colors.white,
            surface: lightSurface,
            onSurface: lightOnSurface,
          ),
          chipTheme: ChipThemeData(
            backgroundColor:
                Colors.transparent, // Unselected: transparent like tabs
            selectedColor: lightPrimary, // Selected: primary color
            labelStyle: const TextStyle(
              color: lightPrimary, // Selected: primary color
              fontWeight: FontWeight.bold, // Bold like tab
              fontSize: 14, // Adjust to match tab font size
            ),
            secondaryLabelStyle: const TextStyle(
              color: Colors.grey, // Unselected: grey like tab
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            side: const BorderSide(
              color: Colors.transparent, // No border, like tabs
              width: 0,
            ),

            disabledColor: Colors.grey.shade300,
            selectedShadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            brightness: Brightness.light,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            //filled: true,
            //fillColor: Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: lightPrimary, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.grey, width: 1.0),
            ),
            hintStyle: TextStyle(color: Colors.grey),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          dividerTheme: const DividerThemeData(
            color: Colors.grey,
            thickness: 0.5,
            space: 8,
          ),
          listTileTheme: ListTileThemeData(
            style: ListTileStyle.drawer, // Use drawer style for better spacing
            subtitleTextStyle: TextStyle(
              color: Colors.grey, // Softer subtitle color
            ),
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: darkPrimary,
          scaffoldBackgroundColor: darkBackground,
          appBarTheme: const AppBarTheme(
            backgroundColor: darkSurface, // Or darkPrimary
            foregroundColor: darkOnSurface,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkOnSurface,
            ),
            iconTheme: IconThemeData(color: darkPrimary),
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: darkPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: darkPrimary,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          colorScheme: const ColorScheme(
            brightness: Brightness.dark,
            primary: darkPrimary,
            onPrimary: darkOnPrimary,
            secondary: darkAccent,
            onSecondary: darkOnSecondary,
            error: Colors.red,
            onError: Colors.white,
            surface: darkSurface,
            onSurface: darkOnSurface,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey.shade800,
            selectedColor: darkPrimary,
            secondarySelectedColor: Colors.grey.shade800,
            labelStyle: const TextStyle(
              color: darkPrimary,
              fontWeight: FontWeight.w600,
            ),
            secondaryLabelStyle: const TextStyle(color: Colors.grey),
            disabledColor: Colors.grey.shade700,
            selectedShadowColor: Colors.transparent,
            side: const BorderSide(
              color: darkPrimary,
              width: 1.0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            brightness: Brightness.dark,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: darkPrimary, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              borderSide: BorderSide(color: Colors.grey, width: 1.0),
            ),
            hintStyle: TextStyle(color: Colors.grey),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          dividerTheme: const DividerThemeData(
            color: Colors.grey,
            thickness: 0.5,
            space: 8,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const MainLayout(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
