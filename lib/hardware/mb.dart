import 'dart:io';

class MotherboardInfo {
  final String manufacturer;
  final String product;
  final String serialNumber;
  final String version;

  MotherboardInfo({
    required this.manufacturer,
    required this.product,
    required this.serialNumber,
    required this.version,
  });

  static Future<MotherboardInfo> fetch() async {
    if (Platform.isWindows) {
      return fetchWindows();
    } else if (Platform.isLinux) {
      return fetchLinux();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<MotherboardInfo> fetchWindows() async {
    var mbInfoCmd = 'wmic baseboard get Manufacturer,Product,SerialNumber,Version /FORMAT:LIST';
    var mbInfoProcessResult = await Process.run('cmd', ['/c', mbInfoCmd]);
    if (mbInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get Motherboard Info. Error: ${mbInfoProcessResult.stderr}');
    }

    // Parse the output into MotherboardInfo
    var output = mbInfoProcessResult.stdout.toString();
    var lines = output.split('\n').where((line) => line.trim().isNotEmpty).toList();

    Map<String, String> mbInfoMap = {};
    for (var line in lines) {
      var splitLine = line.split('=');
      mbInfoMap[splitLine[0]] = splitLine[1].trim();
    }

    var manufacturer = mbInfoMap['Manufacturer']!;
    var product = mbInfoMap['Product']!;
    var serialNumber = mbInfoMap['SerialNumber']!;
    var version = mbInfoMap['Version']!;

    return MotherboardInfo(
      manufacturer: manufacturer,
      product: product,
      serialNumber: serialNumber,
      version: version,
    );
  }

  static Future<MotherboardInfo> fetchLinux() async {
    var mbInfoCmd = 'dmidecode';
    var mbInfoCmdArgs = ['-t', '2'];
    var mbInfoProcessResult = await Process.run('sudo', [mbInfoCmd, ...mbInfoCmdArgs]);
    if (mbInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get Motherboard Info. Error: ${mbInfoProcessResult.stderr}');
    }

    // Parse the output into MotherboardInfo
    var output = mbInfoProcessResult.stdout.toString();
    var lines = output.split('\n').where((line) => line.trim().isNotEmpty).toList();

    Map<String, String> mbInfoMap = {};
    for (var line in lines) {
      var splitLine = line.split(':');
      if (splitLine.length < 2) continue;
      mbInfoMap[splitLine[0].trim()] = splitLine[1].trim();
    }

    var manufacturer = mbInfoMap['Manufacturer'] ?? 'Unknown';
    var product = mbInfoMap['Product Name'] ?? 'Unknown';
    var serialNumber = mbInfoMap['Serial Number'] ?? 'Unknown';
    var version = mbInfoMap['Version'] ?? 'Unknown';

    return MotherboardInfo(
      manufacturer: manufacturer,
      product: product,
      serialNumber: serialNumber,
      version: version,
    );
  }

  @override
  String toString() {
    return '''
Motherboard Manufacturer: $manufacturer
Product: $product
Serial Number: $serialNumber
Version: $version
''';
  }
}
