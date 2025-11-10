import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';

class TaskDoneInput {
  const TaskDoneInput({
    required this.answer,
    required this.success,
  });

  final String answer;
  final bool success;

  TaskDoneInput.fromJson(Map<String, dynamic> json)
      : this(
          answer: json['answer'] as String,
          success: json['success'] as bool,
        );
}

Tool createTaskDoneTool() {
  return Tool.fromFunction<TaskDoneInput, String>(
    name: 'task_done',
    description:
        'Call this when the task is complete. Provide your final answer or conclusion.',
    inputJsonSchema: object({
      'answer': string().min(1).meta(MetadataEntry(
            description:
                'Your final answer or conclusion, arrange the anser well and make it readable ,  it a cli tool',
          )),
      'success': boolean().meta(MetadataEntry(
        description: 'Whether the task was completed successfully',
      )),
    }).toJsonSchema(),
    func: (TaskDoneInput input) async {
      return '__TASK_DONE__:${input.answer}';
    },
    getInputFromJson: (json) => TaskDoneInput.fromJson(json),
    handleToolError: (e) {
      return 'Task done tool error : ${e.toString()}';
    },
  );
}
