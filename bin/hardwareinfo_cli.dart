import 'package:dart_console/dart_console.dart';
import 'package:hardwareinfo_cli/console/colored_string.dart';
import 'package:hardwareinfo_cli/console/console.dart';
import 'package:hardwareinfo_cli/hardware/cpu.dart';
import 'package:hardwareinfo_cli/hardware/drive.dart';
import 'package:hardwareinfo_cli/hardware/mb.dart';
import 'package:hardwareinfo_cli/hardware/mem.dart';
import 'package:hardwareinfo_cli/utility/binary.dart';
import 'package:hardwareinfo_cli/utility/logging.dart';

void main(List<String> arguments) async {
  CPUInfo cpu = await CPUInfo.fetch();
  MotherboardInfo mb = await MotherboardInfo.fetch();
  List<MemorySlot> mems = await MemorySlot.fetchAll();
  List<DriveInfo> drives = await DriveInfo.fetchAll();

  final console = Console();

  final renderer = ConsoleRenderer(
    console,
  );
  Key? lastKey;

  String status() =>
      "pressed: ${lastKey != null ? (lastKey.isControl ? lastKey.controlChar.name : lastKey.char) : 'none'}, press 'q' to exit";

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
      maxHeight: renderer.height - 2,
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
      String memText = "${mem.deviceLocator}\n\n${mem.capacity ~/ (1024 * 1024 * 1024)}GB\n\n${mem.speed}MHz";
      memText = mem.empty ? "│" * (memText.length + 1) : memText;
      renderer.renderTextBox(
        memText,
        memX,
        4,
        maxWidth: 1,
        title: "MEM",
        borderColor: ConsoleColor.yellow.asForeground,
        fillColor: mem.empty ? ConsoleColor.brightBlack.asForeground : ConsoleColor.white.asForeground,
      );
      memX -= 5;
    }
    // * Drives
    int driveY = cpuBox.$2 + 4 + 2;
    for (var drive in drives) {
      var (_, h) = renderer.renderTextBox(
        "Model: ${drive.model}\nID: ${drive.id}\n${bytesToReadable(drive.size)}",
        4,
        driveY,
        title: "DRIVE",
        maxWidth: renderer.width ~/ 2,
        borderColor: ConsoleColor.red.asForeground,
        fillColor: ConsoleColor.white.asForeground,
      );
      driveY += h + 1;
    }
    if (logger.logEntries.isNotEmpty) {
      var (String message, CustomConsoleColor color) = logger.logEntries.last.getConsoleMessage();
      renderer.renderText(0, renderer.height - 1, message, color: color);
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
      console.clearScreen();
    }
  }
  renderer.dispose();
}
