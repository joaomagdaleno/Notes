/// Represents a note template.
class NoteTemplate {
  /// Creates a note template.
  const NoteTemplate({
    required this.name,
    required this.description,
    required this.contentMarkdown,
  });

  /// The name of the template.
  final String name;

  /// A brief description of the template.
  final String description;

  /// The markdown content of the template.
  final String contentMarkdown;
}

/// Service for managing note templates.
class TemplateService {
  /// Returns a list of available templates.
  static List<NoteTemplate> getTemplates() {
    return [
      const NoteTemplate(
        name: 'Meeting Note',
        description: 'Template for meeting minutes and action items.',
        contentMarkdown: '''
# Meeting: [Topic]
**Date:** [Date]
**Attendees:** [Names]

## Agenda
- [ ] Item 1
- [ ] Item 2

## Notes
> [!NOTE] Capture key decisions here.

- Discussion point 1...

## Action Items
- [ ] Task 1 (Assignee)
- [ ] Task 2 (Assignee)
''',
      ),
      const NoteTemplate(
        name: 'Daily Journal',
        description: 'Template for daily reflection and tracking.',
        contentMarkdown: '''
# Daily Journal - [Date]

## 🌟 Highlights
- What went well today?

## 🧠 Thoughts & Reflections
- 

## 📝 Todo List
- [ ] 
- [ ] 

## 🔮 Tomorrow
- Goal for tomorrow: 
''',
      ),
      const NoteTemplate(
        name: 'Project Plan',
        description: 'Basic structure for project planning.',
        contentMarkdown: '''
# Project: [Name]

## 🎯 Objective
Briefly describe the goal of this project.

## 📅 Milestones
| Phase | Deadline | Status |
|---|---|---|
| Planning | [Date] | Pending |
| Execution | [Date] | Pending |
| Review | [Date] | Pending |

## 🛠 Tasks
- [ ] Setup repo
- [ ] implementation
- [ ] Testing

## 🔗 Resources
- [Link](url)
''',
      ),
    ];
  }
}
