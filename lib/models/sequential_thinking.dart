class ThoughtData {
  final String thought;
  final int thoughtNumber;
  final int totalThoughts;
  final bool nextThoughtNeeded;
  final bool? isRevision;
  final int? revisesThought;
  final int? branchFromThought;
  final String? branchId;
  final bool? needsMoreThoughts;

  ThoughtData({
    required this.thought,
    required this.thoughtNumber,
    required this.totalThoughts,
    required this.nextThoughtNeeded,
    this.isRevision,
    this.revisesThought,
    this.branchFromThought,
    this.branchId,
    this.needsMoreThoughts,
  });

  Map<String, dynamic> toJson() => {
        'thought': thought,
        'thought_number': thoughtNumber,
        'total_thoughts': totalThoughts,
        'next_thought_needed': nextThoughtNeeded,
        if (isRevision != null) 'is_revision': isRevision,
        if (revisesThought != null) 'revises_thought': revisesThought,
        if (branchFromThought != null) 'branch_from_thought': branchFromThought,
        if (branchId != null) 'branch_id': branchId,
        if (needsMoreThoughts != null) 'needs_more_thoughts': needsMoreThoughts,
      };
}

class SequentialThinkingInput {
  final String thought;
  final bool nextThoughtNeeded;
  final int thoughtNumber;
  final int totalThoughts;
  final bool? isRevision;
  final int? revisesThought;
  final int? branchFromThought;
  final String? branchId;
  final bool? needsMoreThoughts;

  SequentialThinkingInput({
    required this.thought,
    required this.nextThoughtNeeded,
    required this.thoughtNumber,
    required this.totalThoughts,
    this.isRevision,
    this.revisesThought,
    this.branchFromThought,
    this.branchId,
    this.needsMoreThoughts,
  });

  SequentialThinkingInput.fromJson(Map<String, dynamic> json)
      : thought = json['thought'] as String,
        nextThoughtNeeded = json['next_thought_needed'] as bool,
        thoughtNumber = (json['thought_number'] as num).toInt(),
        totalThoughts = (json['total_thoughts'] as num).toInt(),
        isRevision = json['is_revision'] as bool?,
        revisesThought = (json['revises_thought'] as num?)?.toInt(),
        branchFromThought = (json['branch_from_thought'] as num?)?.toInt(),
        branchId = json['branch_id'] as String?,
        needsMoreThoughts = json['needs_more_thoughts'] as bool?;
}

class SequentialThinkingTracker {
  final List<ThoughtData> thoughtHistory = [];
  final Map<String, List<ThoughtData>> branches = {};

  void addThought(ThoughtData thought) {
    thoughtHistory.add(thought);

    if (thought.branchFromThought != null && thought.branchId != null) {
      branches.putIfAbsent(thought.branchId!, () => []).add(thought);
    }
  }

  void clear() {
    thoughtHistory.clear();
    branches.clear();
  }

  String formatThought(ThoughtData thought) {
    String prefix;
    String context;

    if (thought.isRevision == true) {
      prefix = '🔄 Revision';
      context = ' (revising thought ${thought.revisesThought})';
    } else if (thought.branchFromThought != null) {
      prefix = '🌿 Branch';
      context =
          ' (from thought ${thought.branchFromThought}, ID: ${thought.branchId})';
    } else {
      prefix = '💭 Thought';
      context = '';
    }

    final header =
        '$prefix ${thought.thoughtNumber}/${thought.totalThoughts}$context';
    final borderLength = [header.length, thought.thought.length]
            .reduce((a, b) => a > b ? a : b) +
        4;
    final border = '─' * borderLength;

    return '''
┌$border┐
│ ${header.padRight(borderLength - 2)} │
├$border┤
│ ${thought.thought.padRight(borderLength - 2)} │
└$border┘''';
  }

  String getSummary() {
    return '''
Thinking Progress:
  Total thoughts: ${thoughtHistory.length}
  Active branches: ${branches.length}
  Branch IDs: ${branches.keys.join(', ')}
''';
  }
}
