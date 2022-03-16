import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';

import "package:path/path.dart" show basename, dirname, extension;

const lineNumber = 'line-number';
const packagesDirectoryName = 'packages';
const androidDirectoryName = 'android';
const javaFileExtension = '.java';
const executableJarFile = 'google-java-format-1.15.0-all-deps.jar';

const pathsArg = 'paths';
const portArg = 'port';
String currentPath = dirname(Platform.script.path);

List<Isolate> isolates = [];
ReceivePort receivePort = ReceivePort();

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser();

  //TODO - pass in options to process.run
  ArgResults argResults = parser.parse(arguments);
  //TODO - if paths passed in, do not use "/packages" execution. Ask Mike about this and the former TODO
  final paths = argResults.rest;

  createArraysOfJavaFiles(paths, argResults);
}

void createArraysOfJavaFiles(List<String> paths, ArgResults argResults) async {
  Directory packagesDirectory =
      Directory('${Directory.current.path}/$packagesDirectoryName');

  bool packagesExists = await packagesDirectory.exists();

  if (packagesExists) {
    List<FileSystemEntity> files = packagesDirectory.listSync().toList();
    List<Future<void>> futures = [];
    for (FileSystemEntity file in files) {
      String packageName = basename(file.path);
      String filePath = '${file.path}/$packageName/$androidDirectoryName';
      Directory androidDirectory = Directory(filePath);

      bool androidDirectoryExists = await androidDirectory.exists();

      if (androidDirectoryExists) {
        List<String> listAndroidFiles = androidDirectory
            .listSync(recursive: true, followLinks: false)
            .where((fsEntity) => extension(fsEntity.path) == javaFileExtension)
            .map((fsEntity) => fsEntity.path)
            .toList();

        futures.add(googleJavaFormatTasks(listAndroidFiles));

        await Future.wait(futures);

      } else {
        print('"/android" directory does not exist for $packageName');
      }
    }

    exit(exitCode);
  } else {
    print('ERROR: "/package" directory does not exist for this mono repo.');
  }
}

// TODO - pass in list of cmd line args: List<String> cmdLineArgs
Future<void> googleJavaFormatTasks(List<String> listAndroidFiles) async {
  ProcessResult processResult = await Process.run('java', [
    '-jar',
    '$currentPath/formatting-tool/$executableJarFile',
    //TODO - allow passing in of argument options.
    '--replace',
    ...listAndroidFiles,
  ]);

  if (processResult.stderr is String && processResult.stderr.length > 0) {
    print('ERROR: ' + processResult.stderr);
  }
}

