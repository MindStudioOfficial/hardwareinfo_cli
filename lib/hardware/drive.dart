import 'dart:io';

class DriveInfo {
  final String id;
  final int size; // in bytes
  final String? model;
  final int partitions;
  final String? mediaType;
  final String? serialNumber;
  final String? status;

  DriveInfo({
    required this.id,
    required this.size,
    required this.model,
    required this.partitions,
    required this.mediaType,
    required this.serialNumber,
    required this.status,
  });

  static Future<List<DriveInfo>> fetchAll() async {
    if (Platform.isWindows) {
      return fetchAllWindows();
    } else if (Platform.isLinux) {
      return [];
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<List<DriveInfo>> fetchAllWindows() async {
    var driveInfoCmd = 'wmic diskdrive get DeviceID,Size,Model,Partitions,MediaType,SerialNumber,Status /FORMAT:LIST';
    var driveInfoProcessResult = await Process.run('cmd', ['/c', driveInfoCmd]);
    if (driveInfoProcessResult.exitCode != 0) {
      throw Exception('Failed to get Drive Info. Error: ${driveInfoProcessResult.stderr}');
    }

    // Parse the output into DriveInfo
    var output = driveInfoProcessResult.stdout.toString().replaceAll('\r', '');
    var blocks = output.split('\n\n').where((section) => section.trim().isNotEmpty).toList();

    var drives = <DriveInfo>[];
    for (var block in blocks) {
      Map<String, String> driveInfoMap = {};
      var lines = block.split('\n').where((line) => line.trim().isNotEmpty).toList();
      for (var line in lines) {
        var splitLine = line.split('=');
        driveInfoMap[splitLine[0].trim()] = splitLine[1].trim();
      }

      var id = driveInfoMap['DeviceID']!;
      var model = driveInfoMap['Model'];
      var size = int.parse(driveInfoMap['Size']!);
      var partitions = int.parse(driveInfoMap['Partitions']!);
      var mediaType = driveInfoMap['MediaType'];
      var serialNumber = driveInfoMap['SerialNumber'];
      var status = driveInfoMap['Status'];

      drives.add(DriveInfo(
        id: id,
        size: size,
        model: model,
        partitions: partitions,
        mediaType: mediaType,
        serialNumber: serialNumber,
        status: status,
      ));
    }

    return drives;
  }

  @override
  String toString() {
    return '''
ID: $id
Model: $model
Size: ${size ~/ 1024 ~/ 1024} MB
Partitions: $partitions
Media Type: $mediaType
Serial Number: $serialNumber
Status: $status
''';
  }
}
