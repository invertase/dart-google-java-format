import 'dart:io';

import 'package:args/args.dart';
import 'package:melos/melos.dart';
import "package:path/path.dart" show dirname, extension, join;

const androidDirectoryName = 'android';
const javaFileExtension = '.java';
const executableJarFile = 'google-java-format-1.15.0-all-deps.jar';

Future<void> init(List<String> arguments) async {
  final parser = ArgParser();

  parser.addFlag('replace');
  parser.addOption('lines');
  parser.addOption('offset');

  ArgResults argResults = parser.parse(arguments);

  createArraysOfJavaFiles(argResults);
}

void createArraysOfJavaFiles(ArgResults argResults) async {
  if (argResults.arguments.isEmpty) {
    // default FlutterFire java formatting behaviour
    MelosWorkspace workspace;
    try {
      final config =
          await MelosWorkspaceConfig.fromDirectory(Directory.current);
      workspace = await MelosWorkspace.fromConfig(config);
    } catch (e) {
      print(
          'ERROR: You do not appear to be running dart-google-java-format from a melos workspace');
      exit(1);
    }

    List<Package> packages = workspace.allPackages.values
        .where((package) => package.flutterPluginSupportsAndroid)
        .toList();
    List<Future<void>> futures = [];
    for (Package package in packages) {
      String filePath = '${package.path}/$androidDirectoryName';
      Directory androidDirectory = Directory(filePath);

      bool androidDirectoryExists = await androidDirectory.exists();

      if (androidDirectoryExists) {
        List<String> listAndroidFiles = androidDirectory
            .listSync(recursive: true, followLinks: false)
            .where((fsEntity) => extension(fsEntity.path) == javaFileExtension)
            .map((fsEntity) => fsEntity.path)
            .toList();

        List<String> arguments = listAndroidFiles;
        // Add "--replace" to beginning of list to construct arguments for "google-java-format"
        arguments.insert(0, '--replace');

        futures.add(googleJavaFormatTasks(arguments));

        await Future.wait(futures);
      } else {
        print('"/android" directory does not exist for ${package.name}');
      }
    }

    exit(0);
  } else {
    // Pass in all arguments when user doesn't use default settings (i.e. loop through /packages directory and format all .java files in /android directory)
    await googleJavaFormatTasks(argResults.arguments);
    exit(0);
  }
}

Future<void> googleJavaFormatTasks(List<String> arguments) async {
  String pathToTool = join(
      dirname(Platform.script.path), '../formatting-tool/$executableJarFile');
  ProcessResult processResult = await Process.run('java', [
    '-jar',
    pathToTool,
    ...arguments,
  ]);

  if (processResult.stderr is String && processResult.stderr.length > 0) {
    print('ERROR: ' + processResult.stderr);
  }
}
