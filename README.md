# 🤖 PubMind

**Your intelligent AI assistant for Dart and Flutter package management**

PubMind is an AI-powered CLI tool that revolutionizes how you discover, evaluate, and install packages from pub.dev. Say goodbye to dependency hell and hello to smart, context-aware package recommendations.

[![Pub Version](https://img.shields.io/pub/v/pubmind)](https://pub.dev/packages/pubmind)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev)

---

## ✨ Features

### 🧠 AI-Powered Intelligence

- **Natural Language Search**: Just describe what you need - "I need state management" or "add http client"
- **Context-Aware Recommendations**: Analyzes your project to suggest packages that fit your needs
- **Smart Reasoning**: Uses advanced sequential thinking to break down complex decisions
- **Conflict Resolution**: Automatically detects and resolves dependency conflicts

### 🔍 Package Discovery

- **Intelligent Search**: Find packages using keywords or natural language
- **Detailed Analysis**: Get comprehensive metrics (pub points, popularity, likes, maintenance status)
- **Comparative Scoring**: Compare multiple packages side-by-side with intelligent ranking
- **Quality Assessment**: Evaluates packages based on pub points, popularity, and maintenance

### 🛡️ Safety First

- **Compatibility Checking**: Dry-run verification before any installation
- **Automatic Backups**: Your pubspec.yaml is backed up before every change
- **Rollback on Failure**: Automatic restoration if installation fails
- **Conflict Detection**: Identifies version conflicts before they break your project

### 💬 Interactive Chat Mode

- **Conversational Interface**: Chat with AI about your package needs
- **Project Context**: AI understands your Dart/Flutter project structure
- **Multi-turn Conversations**: Build on previous discussions naturally
- **Command History**: Review and replay previous interactions

---

## 🚀 Installation

### Prerequisites

- Dart SDK 3.0.0 or higher
- OpenAI API key

### Install Globally

```bash
dart pub global activate pubmind
```

### Set Up API Key

```bash
 pubmind --api-key sk-proj-...
 # or
 pubmind config
```

## 📖 Usage

### Quick Start

Navigate to your Dart or Flutter project:

```bash
cd your-project
pubmind chat
```

Then ask PubMind anything:

```
You > I need a state management solution

AI > I'll help you find the best state management package...
[AI analyzes your project and recommends options]

You > install riverpod

AI > Installing riverpod with compatibility checks...
✓ Package installed successfully!
```

### Command Reference

```bash
# Start interactive chat mode
pubmind chat

# Get help
pubmind --help

# Check version
pubmind --version
```

### Interactive Commands

Inside chat mode, use these commands:

```
/help      - Show available commands
/clear     - Clear conversation history
/history   - Show conversation history
/exit      - Exit chat mode
```

---

## 💡 Examples

### Example 1: Finding a Package

```
You > I need a package for HTTP requests

AI > Let me search for HTTP client packages for you...

Found top candidates:
1. http - Official Dart HTTP client
   - Pub Points: 150/160
   - Popularity: 98%
   - Likes: 2,341

2. dio - Powerful HTTP client with interceptors
   - Pub Points: 140/160
   - Popularity: 96%
   - Likes: 3,892

Based on your needs, I recommend dio for advanced features
or http for simplicity. Which would you prefer?
```

### Example 2: Resolving Conflicts

```
You > add freezed

AI > Checking compatibility...
⚠ Detected conflict: freezed requires meta ^1.9.0
   but your project uses meta ^1.11.0

Analyzing solutions...
✓ Solution found: Adjust freezed version to ^2.4.1
  This version is compatible with your dependencies.

Install freezed ^2.4.1? (yes/no)

You > yes

AI > Installing freezed ^2.4.1...
✓ Running pub get...
✓ Installation successful!
```

### Example 3: Getting Package Information

```
You > tell me about riverpod

AI > Fetching information about riverpod...

Package: riverpod
Version: 2.4.9
Pub Points: 150/160
Popularity: 95%
Likes: 4,521

Description: A reactive caching and data-binding framework.
Riverpod is a complete rewrite of Provider with improvements
in performance, developer experience, and features.

Homepage: https://riverpod.dev
Repository: https://github.com/rrousselGit/river_pod

Dependencies: meta, state_notifier
Dev Dependencies: test, mockito

Would you like to install this package?
```

### Example 4: Comparing Packages

```
You > compare provider vs riverpod

AI > Comparing state management solutions...

Sequential thinking: Analyzing trade-offs...
[Thought 1/5] Provider is official, simple, widely adopted
[Thought 2/5] Riverpod offers better performance and safety
[Thought 3/5] Considering your project type: Flutter
[Thought 4/5] Recommendation ready

Comparison Results:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Package    | Score | Pub Points | Popularity | Likes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
riverpod   | 95/100| 150/160   | 95%        | 4,521
provider   | 92/100| 150/160   | 97%        | 5,234
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Recommendation: riverpod
Reasoning:
- Best type safety and compile-time checks
- Better performance than Provider
- Modern API with excellent documentation
- More maintainable for large projects
- Official Dart team recommendation
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Development Setup

```bash
# Clone the repository
git clone https://github.com/VenbrinoDevelopers/pubmind.git
cd pubmind

# Install dependencies
dart pub get

# Run tests
dart test

# Run locally
dart run bin/pubmind.dart chat
```

### Contribution Guidelines

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/VenbrinoDevelopers/pubmind/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/VenbrinoDevelopers/pubmind/discussions)
- 📧 **Email**: precious@venbrinodevs.com
- 🐦 **Twitter**: [@precious_tagy](https://twitter.com/precious_tagy)

<div align="center">

**Made with ❤️ by Venbrino Developers**

[Website](https://venbrinodevs.com) • [GitHub](https://github.com/VenbrinoDevelopers) • [Twitter](https://twitter.com/@precious_tagy)

</div>
