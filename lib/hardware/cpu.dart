import 'dart:io';

class CPUInfo {
  final String name;
  final int numberOfCores;
  final int numberOfLogicalProcessors;
  final int maxClockSpeed;

  CPUInfo({
    required this.name,
    required this.numberOfCores,
    required this.numberOfLogicalProcessors,
    required this.maxClockSpeed,
  });

  static Future<CPUInfo> fetch() async {
    if (Platform.isWindows) {
      return fetchWindows();
    } else if (Platform.isLinux) {
      return fetchLinux();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<CPUInfo> fetchWindows() async {
    var cpuInfoCmd = 'wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /FORMAT:LIST';
    var cpuInfoProcessResult = await Process.run('cmd', ['/c', cpuInfoCmd]);
    if (cpuInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get CPU Info. Error: ${cpuInfoProcessResult.stderr}');
    }

    // Parse the output into CPUInfo
    var output = cpuInfoProcessResult.stdout.toString();
    var lines = output.split('\n').where((line) => line.trim().isNotEmpty).toList();

    Map<String, String> cpuInfoMap = {};
    for (var line in lines) {
      var splitLine = line.split('=');
      cpuInfoMap[splitLine[0].trim()] = splitLine[1].trim();
    }

    var name = cpuInfoMap['Name']!;
    var numberOfCores = int.parse(cpuInfoMap['NumberOfCores']!);
    var numberOfLogicalProcessors = int.parse(cpuInfoMap['NumberOfLogicalProcessors']!);
    var maxClockSpeed = int.parse(cpuInfoMap['MaxClockSpeed']!);

    return CPUInfo(
      name: name,
      numberOfCores: numberOfCores,
      numberOfLogicalProcessors: numberOfLogicalProcessors,
      maxClockSpeed: maxClockSpeed,
    );
  }

  static Future<CPUInfo> fetchLinux() async {
    var cpuInfoCmd = 'lscpu';
    var cpuInfoProcessResult = await Process.run(cpuInfoCmd, []);
    if (cpuInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get CPU Info. Error: ${cpuInfoProcessResult.stderr}');
    }

    // Parse the output into CPUInfo
    var output = cpuInfoProcessResult.stdout.toString();
    var lines = output.split('\n').where((line) => line.trim().isNotEmpty).toList();

    Map<String, String> cpuInfoMap = {};
    for (var line in lines) {
      var splitLine = line.split(':');
      cpuInfoMap[splitLine[0].trim()] = splitLine[1].trim();
    }

    var name = cpuInfoMap['Model name']!;
    var numberOfCores = int.parse(cpuInfoMap['Core(s) per socket']!);
    var numberOfLogicalProcessors = int.parse(cpuInfoMap['Thread(s) per core']!) * numberOfCores;
    var maxClockSpeed = int.parse(cpuInfoMap['CPU MHz']!.split('.')[0]); // Converting to integer MHz

    return CPUInfo(
      name: name,
      numberOfCores: numberOfCores,
      numberOfLogicalProcessors: numberOfLogicalProcessors,
      maxClockSpeed: maxClockSpeed,
    );
  }

  @override
  String toString() {
    return '''
Model: $name
Cores: $numberOfCores
Threads: $numberOfLogicalProcessors
Base Clock: $maxClockSpeed MHz
''';
  }
}
