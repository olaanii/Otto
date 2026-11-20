package main

import (
	"fmt"
	"html"
)

func renderAgentAuthPage(agentID, agentName, workspace, token string) string {
	safeName, safePath := html.EscapeString(agentName), html.EscapeString(workspace)
	safeToken, safeID := html.EscapeString(token), html.EscapeString(agentID)

	return fmt.Sprintf(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"><title>Authorize Otto - %s</title>
  <style>
    body { background: #121214; color: #E1E1E6; font-family: Segoe UI, system-ui, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .card { background: #202024; border: 1px solid #323238; border-radius: 12px; padding: 28px; width: 440px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); text-align: center; }
    .badge { display: inline-block; padding: 4px 12px; background: #00875F; color: #FFF; border-radius: 16px; font-size: 11px; font-weight: 600; margin-bottom: 12px; }
    h2 { margin: 8px 0 12px; font-size: 20px; font-weight: 600; }
    p { font-size: 13px; color: #A8A8B3; line-height: 1.5; margin: 0 0 16px; }
    .scope { background: #121214; border: 1px solid #29292E; border-radius: 8px; padding: 12px; text-align: left; font-size: 12px; margin-bottom: 16px; }
    .scope div { margin: 4px 0; color: #C4C4CC; }
    .btn { background: #4285F4; color: #FFF; border: none; padding: 11px 20px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; width: 100%%; }
    .btn:hover { opacity: 0.9; }
    .btn-secondary { background: transparent; color: #8D8D99; border: none; margin-top: 8px; cursor: pointer; }
    #success { display: none; margin-top: 10px; }
    .check { font-size: 36px; color: #04D361; margin-bottom: 8px; }
  </style>
</head>
<body>
  <div class="card">
    <div id="content">
      <div class="badge">AGENT HANDSHAKE</div>
      <h2>Connect to %s</h2>
      <p>Otto is requesting authorization to connect with your active coding agent session.</p>
      <div class="scope">
        <div><strong>Workspace:</strong> %s</div>
        <div>&#10003; Continuous git working-tree diff monitoring</div>
        <div>&#10003; Autonomous commit slicing (&le; 80 LOC per unit)</div>
        <div>&#10003; Real-time event notifications via daemon</div>
      </div>
      <button id="btnAuth" class="btn" onclick="confirmAuth()">Authorize &amp; Confirm in Otto</button>
      <button class="btn-secondary" onclick="closeTab()">Cancel</button>
    </div>
    <div id="success">
      <div class="check">&#10003;</div>
      <h2>Connection Confirmed!</h2>
      <p>Otto is actively slicing atomic commits for your workspace.<br>Closing tab and returning to Otto (<span id="t">2</span>s)...</p>
      <button class="btn" onclick="closeTab()">Return to Otto Desktop</button>
      <p style="font-size: 11px; color: #71717A; margin-top: 10px;">If tab remains open by browser policy, you may close it safely.</p>
    </div>
  </div>
  <script>
    function closeTab() {
      try { window.location.href = 'otto://connected?agent=%s'; } catch(_) {}
      try { window.open('', '_self'); window.close(); } catch(_) {}
      try { window.close(); } catch(_) {}
    }
    async function confirmAuth() {
      const btn = document.getElementById('btnAuth');
      btn.innerText = 'Connecting...'; btn.disabled = true;
      try {
        const res = await fetch('/api/agents/confirm', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({agentId: '%s', token: '%s'})});
        const data = await res.json();
        if (data.ok) {
          document.getElementById('content').style.display = 'none';
          document.getElementById('success').style.display = 'block';
          closeTab();
          let c = 2; setInterval(() => { c--; if (c >= 0) document.getElementById('t').innerText = c; if (c <= 0) closeTab(); }, 1000);
        } else {
          alert('Failed to confirm: ' + (data.error || 'Unknown error')); btn.innerText = 'Authorize & Confirm'; btn.disabled = false;
        }
      } catch (e) { alert('Error: ' + e); btn.innerText = 'Authorize & Confirm'; btn.disabled = false; }
    }
  </script>
</body>
</html>`, safeName, safeName, safePath, safeID, safeID, safeToken)
}
