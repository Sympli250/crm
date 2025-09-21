# LutecIA - Symplissime

This is a scaffold WinUI 3 desktop application (unpackaged) targeting .NET 9 and Windows App SDK.
It implements a modern Windows 11-style UI with NavigationView and MVVM structure.

## How to build

1. Install .NET 9 SDK and the Windows App SDK developer tools.
2. From the repository root on Windows, run `go.bat`.
3. The publish output will be in `publish\app`.

## Notes

- This project is an original scaffold created to match the requested feature list (NavigationView, Chat, Documents, History, Users, Settings).
- The LLM integration uses a minimal `LLMService` stub that echoes input. Replace it with real HTTP code for AnythingLLM/OpenAI.
- Mica effect and advanced WinUI theming are hinted but may require additional manifest/Windows SDK setup.

