import 'package:dart_console/dart_console.dart';
import 'package:hardwareinfo_cli/console/colored_string.dart';
import 'package:hardwareinfo_cli/console/console.dart';
import 'package:hardwareinfo_cli/hardware/cpu.dart';
import 'package:hardwareinfo_cli/hardware/drive.dart';
import 'package:hardwareinfo_cli/hardware/mb.dart';
import 'package:hardwareinfo_cli/hardware/mem.dart';

void main(List<String> arguments) async {
  CPUInfo cpu = await CPUInfo.fetch();
  MotherboardInfo mb = await MotherboardInfo.fetch();
  List<MemoryModule> mems = await MemoryModule.fetchAll();
  List<DriveInfo> drives = await DriveInfo.fetchAll();

  final console = Console();

  final renderer = ConsoleRenderer(
    console,
  );
  Key? lastKey;

  String status() =>
      "pressed: ${lastKey != null ? (lastKey.isControl ? lastKey.controlChar.name : lastKey.char) : 'none'}";

  void createOutput(ConsoleRenderer renderer) {
    renderer.clear();
    // * status
    renderer.renderText(1, 0, status(), color: CustomConsoleColor(ConsoleColor.blue, ConsoleColor.black));
    // * MB
    renderer.renderTextBox(
      "${mb.manufacturer} ${mb.product}",
      0,
      1,
      expandRect: true,
      title: "Motherboard",
      titleColor: ConsoleColor.green.asForeground,
      borderColor: ConsoleColor.green.asForeground,
      fillColor: ConsoleColor.cyan.asForeground,
    );
    // * CPU
    var cpuBox = renderer.renderTextBox(
      cpu.toString(),
      4,
      4,
      maxWidth: renderer.width ~/ 3,
      title: "CPU",
      borderColor: ConsoleColor.blue.asForeground,
      fillColor: CustomConsoleColor(ConsoleColor.white),
    );
    // * MEM
    int memX = renderer.width - 8;
    for (var mem in mems.reversed) {
      renderer.renderTextBox(
        "${mem.deviceLocator}\n\n${mem.capacity ~/ (1024 * 1024 * 1024)}GB\n\n${mem.speed}MHz",
        memX,
        4,
        maxWidth: 1,
        title: "MEM",
        borderColor: ConsoleColor.blue.asForeground,
      );
      memX -= 6;
    }
    // * Drives
    int driveY = cpuBox.$2 + 4 + 2;
    for (var drive in drives) {
      var (_, h) = renderer.renderTextBox(
        "Model: ${drive.model}",
        4,
        driveY,
        title: "DRIVE",
        maxWidth: renderer.width ~/ 2,
        borderColor: ConsoleColor.blue.asForeground,
      );
      driveY += h + 1;
    }
    renderer.show();
  }

  renderer.setResizeCallback(
    (width, height) => (width, height) {
      createOutput(renderer);
    },
  );

  createOutput(renderer);

  bool running = true;
  while (running) {
    final Key key = console.readKey();
    lastKey = key;
    createOutput(renderer);
    if (key.controlChar == ControlCharacter.ctrlC || key.char.compareTo("q") == 0) {
      running = false;
    }
  }
  renderer.dispose();
}

void printMotherboardLayout(CPUInfo cpu, List<MemoryModule> memoryModules) {
  final console = Console();
  final width = console.windowWidth;
  final boxWidth = (width - 12) ~/ 2;
  final cpuBox = 'CPU'.padLeft((boxWidth + 'CPU'.length) ~/ 2).padRight(boxWidth);
  final ramBox1 = 'RAM1'.padLeft((boxWidth + 'RAM1'.length) ~/ 2).padRight(boxWidth);

  print('┌${'─' * (width - 2)}┐');
  print('│${'Motherboard'.padLeft((width + 'Motherboard'.length) ~/ 2).padRight(width - 2)}│');
  print('│ ┌${'─' * (boxWidth - 2)}┐  ┌${'─' * (boxWidth - 2)}┐  │');
  print('│ │$cpuBox│  │$ramBox1│  │');
  print('│ └${'─' * (boxWidth - 2)}┘  └${'─' * (boxWidth - 2)}┘  │');
  print('└${'─' * (width - 2)}┘');
}
