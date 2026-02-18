# Contributing to AIKA x Shanuzz FMT

Thank you for considering contributing to this project! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [How to Contribute](#how-to-contribute)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Commit Guidelines](#commit-guidelines)
7. [Pull Request Process](#pull-request-process)

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Keep discussions professional
- Help others learn and grow

## Getting Started

### Prerequisites

1. Flutter SDK 3.0.0 or higher
2. Dart SDK 3.0.0 or higher
3. Google Chrome (for web development)
4. Git
5. Code editor (VS Code recommended)

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd "AIKA x Shanuzz FMT"

# Install dependencies
flutter pub get

# Run setup script
.\setup.ps1
```

## How to Contribute

### Reporting Bugs

Before creating a bug report:
1. Check if the issue already exists
2. Verify it's reproducible
3. Gather relevant information

When reporting:
- Use a clear, descriptive title
- Describe steps to reproduce
- Include expected vs actual behavior
- Add screenshots if applicable
- List your environment details

### Suggesting Features

Feature suggestions are welcome! Please:
1. Check if it's already suggested
2. Explain the use case
3. Describe the proposed solution
4. Consider alternatives

### Code Contributions

We welcome:
- Bug fixes
- Feature implementations
- Documentation improvements
- Performance optimizations
- UI/UX enhancements

## Development Workflow

### 1. Fork and Clone

```bash
git clone <your-fork-url>
cd "AIKA x Shanuzz FMT"
```

### 2. Create a Branch

```bash
# Format: type/description
git checkout -b feature/add-export-function
git checkout -b fix/login-validation
git checkout -b docs/update-readme
```

Branch types:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `refactor/` - Code refactoring
- `test/` - Test additions/changes
- `chore/` - Maintenance tasks

### 3. Make Changes

- Write clean, readable code
- Follow existing patterns
- Add comments for complex logic
- Update documentation if needed

### 4. Test Your Changes

```bash
# Run the app
flutter run -d chrome

# Build for production
flutter build web --release

# Manual testing checklist:
# - Feature works as expected
# - No console errors
# - Responsive on different screen sizes
# - Works with existing data
# - Error handling works
```

### 5. Commit Changes

```bash
git add .
git commit -m "feat: add export to CSV functionality"
```

### 6. Push and Create PR

```bash
git push origin feature/add-export-function
```

Then create a Pull Request on GitHub.

## Coding Standards

### Dart/Flutter

```dart
// Good practices:

// 1. Use const constructors where possible
const Text('Hello');

// 2. Use descriptive variable names
final userName = 'John Doe';

// 3. Add type annotations
final List<Entry> entries = [];

// 4. Use async/await properly
Future<void> loadData() async {
  try {
    final data = await apiService.getData();
    setState(() {
      _data = data;
    });
  } catch (e) {
    // Handle error
  }
}

// 5. Keep functions small and focused
void processData() {
  validateData();
  transformData();
  saveData();
}
```

### File Organization

```dart
// Import order:
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:http/http.dart';

// 4. Local imports
import '../models/user.dart';
import '../services/api_service.dart';
```

### Naming Conventions

```dart
// Classes: PascalCase
class UserProfile {}

// Variables/Functions: camelCase
String userName;
void loadUserData() {}

// Private members: _camelCase
String _privateVar;
void _privateMethod() {}

// Constants: SCREAMING_SNAKE_CASE or lowerCamelCase
const API_KEY = 'xxx';
const defaultTimeout = 30;
```

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

### Examples

```bash
# Feature
git commit -m "feat(auth): add biometric login support"

# Bug fix
git commit -m "fix(entry-form): resolve date picker validation issue"

# Documentation
git commit -m "docs(readme): add deployment instructions"

# With body
git commit -m "feat(export): add CSV export functionality

- Add export button to home screen
- Implement CSV generation
- Add download trigger
- Update documentation"
```

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No console errors
- [ ] Tested on multiple screen sizes
- [ ] Commit messages follow guidelines

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Screenshots
(if applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Tested thoroughly
```

### Review Process

1. Create PR with clear description
2. Address review comments
3. Get approval from maintainer
4. Squash and merge

### After Merge

- Delete your branch
- Update your local main branch
- Close related issues

## Questions?

If you have questions:
1. Check existing documentation
2. Review closed issues/PRs
3. Open a discussion
4. Contact the maintainers

## Recognition

Contributors will be recognized in:
- CHANGELOG.md
- README.md (Contributors section)
- Release notes

Thank you for contributing! 🎉
