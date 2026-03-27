/// Action Plan model from backend webhook
class ActionPlan {
  final List<CalendarEvent> calendarEvents;
  final List<TodoistTask> todoistTasks;
  final List<Resource> resources;
  final String reasoning;

  const ActionPlan({
    required this.calendarEvents,
    required this.todoistTasks,
    required this.resources,
    required this.reasoning,
  });

  factory ActionPlan.fromJson(Map<String, dynamic> json) {
    return ActionPlan(
      calendarEvents: (json['calendar_events'] as List<dynamic>?)
              ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      todoistTasks: (json['todoist_tasks'] as List<dynamic>?)
              ?.map((e) => TodoistTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      resources: (json['resources'] as List<dynamic>?)
              ?.map((e) => Resource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calendar_events': calendarEvents.map((e) => e.toJson()).toList(),
      'todoist_tasks': todoistTasks.map((e) => e.toJson()).toList(),
      'resources': resources.map((e) => e.toJson()).toList(),
      'reasoning': reasoning,
    };
  }

  int get totalActions =>
      calendarEvents.length + todoistTasks.length + resources.length;

  bool get isEmpty => totalActions == 0;
}

/// Calendar Event
class CalendarEvent {
  final String summary;
  final String startTime;
  final String endTime;
  final String location;
  final String description;
  final String? recurrence;

  const CalendarEvent({
    required this.summary,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.description,
    this.recurrence,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      summary: json['summary'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      recurrence: json['recurrence'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'description': description,
      'recurrence': recurrence,
    };
  }
}

/// Todoist Task
class TodoistTask {
  final String taskName;
  final String taskDue;
  final int priority;
  final List<String> labels;
  final String description;

  const TodoistTask({
    required this.taskName,
    required this.taskDue,
    required this.priority,
    required this.labels,
    required this.description,
  });

  factory TodoistTask.fromJson(Map<String, dynamic> json) {
    return TodoistTask(
      taskName: json['task_name'] as String? ?? '',
      taskDue: json['task_due'] as String? ?? '',
      priority: json['priority'] as int? ?? 2,
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_name': taskName,
      'task_due': taskDue,
      'priority': priority,
      'labels': labels,
      'description': description,
    };
  }
}

/// Resource
class Resource {
  final String title;
  final String url;
  final String description;
  final String category;

  const Resource({
    required this.title,
    required this.url,
    required this.description,
    required this.category,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'category': category,
    };
  }
}

/// Backend Update (webhook payload)
class BackendUpdate {
  final String type;
  final String userId;
  final String callId;
  final DateTime timestamp;
  final Classification classification;
  final ActionPlan actionPlan;
  final UpdateStats stats;

  const BackendUpdate({
    required this.type,
    required this.userId,
    required this.callId,
    required this.timestamp,
    required this.classification,
    required this.actionPlan,
    required this.stats,
  });

  factory BackendUpdate.fromJson(Map<String, dynamic> json) {
    return BackendUpdate(
      type: json['type'] as String? ?? 'action_plan_ready',
      userId: json['userId'] as String? ?? '',
      callId: json['callId'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      classification: Classification.fromJson(
          json['classification'] as Map<String, dynamic>? ?? {}),
      actionPlan: ActionPlan.fromJson(
          json['action_plan'] as Map<String, dynamic>? ?? {}),
      stats:
          UpdateStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Classification from context glean agent
class Classification {
  final String primaryNeed;
  final double confidence;
  final String stressLevel;

  const Classification({
    required this.primaryNeed,
    required this.confidence,
    required this.stressLevel,
  });

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      primaryNeed: json['primary_need'] as String? ?? 'seniors_help',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      stressLevel: json['stress_level'] as String? ?? 'regular',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_need': primaryNeed,
      'confidence': confidence,
      'stress_level': stressLevel,
    };
  }
}

/// Statistics from workflow
class UpdateStats {
  final int newActions;
  final int duplicatesSkipped;
  final String kbQueried;
  final int totalActionsAvailable;
  final int actionsInWebhook;

  const UpdateStats({
    required this.newActions,
    required this.duplicatesSkipped,
    required this.kbQueried,
    required this.totalActionsAvailable,
    required this.actionsInWebhook,
  });

  factory UpdateStats.fromJson(Map<String, dynamic> json) {
    return UpdateStats(
      newActions: json['new_actions'] as int? ?? 0,
      duplicatesSkipped: json['duplicates_skipped'] as int? ?? 0,
      kbQueried: json['kb_queried'] as String? ?? '',
      totalActionsAvailable: json['total_actions_available'] as int? ?? 0,
      actionsInWebhook: json['actions_in_webhook'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'new_actions': newActions,
      'duplicates_skipped': duplicatesSkipped,
      'kb_queried': kbQueried,
      'total_actions_available': totalActionsAvailable,
      'actions_in_webhook': actionsInWebhook,
    };
  }
}
