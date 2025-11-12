import 'dart:io';
import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:path/path.dart' as path;

const int snippetLines = 4;
const int maxOutputLength = 15000;

class TextEditorInput {
  final String command;
  final String filePath;
  final String? fileText;
  final int? insertLine;
  final String? newStr;
  final String? oldStr;
  final List<int>? viewRange;

  const TextEditorInput({
    required this.command,
    required this.filePath,
    this.fileText,
    this.insertLine,
    this.newStr,
    this.oldStr,
    this.viewRange,
  });

  factory TextEditorInput.fromJson(Map<String, dynamic> json) {
    return TextEditorInput(
      command: json['command'] as String,
      filePath: json['path'] as String,
      fileText: json['file_text'] as String?,
      insertLine: json['insert_line'] as int?,
      newStr: json['new_str'] as String?,
      oldStr: json['old_str'] as String?,
      viewRange: (json['view_range'] as List?)?.cast<int>(),
    );
  }
}

enum TextEditorCommand {
  view,
  create,
  strReplace,
  insert,
}

Tool createTextEditorTool({required String projectDirectory}) {
  return Tool.fromFunction<TextEditorInput, String>(
    name: 'str_replace_based_edit_tool',
    description: '''Custom editing tool for viewing, creating and editing files
* State is persistent across command calls and discussions with the user
* If `path` is a file, `view` displays the result of applying `cat -n`. If `path` is a directory, `view` lists non-hidden files and directories up to 2 levels deep
* The `create` command cannot be used if the specified `path` already exists as a file !!! If you know that the `path` already exists, please remove it first and then perform the `create` operation!
* If a `command` generates a long output, it will be truncated and marked with `<response clipped>`

Notes for using the `str_replace` command:
* The `old_str` parameter should match EXACTLY one or more consecutive lines from the original file. Be mindful of whitespaces!
* If the `old_str` parameter is not unique in the file, the replacement will not be performed. Make sure to include enough context in `old_str` to make it unique
* The `new_str` parameter should contain the edited lines that should replace the `old_str`''',
    inputJsonSchema: object({
      'command': string().enumerated(TextEditorCommand.values,
          nameTransformer: (name) {
        return name.replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        );
      }).meta(MetadataEntry(
        description:
            'The command to run. Options: view, create, str_replace, insert',
      )),
      'path': string().meta(MetadataEntry(
        description:
            'Absolute path to file or directory, e.g. `/repo/file.dart` or `/repo`',
      )),
      'file_text': string().meta(MetadataEntry(
        description:
            'Required parameter of `create` command, with the content of the file to be created',
      )),
      'insert_line': number().meta(MetadataEntry(
        description:
            'Required parameter of `insert` command. The `new_str` will be inserted AFTER the line `insert_line` of `path`',
      )),
      'new_str': string().meta(MetadataEntry(
        description:
            'Optional parameter of `str_replace` command containing the new string (if not given, no string will be added). Required parameter of `insert` command containing the string to insert',
      )),
      'old_str': string().meta(MetadataEntry(
        description:
            'Required parameter of `str_replace` command containing the string in `path` to replace',
      )),
      'view_range': number().list().meta(MetadataEntry(
            description:
                'Optional parameter of `view` command when `path` points to a file. If none is given, the full file is shown. If provided, the file will be shown in the indicated line number range, e.g. [11, 12] will show lines 11 and 12. Indexing at 1 to start. Setting `[start_line, -1]` shows all lines from `start_line` to the end of the file',
          )),
    }).optionals([
      'file_text',
      'insert_line',
      'new_str',
      'old_str',
      'view_range',
    ]).toJsonSchema(),
    func: (input) async {
      try {
        return await _executeCommand(input, projectDirectory);
      } catch (e) {
        return 'Error: ${e.toString()}';
      }
    },
    getInputFromJson: TextEditorInput.fromJson,
    handleToolError: (e) {
      return 'Text editor tool error: ${e.toString()}';
    },
  );
}

Future<String> _executeCommand(
  TextEditorInput input,
  String projectDirectory,
) async {
  final filePath = _resolvePath(input.filePath, projectDirectory);

  _validatePath(input.command, filePath);

  switch (input.command) {
    case 'view':
      return await _viewCommand(filePath, input.viewRange);
    case 'create':
      return _createCommand(filePath, input.fileText);
    case 'strReplace':
      return _strReplaceCommand(filePath, input.oldStr, input.newStr);
    case 'str_replace':
      return _strReplaceCommand(filePath, input.oldStr, input.newStr);
    case 'insert':
      return _insertCommand(filePath, input.insertLine, input.newStr);
    default:
      throw Exception(
        'Unrecognized command ${input.command}. Allowed: view, create, str_replace, insert',
      );
  }
}

