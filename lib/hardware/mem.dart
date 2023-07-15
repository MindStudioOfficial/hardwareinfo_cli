import 'dart:io';

class MemoryModule {
  final int capacity;
  final int speed;
  final String deviceLocator;

  MemoryModule({
    required this.capacity,
    required this.speed,
    required this.deviceLocator,
  });

  static Future<List<MemoryModule>> fetchAll() async {
    var memInfoCmd = 'wmic MEMORYCHIP get Capacity,Speed,DeviceLocator /FORMAT:LIST';
    var memInfoProcessResult = await Process.run('cmd', ['/c', memInfoCmd]);
    if (memInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get Memory Info. Error: ${memInfoProcessResult.stderr}');
    }

    // Parse the output into a list of MemoryModule objects
    var output = memInfoProcessResult.stdout.toString().replaceAll('\r', '');
    var blocks = output.split('\n\n').where((block) => block.trim().isNotEmpty).toList();

    List<MemoryModule> modules = [];
    for (var block in blocks) {
      var lines = block.split('\n').where((line) => line.trim().isNotEmpty).toList();

      Map<String, String> memInfoMap = {};
      for (var line in lines) {
        var splitLine = line.split('=');
        memInfoMap[splitLine[0]] = splitLine[1].trim();
      }

      var capacity = int.parse(memInfoMap['Capacity']!);
      var speed = int.parse(memInfoMap['Speed']!);
      var deviceLocator = memInfoMap['DeviceLocator']!;

      modules.add(MemoryModule(
        capacity: capacity,
        speed: speed,
        deviceLocator: deviceLocator,
      ));
    }

    return modules;
  }

  @override
  String toString() {
    return '''
Device Locator: $deviceLocator
Capacity: ${capacity ~/ (1024 * 1024 * 1024)} GB
Speed: $speed MHz
''';
  }
}
