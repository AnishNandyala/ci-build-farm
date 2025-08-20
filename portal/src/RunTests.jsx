import React, { useState } from "react";
import axios from "axios";

const API_BASE = process.env.REACT_APP_API_BASE || "";

console.log("Portal API_BASE:", API_BASE);

export default function RunTests() {
  const [repo, setRepo] = useState("");
  const [branch, setBranch] = useState("main");
  const [agents, setAgents] = useState(1);
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setLoading(true);
    setStatus("Sending job...");

    try {
      const res = await axios.post(`${API_BASE}/run`, {
        repo,
        branch,
        agents
      });

      if (res.status >= 200 && res.status < 300) {
        const body = res.data || {};
        setStatus(`Queued job ${body.job_id || "(id unknown)"}`);
      } else {
        setStatus(`Error: ${res.statusText}`);
      }
    } catch (err) {
      const msg =
        err?.response?.data?.error || err.message || "Network or server error";
      setStatus(`Error: ${msg}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <section>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="repo">Repository</label>
        </div>
        <div style={{ marginBottom: 8 }}>
          <input
            id="repo"
            value={repo}
            onChange={(e) => setRepo(e.target.value)}
            placeholder="https://github.com/youruser/repo.git"
            required
          />
        </div>

        <div style={{ marginBottom: 8 }}>
          <label htmlFor="branch">Branch</label>
          <input
            id="branch"
            value={branch}
            onChange={(e) => setBranch(e.target.value)}
            placeholder="main"
            style={{ width: 200 }}
          />
        </div>

        <div style={{ marginBottom: 12 }}>
          <label htmlFor="agents">Agents</label>
          <input
            id="agents"
            type="number"
            min="1"
            max="10"
            value={agents}
            onChange={(e) => setAgents(Number(e.target.value))}
            style={{ width: 120 }}
          />
        </div>

        <div>
          <button type="submit" disabled={loading}>
            {loading ? "Sending…" : "Run tests"}
          </button>
        </div>
      </form>

      {status && <div className="status">{status}</div>}
      <div style={{ marginTop: 18 }}>
        <small>
          API base: <code>{API_BASE || "(not set)"}</code>
        </small>
      </div>
    </section>
  );
}
