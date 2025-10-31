import 'dart:convert';
import 'package:acanthis/acanthis.dart';
import 'package:langchain/langchain.dart';
import 'package:pubmind/models/sequential_thinking.dart';

Tool createSequentialThinkingTool({
  SequentialThinkingTracker? tracker,
  bool verbose = false,
}) {
  final thinkingTracker = tracker ?? SequentialThinkingTracker();

  return Tool.fromFunction<SequentialThinkingInput, String>(
    name: 'sequential_thinking',
    description:
        '''A tool for dynamic and reflective problem-solving through structured thoughts.

Use this when you need to:
- Break down complex problems into manageable steps
- Plan and design with room for revision and course correction
- Analyze problems where the full scope might not be clear initially
- Maintain context over multiple reasoning steps
- Question or revise previous conclusions as understanding deepens
- Generate and verify solution hypotheses
- Filter out irrelevant information at each step

Key features:
- Adjust total_thoughts up or down as you progress
- Question or revise previous thoughts (mark with is_revision)
- Add more thoughts even after reaching what seemed like the end
- Express uncertainty and explore alternative approaches
- Branch into alternative reasoning paths
- Generate hypothesis → verify → repeat until satisfied

How to use:
1. Start with initial estimate of needed thoughts (can adjust later)
2. Each thought builds on previous ones or questions them
3. Mark revisions with is_revision and revises_thought
4. Set next_thought_needed=true to continue thinking
5. Only set next_thought_needed=false when truly satisfied
6. Generate hypotheses and verify them through the chain
7. Provide final answer only when confident

This tool helps you think through problems systematically while remaining flexible.''',
    inputJsonSchema: object({
      'thought': string().min(1).meta(
            MetadataEntry(
              description: 'Your current thinking step (can include analysis, '
                  'revisions, questions, realizations, hypothesis generation/verification)',
            ),
          ),
      'next_thought_needed': boolean().meta(
        MetadataEntry(
          description: 'True if more thinking needed, false when done',
        ),
      ),
      'thought_number': number().positive().meta(
            MetadataEntry(
              description: 'Current thought number in sequence (min: 1)',
            ),
          ),
      'total_thoughts': number().positive().meta(
            MetadataEntry(
              description:
                  'Current estimate of total thoughts needed (can adjust up/down)',
            ),
          ),
      'is_revision': boolean().meta(
        MetadataEntry(
          description: 'True if this thought revises previous thinking',
        ),
      ),
      'revises_thought': number().positive().meta(
            MetadataEntry(
              description:
                  'Which thought number is being reconsidered (min: 1)',
            ),
          ),
      'branch_from_thought': number().positive().meta(
            MetadataEntry(
              description: 'Thought number where branching occurs (min: 1)',
            ),
          ),
      'branch_id': string().meta(
        MetadataEntry(
          description: 'Identifier for the current branch',
        ),
      ),
      'needs_more_thoughts': boolean().meta(
        MetadataEntry(
          description:
              'True if reaching end but realizing more thoughts needed',
        ),
      ),
    }).optionals([
      'is_revision',
      'revises_thought',
      'branch_from_thought',
      'branch_id',
      'needs_more_thoughts',
    ]).toJsonSchema(),
    func: (input) async {
      try {
        var adjustedTotalThoughts = input.totalThoughts;
        if (input.thoughtNumber > input.totalThoughts) {
          adjustedTotalThoughts = input.thoughtNumber;
        }

        final thoughtData = ThoughtData(
          thought: input.thought,
          thoughtNumber: input.thoughtNumber,
          totalThoughts: adjustedTotalThoughts,
          nextThoughtNeeded: input.nextThoughtNeeded,
          isRevision: input.isRevision,
          revisesThought: input.revisesThought,
          branchFromThought: input.branchFromThought,
          branchId: input.branchId,
          needsMoreThoughts: input.needsMoreThoughts,
        );

        thinkingTracker.addThought(thoughtData);

        if (verbose) {
          print(thinkingTracker.formatThought(thoughtData));
        }

        final responseData = {
          'thought_number': thoughtData.thoughtNumber,
          'total_thoughts': thoughtData.totalThoughts,
          'next_thought_needed': thoughtData.nextThoughtNeeded,
          'branches': thinkingTracker.branches.keys.toList(),
          'thought_history_length': thinkingTracker.thoughtHistory.length,
        };

        return 'Sequential thinking step completed.\n\n'
            'Status:\n${jsonEncode(responseData)}';
      } catch (e) {
        return 'Sequential thinking failed: $e';
      }
    },
    getInputFromJson: SequentialThinkingInput.fromJson,
  );
}
