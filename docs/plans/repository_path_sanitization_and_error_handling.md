# Repository Path Sanitization and Human-Readable Error Handling

## 1. Problem Statement
When users copy repository paths in Windows Explorer using "Copy as Path", Windows encloses the string in literal double quotes (e.g., `"C:\Users\olani\Desktop\olani\mile"`). If submitted to the workspace open endpoint without sanitization:
1. `os.Stat` fails because literal double quotes are invalid filesystem path characters on Windows.
2. In older builds or unhandled edge cases, HTTP 400 was thrown.
3. In `ApiClient._handleDioError`, only `error.response?.data?['message']` was parsed, ignoring `data['error']`. This caused Dio to fall back to the raw internal HTTP status message:
   `ServerException: This exception was thrown because the response has a status code of 400 and RequestOptions.validateStatus was configured to throw for this status code...`
4. The running release executables (`Otto.exe` and `otto_frontend.exe`) were out of sync with the latest worktree commits.

## 2. Architectural Solution
1. **Frontend Sanitization (`windows_shell_screen.dart`)**:
   - Strip leading and trailing quotes (`"` and `'`) before dispatching `ApiEndpoints.workspaceOpen`.
   - Provide concise error extraction when displaying `ServerException`.
2. **Daemon-Level Sanitization (`cmd/daemon/integrations.go`)**:
   - Strip outer quotes (`"'` and backticks) in `POST /api/workspace/open`.
   - Ensure clean `HTTP 200` responses with descriptive JSON `error` messages instead of unhandled 400 errors.
3. **Network Error Extraction (`frontend_flutter/lib/core/network/api_client.dart`)**:
   - Check `error.response?.data?['error']` first before `'message'` or `error.message`.
4. **Binary Sync & Release Rebuild**:
   - Merge `flutter_build_windows` into `main`.
   - Recompile both `Otto.exe` and `otto_frontend.exe`.