String _resolvePath(String filePath, String projectDirectory) {
  if (path.isAbsolute(filePath)) {
    return filePath;
  }
  // If relative, make it absolute relative to project directory
  final suggestedPath = path.join(projectDirectory, filePath);
  throw Exception(
    'The path $filePath is not an absolute path. It should start with `/`. Maybe you meant $suggestedPath?',
  );
}

void _validatePath(String command, String filePath) {
  final file = File(filePath);
  final dir = Directory(filePath);

  if (!path.isAbsolute(filePath)) {
    throw Exception(
      'The path $filePath is not an absolute path, it should start with `/`',
    );
  }

  // Check if path exists
  if (!file.existsSync() && !dir.existsSync() && command != 'create') {
    throw Exception(
        'The path $filePath does not exist. Please provide a valid path');
  }

  if ((file.existsSync() || dir.existsSync()) && command == 'create') {
    throw Exception(
      'File already exists at: $filePath. Cannot overwrite files using command `create`',
    );
  }

  // Check if the path points to a directory
  if (dir.existsSync() && command != 'view') {
    throw Exception(
      'The path $filePath is a directory and only the `view` command can be used on directories',
    );
  }
}

Future<String> _viewCommand(String filePath, List<int>? viewRange) async {
  final file = File(filePath);
  final dir = Directory(filePath);

  if (dir.existsSync()) {
    if (viewRange != null) {
      throw Exception(
        'The `view_range` parameter is not allowed when `path` points to a directory',
      );
    }
    return await _viewDirectory(dir);
  }

  final content = await file.readAsString();
  final lines = content.split('\n');

  if (viewRange != null) {
    if (viewRange.length != 2) {
      throw Exception(
          'Invalid `view_range`. It should be a list of two integers');
    }

    final startLine = viewRange[0];
    final endLine = viewRange[1];
    final totalLines = lines.length;

    if (startLine < 1 || startLine > totalLines) {
      throw Exception(
        'Invalid `view_range`: $viewRange. Its first element `$startLine` should be within [1, $totalLines]',
      );
    }

    if (endLine > totalLines && endLine != -1) {
      throw Exception(
        'Invalid `view_range`: $viewRange. Its second element `$endLine` should be smaller than or equal to $totalLines',
      );
    }

    if (endLine != -1 && endLine < startLine) {
      throw Exception(
        'Invalid `view_range`: $viewRange. Its second element `$endLine` should be >= its first `$startLine`',
      );
    }

    final filteredLines = endLine == -1
        ? lines.sublist(startLine - 1)
        : lines.sublist(startLine - 1, endLine);

    return _makeOutput(filteredLines.join('\n'), filePath, startLine);
  }

  return _makeOutput(content, filePath, 1);
}

Future<String> _viewDirectory(Directory dir) async {
  final buffer = StringBuffer();
  buffer.writeln(
    'Here\'s the files and directories up to 2 levels deep in ${dir.path}, excluding hidden items:',
  );

  await _listDirectory(dir, buffer, 0, 2);

  return buffer.toString();
}

Future<void> _listDirectory(
  Directory dir,
  StringBuffer buffer,
  int level,
  int maxLevel,
) async {
  if (level > maxLevel) return;

  final entities = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

  for (final entity in entities) {
    final name = path.basename(entity.path);
    if (name.startsWith('.')) continue;

    final indent = '  ' * level;

    if (entity is Directory) {
      buffer.writeln('$indent$name/');
      await _listDirectory(entity, buffer, level + 1, maxLevel);
    } else {
      buffer.writeln('$indent$name');
    }
  }
}

String _createCommand(String filePath, String? fileText) {
  if (fileText == null) {
    throw Exception(
      'Parameter `file_text` is required and must be a string for command: create',
    );
  }

  final file = File(filePath);

  // Create parent directories if they don't exist
  file.parent.createSync(recursive: true);

  file.writeAsStringSync(fileText);

  return 'File created successfully at: $filePath';
}

