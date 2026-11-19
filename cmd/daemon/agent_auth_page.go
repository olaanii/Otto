package main

import (
	"fmt"
	"html"
)

func renderAgentAuthPage(agentID, agentName, workspace, token string) string {
	safeName := html.EscapeString(agentName)
	safePath := html.EscapeString(workspace)
	safeToken := html.EscapeString(token)
	safeID := html.EscapeString(agentID)

	return fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"><title>Authorize Otto - %s</title>
  <style>
    body { background: #121214; color: #E1E1E6; font-family: Segoe UI, system-ui, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #202024; border: 1px solid #323238; border-radius: 12px; padding: 32px; width: 440px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); text-align: center; }
    .badge { display: inline-block; padding: 4px 12px; background: #00875F; color: #FFF; border-radius: 16px; font-size: 11px; font-weight: 600; margin-bottom: 12px; }
    h2 { margin: 8px 0 16px; font-size: 20px; font-weight: 600; }
    p { font-size: 13px; color: #A8A8B3; line-height: 1.5; margin: 0 0 16px; }
    .scope { background: #121214; border: 1px solid #29292E; border-radius: 8px; padding: 12px; text-align: left; font-size: 12px; margin-bottom: 20px; }
    .scope div { margin: 4px 0; color: #C4C4CC; }
    .btn { background: #4285F4; color: #FFF; border: none; padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; width: 100%%; transition: opacity 0.2s; }
    .btn:hover { opacity: 0.9; }
    .btn-secondary { background: transparent; color: #8D8D99; border: none; margin-top: 10px; cursor: pointer; }
    #success { display: none; color: #04D361; font-weight: 600; margin-top: 16px; font-size: 14px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">AGENT HANDSHAKE</div>
    <h2>Connect to %s</h2>
    <p>Otto is requesting authorization to connect with your active coding agent session.</p>
    <div class="scope">
      <div><strong>Target Workspace:</strong> %s</div>
      <div>&#10003; Continuous git working-tree diff monitoring</div>
      <div>&#10003; Autonomous commit slicing (&le; 80 LOC per unit)</div>
      <div>&#10003; Real-time event notifications via daemon</div>
    </div>
    <button id="btnAuth" class="btn" onclick="confirmAuth()">Authorize &amp; Confirm in Otto</button>
    <div id="success">&#10003; Connection Confirmed! You can now close this tab.</div>
    <button class="btn-secondary" onclick="window.close()">Cancel</button>
  </div>
  <script>
    async function confirmAuth() {
      const btn = document.getElementById('btnAuth');
      btn.innerText = 'Connecting...';
      btn.disabled = true;
      try {
        const res = await fetch('/api/agents/confirm', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({agentId: '%s', token: '%s'})
        });
        const data = await res.json();
        if (data.ok) {
          btn.style.display = 'none';
          document.getElementById('success').style.display = 'block';
          setTimeout(() => window.close(), 2500);
        } else {
          alert('Failed to confirm: ' + (data.error || 'Unknown error'));
          btn.innerText = 'Authorize & Confirm'; btn.disabled = false;
        }
      } catch (e) {
        alert('Error communicating with Otto daemon: ' + e);
        btn.innerText = 'Authorize & Confirm'; btn.disabled = false;
      }
    }
  </script>
</body>
</html>`, safeName, safeName, safePath, safeID, safeToken)
}
