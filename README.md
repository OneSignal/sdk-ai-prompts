# OneSignal SDK AI Prompts

AI-powered SDK integration prompts for OneSignal. This repository contains structured prompts that enable AI coding assistants (Cursor, GitHub Copilot, etc.) to automatically integrate the OneSignal SDK into mobile and web applications.

## Live Site

Visit the GitHub Pages site to get started:

**[https://onesignal.github.io/sdk-ai-prompts/](https://onesignal.github.io/sdk-ai-prompts/)**

## Supported Platforms

- **Android** (Kotlin & Java)
- **iOS** (Swift & Objective-C)
- **Flutter** (Dart)
- **Unity** (C#)
- **React Native** (JavaScript & TypeScript)

## How It Works

1. **Select your platform** on the homepage
2. **Copy the AI prompt** that appears
3. **Paste into your AI-enabled IDE** (Cursor, GitHub Copilot Chat, etc.)
4. **Answer a few questions** (App ID, language preference)
5. **Let the AI integrate** the OneSignal SDK
6. **Review the PR** with all changes ready to merge

## Quick Start

Copy and paste this prompt into your AI editor:

```
You are an AI coding agent.

Read and follow the integration instructions at:
https://onesignal.github.io/sdk-ai-prompts/integrate.html?platform=android

Fetch and read both of these files:
- https://onesignal.github.io/sdk-ai-prompts/shared/guidelines.md
- https://onesignal.github.io/sdk-ai-prompts/android/integrate.md

Then integrate the OneSignal SDK into this codebase following all instructions.
```

Replace `android` with your platform: `ios`, `flutter`, `unity`, or `react-native`.

## Repository Structure

```
docs/
├── index.html              # Landing page with platform selector
├── integrate.html          # Dynamic prompt display page
├── styles.css              # Dark/light mode styles
├── shared/
│   └── guidelines.md       # Main integration prompt (all platforms)
├── android/
│   └── integrate.md        # Android-specific guidance
├── ios/
│   └── integrate.md        # iOS-specific guidance
├── flutter/
│   └── integrate.md        # Flutter-specific guidance
├── unity/
│   └── integrate.md        # Unity-specific guidance
└── react-native/
    └── integrate.md        # React Native-specific guidance
```

## What the AI Does

When you use these prompts, the AI will:

1. **Create a new branch** (`onesignal-integration`)
2. **Add the correct SDK version** for your platform
3. **Follow your existing architecture** (MVVM, MVC, etc.)
4. **Create a centralized OneSignal manager** class
5. **Handle threading correctly** (off main thread)
6. **Add unit tests** for the integration
7. **Create a Pull Request** with all changes
8. **Output a PR summary** for you to copy

## Demo Mode

If you don't have a OneSignal App ID, you can use the demo mode:

1. When asked for your App ID, say "use demo"
2. The AI will create a **Welcome View** with:
   - Email input field
   - Phone number input field
   - Submit button
3. On submit, it triggers a welcome journey (email + SMS)

## Raw Markdown Access

For AI agents that prefer raw markdown:

- `https://raw.githubusercontent.com/OneSignal/sdk-ai-prompts/main/docs/shared/guidelines.md`
- `https://raw.githubusercontent.com/OneSignal/sdk-ai-prompts/main/docs/{platform}/integrate.md`

## Features

- **Dark/Light Mode**: Automatically respects system preference
- **Copy to Clipboard**: Easy prompt copying
- **Platform Detection**: URL parameter based platform selection
- **Pre-flight Checklists**: Platform-specific verification steps
- **Code Examples**: Production-ready code snippets

## Development

### Local Preview

```bash
# Using Python
cd docs
python -m http.server 8000
# Visit http://localhost:8000

# Or using MkDocs
pip install mkdocs-material
mkdocs serve
```

### Deployment

The site automatically deploys to GitHub Pages on push to `main` via GitHub Actions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a Pull Request

## Links

- [OneSignal Documentation](https://documentation.onesignal.com/)
- [OneSignal Dashboard](https://onesignal.com/)
- [GitHub Repository](https://github.com/OneSignal/sdk-ai-prompts)

## License

MIT License - See [LICENSE](LICENSE) for details.
