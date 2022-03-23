import '../lib/dart_google_java_format.dart';
import 'package:args/args.dart';

void main(List<String> argumentsFromCLI) async {
  final parser = ArgParser();

  parser.addFlag('replace');
  parser.addOption('lines');
  parser.addOption('offset');

  ArgResults argResults = parser.parse(argumentsFromCLI);

  List<String> arguments = argResults.arguments;

  await formatJavaFiles(arguments);
}
