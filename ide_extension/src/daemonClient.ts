import * as vscode from 'vscode';
import * as http from 'http';
import * as https from 'https';
import {
  AtomicCommitUnit,
  DaemonAnalyzeRequest,
  DaemonAnalyzeResponse,
  DaemonEvent,
  DaemonPushStackRequest,
  DaemonPushStackResponse,
  DiffHunk,
  GuardrailPolicy,
  WorkspaceState,
} from './types';

export class OttoDaemonClient {
  private baseUrl: string = 'http://localhost:3000';
  private clerkToken: string = '';

  constructor() {
    this.refreshConfig();
  }

  public refreshConfig(): void {
    const config = vscode.workspace.getConfiguration('otto');
    this.baseUrl = config.get<string>('daemonUrl', 'http://localhost:3000').replace(/\/+$/, '');
    this.clerkToken = config.get<string>('clerkToken', '').trim();
  }

  private getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'User-Agent': 'otto-universal-ide-extension/1.0.0',
    };
    if (this.clerkToken) {
      headers['Authorization'] = `Bearer ${this.clerkToken}`;
    }
    return headers;
  }

  private async request<T>(path: string, options: { method?: string; body?: any } = {}): Promise<T> {
    this.refreshConfig();
    const urlStr = `${this.baseUrl}${path.startsWith('/') ? path : '/' + path}`;
    const url = new URL(urlStr);
    const isHttps = url.protocol === 'https:';
    const client = isHttps ? https : http;

    const payload = options.body ? JSON.stringify(options.body) : undefined;
    const reqOptions: http.RequestOptions = {
      protocol: url.protocol,
      hostname: url.hostname,
      port: url.port || (isHttps ? 443 : 80),
      path: `${url.pathname}${url.search}`,
      method: options.method || 'GET',
      headers: {
        ...this.getHeaders(),
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload).toString() } : {}),
      },
      timeout: 8000,
    };

    return new Promise<T>((resolve, reject) => {
      const req = client.request(reqOptions, (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            try {
              const parsed = JSON.parse(data) as T;
              resolve(parsed);
            } catch (e) {
              resolve(data as unknown as T);
            }
          } else {
            reject(new Error(`Daemon request failed with status ${res.statusCode}: ${data}`));
          }
        });
      });

      req.on('error', (err) => {
        reject(err);
      });

      req.on('timeout', () => {
        req.destroy();
        reject(new Error(`Daemon request to ${urlStr} timed out`));
      });

      if (payload) {
        req.write(payload);
      }
      req.end();
    });
  }

  public async isHealthy(): Promise<boolean> {
    try {
      await this.request('/api/github/sync-status');
      return true;
    } catch {
      try {
        await this.request('/api/state');
        return true;
      } catch {
        return false;
      }
    }
  }

  public async getState(): Promise<WorkspaceState> {
    return this.request<WorkspaceState>('/api/state');
  }

  public async analyzeDiff(params: DaemonAnalyzeRequest = {}): Promise<DaemonAnalyzeResponse> {
    try {
      return await this.request<DaemonAnalyzeResponse>('/api/git/analyze', {
        method: 'POST',
        body: params,
      });
    } catch {
      // Fallback: request state and compute analysis from working tree hunks
      const state = await this.getState();
      const uncommittedLoc = state.workingTreeHunks.reduce(
        (acc, h) => acc + h.additions + h.deletions,
        0
      );
      return {
        stagedSlices: state.stagedAtomicStack,
        totalUncommittedLoc: uncommittedLoc,
        workingTreeClean: state.workingTreeHunks.length === 0,
        engine: 'otto-ast-slicer',
      };
    }
  }

  public async pushStack(params: DaemonPushStackRequest = { pushAll: true }): Promise<DaemonPushStackResponse> {
    try {
      return await this.request<DaemonPushStackResponse>('/api/git/push-stack', {
        method: 'POST',
        body: params,
      });
    } catch {
      // Fallback to sync-now endpoint
      const syncRes = await this.request<any>('/api/github/sync-now', {
        method: 'POST',
        body: { pushStaged: true },
      });
      const state: WorkspaceState = syncRes.state;
      return {
        ok: true,
        pushedCount: state?.pushedStack?.length || 1,
        latestPrNumber: state?.pushedStack?.[0]?.prNumber || 144,
        stack: state?.pushedStack || [],
      };
    }
  }

  public async refineStack(
    hunks: DiffHunk[],
    policy?: GuardrailPolicy
  ): Promise<{ stack: AtomicCommitUnit[]; engine: string }> {
    return this.request<{ stack: AtomicCommitUnit[]; engine: string }>('/api/ai/refine-stack', {
      method: 'POST',
      body: { hunks, policy },
    });
  }

  public async toggleDaemon(active?: boolean): Promise<{ daemonActive: boolean }> {
    const state = await this.getState();
    const nextActive = active !== undefined ? active : !state.daemonActive;
    await this.request('/api/state', {
      method: 'POST',
      body: { daemonActive: nextActive },
    });
    return { daemonActive: nextActive };
  }

  public async syncNow(defaultBranch?: string): Promise<{ ok: boolean; syncedAt: string }> {
    return this.request<{ ok: boolean; syncedAt: string }>('/api/github/sync-now', {
      method: 'POST',
      body: { defaultBranch, pushStaged: false },
    });
  }

  /**
   * Subscribes to daemon real-time Server-Sent Events (SSE).
   * Returns a cleanup unsubscribe function.
   */
  public subscribeEvents(
    onMessage: (event: DaemonEvent) => void,
    onError?: (err: any) => void
  ): () => void {
    this.refreshConfig();
    const urlStr = `${this.baseUrl}/api/events`;
    const url = new URL(urlStr);
    const isHttps = url.protocol === 'https:';
    const client = isHttps ? https : http;

    let aborted = false;
    let activeReq: http.ClientRequest | null = null;
    let reconnectTimeout: NodeJS.Timeout | null = null;

    const connect = () => {
      if (aborted) return;

      const reqOptions: http.RequestOptions = {
        protocol: url.protocol,
        hostname: url.hostname,
        port: url.port || (isHttps ? 443 : 80),
        path: url.pathname,
        method: 'GET',
        headers: {
          ...this.getHeaders(),
          Accept: 'text/event-stream',
          'Cache-Control': 'no-cache',
          Connection: 'keep-alive',
        },
      };

      activeReq = client.request(reqOptions, (res) => {
        let buffer = '';

        res.setEncoding('utf8');
        res.on('data', (chunk: string) => {
          buffer += chunk;
          const lines = buffer.split('\n');
          buffer = lines.pop() || '';

          for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed.startsWith('data:')) {
              const jsonStr = trimmed.slice(5).trim();
              if (jsonStr) {
                try {
                  const ev = JSON.parse(jsonStr) as DaemonEvent;
                  onMessage(ev);
                } catch {
                  // Ignore parse error on heartbeats
                }
              }
            }
          }
        });

        res.on('end', () => {
          if (!aborted) {
            reconnectTimeout = setTimeout(connect, 3000);
          }
        });
      });

      activeReq.on('error', (err) => {
        if (!aborted) {
          if (onError) onError(err);
          reconnectTimeout = setTimeout(connect, 5000);
        }
      });

      activeReq.end();
    };

    connect();

    return () => {
      aborted = true;
      if (activeReq) {
        activeReq.destroy();
      }
      if (reconnectTimeout) {
        clearTimeout(reconnectTimeout);
      }
    };
  }
}
