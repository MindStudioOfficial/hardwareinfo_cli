import 'dart:io';

import 'package:hardwareinfo_cli/utility/logging.dart';

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
      return fetchAllLinux();
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

  static Future<List<DriveInfo>> fetchAllLinux() async {
    var driveListResult = await Process.run('lsblk', ['-dpn', '-o', 'name,size']);
    if (driveListResult.exitCode != 0) {
      throw Exception('Failed to get Drive List. Error: ${driveListResult.stderr}');
    }

    var drives = <DriveInfo>[];
    var lines = driveListResult.stdout.toString().split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }

      var parts = line.split(' ');
      var id = parts.first.trim();
      var sizeStr = parts.last.trim();
      var size = _parseHumanReadableSizeToBytes(sizeStr);

      // Initialize optional fields as null
      String? model;
      String? serialNumber;
      String? mediaType;
      try {
        String? extractValueFromHdparmOutput(String field, String output) {
          var lines = output.split('\n');
          for (var line in lines) {
            if (line.contains(field)) {
              return line.split(':').last.trim();
            }
          }
          return null;
        }

        // Try to get other drive info from hdparm
        var infoCmd = 'hdparm';
        var infoCmdArgs = ['-I', id];
        var infoProcessResult = await Process.run(infoCmd, infoCmdArgs);
        if (infoProcessResult.exitCode != 0) {
          throw Exception('Failed to get Drive Info. Error: ${infoProcessResult.stderr}');
        }
        var output = infoProcessResult.stdout.toString();
        model = extractValueFromHdparmOutput('Model Number:', output);
        serialNumber = extractValueFromHdparmOutput('Serial Number:', output);
        mediaType = extractValueFromHdparmOutput('Transport:', output);
      } catch (e) {
        logger.log(
          "hdparm is likely not installed. Drive information might be incomplete.",
          level: LogLevel.warning,
        );
      }
      if (model == null) {
        logger.log(
          "couldn't fetch model name for drive $id",
          level: LogLevel.warning,
        );
      }

      drives.add(DriveInfo(
        id: id,
        size: size,
        model: model,
        partitions: 0,
        mediaType: mediaType,
        serialNumber: serialNumber,
        status: null,
      ));
    }

    return drives;
  }

  // Parses a size string (like "10G", "100M", "1000K", "1024") to its size in bytes
  static int _parseHumanReadableSizeToBytes(String size) {
    var scale = 1;
    if (size.endsWith('T')) {
      scale = 1024 * 1024 * 1024 * 1024; // for Terabytes
    } else if (size.endsWith('G')) {
      scale = 1024 * 1024 * 1024; // for Gigabytes
    } else if (size.endsWith('M')) {
      scale = 1024 * 1024; // for Megabytes
    } else if (size.endsWith('K')) {
      scale = 1024; // for Kilobytes
    }
    // Replace commas with dots to handle the decimal point and remove the scale character, then convert to a double and multiply by the scale
    return (double.parse(size.replaceAll(',', '.').replaceAll(RegExp(r'[TGMK]'), '')) * scale).round();
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
