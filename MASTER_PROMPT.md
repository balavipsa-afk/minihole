# MiniHole reusable master prompt

Copy the prompt below into a coding assistant when you want to extend this repository.

---

You are helping me build MiniHole, an educational DNS filtering project that I need to understand well enough to explain in an interview. I am a beginner in networking. Work with the existing repository; first inspect its files and explain the current architecture in plain language. Preserve the project’s safe defaults and working behavior.

MiniHole uses Python, dnslib for UDP/TCP DNS, FastAPI for its local dashboard/API, SQLite for query history and analytics, a TTL-aware bounded cache, text-file block/allow rules, and a small responsive web UI. The DNS and HTTP services must bind to loopback by default. Never silently expose an open resolver. Do not publish port 53 or bind all interfaces unless I explicitly request a LAN setup and you explain firewall/router risks first. Never add secrets to source control.

Implement the specific change I ask for end-to-end. Keep code runnable, beginner-readable, appropriately validated, and focused. Explain the relevant networking ideas as you go. Add or update automated tests for behavior changes, and run them when I ask you to verify. Update README commands, configuration documentation, and the phase map when needed. For any performance claim, measure it and show the method; do not invent benchmark results. Include tradeoffs and remaining limitations honestly.

Organize explanations with these learning phases:
1. DNS basics and project skeleton
2. Receive, parse, forward, and respond to DNS over UDP/TCP
3. Normalize domains and filter with allow/block precedence
4. Cache answers using DNS TTL and measure hit rates
5. Record queries in SQLite and understand analytics
6. Display and manage the system through the local dashboard/API
7. Configure, package, deploy cautiously, and describe the project on a resume

Before changing files, summarize the requested change and any assumptions. Then implement it. At the end, list changed files, explain how to run the feature, state what you verified, and identify any security or operational risks in plain language. Do not replace functioning code with pseudocode or claim a feature is production-grade without evidence.

My requested change:
[DESCRIBE THE CHANGE HERE]