String _strReplaceCommand(String filePath, String? oldStr, String? newStr) {
  if (oldStr == null) {
    throw Exception(
      'Parameter `old_str` is required and should be a string for command: str_replace',
    );
  }

  final file = File(filePath);
  final content = file.readAsStringSync().replaceAll('\t', '    ');
  final oldStrExpanded = oldStr.replaceAll('\t', '    ');
  final newStrExpanded = (newStr ?? '').replaceAll('\t', '    ');

  // Check if old_str is unique in the file
  final occurrences = content.split(oldStrExpanded).length - 1;

  if (occurrences == 0) {
    throw Exception(
      'No replacement was performed, old_str `$oldStr` did not appear verbatim in $filePath',
    );
  } else if (occurrences > 1) {
    final lines = content.split('\n');
    final lineNumbers = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(oldStrExpanded)) {
        lineNumbers.add(i + 1);
      }
    }
    throw Exception(
      'No replacement was performed. Multiple occurrences of old_str `$oldStr` in lines $lineNumbers. Please ensure it is unique',
    );
  }

  // Replace old_str with new_str
  final newContent = content.replaceAll(oldStrExpanded, newStrExpanded);
  file.writeAsStringSync(newContent);

  // Create a snippet of the edited section
  final replacementLine = content.split(oldStrExpanded)[0].split('\n').length;
  final startLine =
      (replacementLine - snippetLines).clamp(0, double.infinity).toInt();
  final endLine =
      replacementLine + snippetLines + newStrExpanded.split('\n').length;

  final newLines = newContent.split('\n');
  final snippet = newLines
      .sublist(startLine, (endLine + 1).clamp(0, newLines.length))
      .join('\n');

  final successMsg = StringBuffer();
  successMsg.writeln('The file $filePath has been edited.');
  successMsg
      .write(_makeOutput(snippet, 'a snippet of $filePath', startLine + 1));
  successMsg.write(
      'Review the changes and make sure they are as expected. Edit the file again if necessary.');

  return successMsg.toString();
}

String _insertCommand(String filePath, int? insertLine, String? newStr) {
  if (insertLine == null) {
    throw Exception(
      'Parameter `insert_line` is required and should be integer for command: insert',
    );
  }

  if (newStr == null) {
    throw Exception('Parameter `new_str` is required for command: insert');
  }

  final file = File(filePath);
  final content = file.readAsStringSync().replaceAll('\t', '    ');
  final newStrExpanded = newStr.replaceAll('\t', '    ');

  final lines = content.split('\n');
  final totalLines = lines.length;

  if (insertLine < 0 || insertLine > totalLines) {
    throw Exception(
      'Invalid `insert_line` parameter: $insertLine. It should be within [0, $totalLines]',
    );
  }

  final newStrLines = newStrExpanded.split('\n');
  final newFileLines = [
    ...lines.sublist(0, insertLine),
    ...newStrLines,
    ...lines.sublist(insertLine),
  ];

  // Calculate snippet boundaries using the CONSTANT snippetLines (4)
  final snippetStartLine = (insertLine - snippetLines).clamp(0, totalLines);
  final snippetEndLine = (insertLine + snippetLines).clamp(0, totalLines);

  final snippetLinesList = [
    ...lines.sublist(snippetStartLine, insertLine),
    ...newStrLines,
    ...lines.sublist(insertLine, snippetEndLine),
  ];

  final newContent = newFileLines.join('\n');
  final snippet = snippetLinesList.join('\n');

  file.writeAsStringSync(newContent);

  final successMsg = StringBuffer();
  successMsg.writeln('The file $filePath has been edited.');
  successMsg.write(_makeOutput(
    snippet,
    'a snippet of the edited file',
    (snippetStartLine + 1).clamp(1, totalLines + 1),
  ));
  successMsg.write(
    'Review the changes and make sure they are as expected (correct indentation, no duplicate lines, etc). Edit the file again if necessary.',
  );

  return successMsg.toString();
}

String _makeOutput(
  String fileContent,
  String fileDescriptor,
  int initLine,
) {
  var content = fileContent;

  // Truncate if too long
  if (content.length > maxOutputLength) {
    content = '${content.substring(0, maxOutputLength)}\n<response clipped>';
  }

  content = content.replaceAll('\t', '    ');

  final lines = content.split('\n');
  final numberedLines = lines
      .asMap()
      .entries
      .map((entry) =>
          '${(entry.key + initLine).toString().padLeft(6)}\t${entry.value}')
      .join('\n');

  return 'Here\'s the result of running `cat -n` on $fileDescriptor:\n$numberedLines\n';
}
