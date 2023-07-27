mkdir -p ./output/linux
mkdir -p ./output/windows
dart compile exe --target-os linux -o ./output/linux/hardwareinfo_cli ./bin/hardwareinfo_cli.dart
dart compile exe --target-os windows -o ./output/windows/hardwareinfo_cli.exe ./bin/hardwareinfo_cli.dart