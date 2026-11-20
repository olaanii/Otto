# Dual-Engine LLM Architecture: BYOK & Local CLI Subscriptions

## 1. Executive Summary
This architecture provides users two distinct, cost-effective methods to power Otto's autonomous commit slicing and stack refinement without requiring cloud servers, databases, or OAuth callback domains:
1. **Approach 1: Bring Your Own Key (BYOK)**:
   - Supports Google AI Studio (Free tier), OpenAI, Anthropic, OpenRouter, and Local Ollama / LM Studio.
   - Standardized on OpenAI-compatible / Gemini REST format.
   - Outbound requests routed through native Go daemon to prevent browser CORS restrictions.
   - Keys encrypted via Windows DPAPI (`flutter_secure_storage`).
2. **Approach 2: Wrap Local CLIs (Subscription Access for $0 Extra Cost)**:
   - Directly harnesses user's existing flat-rate subscriptions (Google Antigravity Google AI Pro Plan, Claude Code, Codex).
   - Automatically detects installed CLI binaries (`agy`, `claude`, `codex`).
   - Executes prompts via headless child processes and streams stdout back to Otto.

## 2. Daemon REST Specifications
- `GET /api/llm/providers`: Returns available BYOK providers, detected local CLIs, active engine mode (`byok` or `cli`), and current model.
- `POST /api/llm/configure`: Updates active engine, provider ID, API keys, custom base URLs, and model name.
- `POST /api/llm/test-connection`: Tests either BYOK API connectivity or CLI execution and returns latency and health status.
- `POST /api/llm/generate`: Dispatches prompt execution through the selected engine.

## 3. UI Specifications
The Settings modal (`settings_dialog.dart`) features a dual-mode selector:
- **Local CLI Wrappers Tab**: Visual cards for detected CLIs (`agy`, `claude`, `codex`), installation status, subscription plan details, and a "Test CLI" button.
- **BYOK Tab**: Provider selector, API key input, base URL override, model selector, and "Test Connection" button.
