import 'dart:io';

class MemorySlot {
  final int capacity;
  final int speed;
  final String deviceLocator;
  final bool empty;

  MemorySlot({
    required this.capacity,
    required this.speed,
    required this.deviceLocator,
    required this.empty,
  });

  static Future<List<MemorySlot>> fetchAll() async {
    if (Platform.isWindows) {
      return fetchAllWindows();
    } else if (Platform.isLinux) {
      return fetchAllLinux();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<List<MemorySlot>> fetchAllWindows() async {
    var memInfoCmd = 'wmic MEMORYCHIP get Capacity,Speed,DeviceLocator /FORMAT:LIST';
    var memInfoProcessResult = await Process.run('cmd', ['/c', memInfoCmd]);
    if (memInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get Memory Info. Error: ${memInfoProcessResult.stderr}');
    }

    // Parse the output into a list of MemoryModule objects
    var output = memInfoProcessResult.stdout.toString().replaceAll('\r', '');
    var blocks = output.split('\n\n').where((block) => block.trim().isNotEmpty).toList();

    List<MemorySlot> modules = [];
    for (var block in blocks) {
      var lines = block.split('\n').where((line) => line.trim().isNotEmpty).toList();

      Map<String, String> memInfoMap = {};
      for (var line in lines) {
        var splitLine = line.split('=');
        memInfoMap[splitLine[0]] = splitLine[1].trim();
      }

      var capacity = int.tryParse(memInfoMap['Capacity']!);
      var speed = int.tryParse(memInfoMap['Speed']!);
      var deviceLocator = memInfoMap['DeviceLocator']!;

      modules.add(MemorySlot(
        capacity: capacity ?? 0,
        speed: speed ?? 0,
        deviceLocator: deviceLocator,
        empty: capacity == null || speed == null,
      ));
    }

    return modules;
  }

  static Future<List<MemorySlot>> fetchAllLinux() async {
    var memInfoCmd = 'dmidecode';
    var memInfoCmdArgs = ['-t', 'memory'];
    var memInfoProcessResult = await Process.run('sudo', [memInfoCmd, ...memInfoCmdArgs]);
    if (memInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get Memory Info. Error: ${memInfoProcessResult.stderr}');
    }

    // Parse the output into a list of MemoryModule objects
    var output = memInfoProcessResult.stdout.toString();
    var blocks = output.split('\n\n').where((block) => block.contains('Size:') && block.contains('Speed:')).toList();

    List<MemorySlot> modules = [];
    for (var block in blocks) {
      var lines = block.split('\n').where((line) => line.trim().isNotEmpty).toList();

      Map<String, String> memInfoMap = {};
      for (var line in lines) {
        var splitLine = line.split(':');
        if (splitLine.length < 2) continue;
        memInfoMap[splitLine[0].trim()] = splitLine[1].trim();
      }

      var capacityStr = memInfoMap['Size']!;
      var speedStr = memInfoMap['Speed']!;
      var locator = memInfoMap['Locator']!;

      var capacity = capacityStr.contains('MB')
          ? (int.tryParse(capacityStr.split(' ')[0]) ?? 0) * 1024 * 1024
          : (int.tryParse(capacityStr.split(' ')[0]) ?? 0) * 1024 * 1024 * 1024;

      var speed = int.tryParse(speedStr.split(' ')[0]) ?? 0;

      modules.add(MemorySlot(
        capacity: capacity,
        speed: speed,
        deviceLocator: locator,
        empty: capacity == 0 || speed == 0,
      ));
    }

    return modules;
  }

  @override
  String toString() {
    if (empty) {
      return 'Device Locator: $deviceLocator\nEmpty slot';
    } else {
      return '''
Device Locator: $deviceLocator
Capacity: ${capacity ~/ (1024 * 1024 * 1024)} GB
Speed: $speed MHz
''';
    }
  }
}
