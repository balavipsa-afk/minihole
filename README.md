# MiniHole — learn DNS filtering by building it

MiniHole is a small, runnable DNS filter and dashboard. It receives DNS questions, checks local rules, returns an empty answer for blocked names, and forwards other questions to an upstream resolver. It records decisions in SQLite and caches successful answers for the DNS answer's TTL.

> **Educational software:** this is a learning project, not a hardened replacement for a maintained network DNS appliance. Its DNS listener and API bind to `127.0.0.1` by default. Keep that setting until you understand the LAN cautions below.

## Quick start (Windows PowerShell)

Use Python 3.11 or newer. From this folder:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn minihole.api:app --host 127.0.0.1 --port 8000
```

Open <http://127.0.0.1:8000>. The demo dashboard starts with a few sample rows. API docs are at <http://127.0.0.1:8000/docs>. Stop with Ctrl+C.

### Try a DNS question locally

With the app running, open another PowerShell window:

```powershell
nslookup example.com 127.0.0.1 -port=5353
nslookup ads.example.test 127.0.0.1 -port=5353
```

The first asks MiniHole to forward a real domain (requires upstream network access). The second matches the included seed rule and is blocked. Since blocked responses are NODATA, `nslookup` may show “No records” instead of a dramatic block page. DNS does not itself display a block page.

If your `nslookup` version does not accept `-port`, use `Resolve-DnsName example.com -Server 127.0.0.1 -Port 5353` where supported, or `dig @127.0.0.1 -p 5353 example.com` if you have `dig` installed.

## Docker Compose

```powershell
Copy-Item .env.example .env
docker compose up --build
```

The Compose file publishes both the dashboard and DNS ports only on loopback. Browse to <http://127.0.0.1:8000>. Stop with `docker compose down`. Persistent SQLite and rule files live under `data/`.

## What happens to a DNS question?

```text
Client → UDP/TCP DNS listener → normalize name → allowlist? → blocklist?
                                                     │ blocked: empty answer
                                                     └ allowed → TTL cache → upstream DNS
                                                               → SQLite log → response
```

The upstream is configurable (Cloudflare `1.1.1.1` by default). MiniHole does not encrypt upstream DNS in this starter version. The cache is keyed by name/type/class, expires at the smallest positive TTL in the stored response, and reduces answer TTLs on cache hits so clients do not keep data beyond the cache's remaining lifetime. This is a learning implementation, not a full RFC-compliant recursive resolver.

## Learning phases and file map

1. **DNS basics and skeleton** — `minihole/config.py` holds environment settings; `.env.example` shows safe defaults.
2. **Receive and forward** — `minihole/dns_server.py` uses dnslib to serve UDP and TCP, forwards to an upstream, and returns `SERVFAIL` if it cannot reach it.
3. **Filter domains** — `minihole/filtering.py` normalizes case/IDNA and applies allow rules before block rules. A rule covers its domain and subdomains; `*.domain` is accepted too.
4. **Log and cache** — `minihole/cache.py` bounds memory and honors response TTL. Cache statistics are exposed through the API.
5. **SQLite analytics** — `minihole/store.py` logs client, name, type, decision, reason, latency, and cache-hit status.
6. **Dashboard/API** — `minihole/api.py` exposes stats, recent queries, and rule-management endpoints; `minihole/static/index.html` is the compact frontend.
7. **Package safely** — `Dockerfile`, `docker-compose.yml`, and `.env.example` support local development. The dashboard includes this safety boundary; `MASTER_PROMPT.md` is a reusable extension prompt.

| File | Purpose |
|---|---|
| `minihole/dns_server.py` | DNS request handling, UDP/TCP listeners and upstream forwarding |
| `minihole/filtering.py` | Domain normalization and rule decisions |
| `minihole/cache.py` | TTL expiry, size limit and cache counters |
| `minihole/store.py` | SQLite schema, query log and aggregates |
| `minihole/api.py` | FastAPI lifecycle, dashboard serving and API routes |
| `minihole/static/index.html` | Responsive dashboard, served by FastAPI |
| `data/blocklist.txt` | Example deny rules |
| `data/allowlist.txt` | Example override rules |
| `tests/test_core.py` | Filter precedence and cache TTL/capacity checks |
| `tests/test_integration.py` | Local dashboard, UDP/TCP filtering, forwarding and cache integration check |
| `MASTER_PROMPT.md` | Reusable prompt for future changes |

## Configuration

Copy `.env.example` to `.env` and edit values. Important settings:

| Setting | Default | Meaning |
|---|---|---|
| `DNS_HOST` | `127.0.0.1` | DNS bind address; loopback is private to this computer |
| `DNS_PORT` | `5353` | Non-privileged learning port; ordinary client DNS uses 53 |
| `API_HOST` | `127.0.0.1` | HTTP API bind address |
| `UPSTREAM_DNS` | `1.1.1.1` | Server MiniHole asks for allowed names |
| `DATABASE_PATH` | `./data/minihole.db` | SQLite file path |
| `DEMO_MODE` | `true` | Adds starter dashboard examples only if the database is empty |

The quick-start command explicitly keeps Uvicorn on loopback. `python main.py` uses `API_HOST` and `API_PORT` from configuration; Docker overrides the bind inside the container while publishing only to host loopback.

## API endpoints

- `GET /api/health` — process and DNS bind status
- `GET /api/stats` — counts, average latency, cache metrics and most-blocked names
- `GET /api/queries?limit=50` — recent events (maximum 200)
- `POST /api/rules/block` — JSON body `{"domain":"ads.example.test"}`
- `POST /api/rules/allow` — JSON body `{"domain":"safe.example.test"}`
- `POST /api/rules/reload` — re-read both rule files and clear cache

Rule edits are stored in the rule files and survive restart. There is no authentication in this learning version, which is one reason to keep the API on loopback.

## LAN testing: read before changing bind addresses

Port `5353` is useful for explicit test clients; many phones and operating systems cannot be configured to use a custom DNS port. A normal DNS client expects port `53`.

To experiment from another device on your own trusted Wi-Fi, first understand that setting `DNS_HOST=0.0.0.0` listens on every network interface. Also bind Uvicorn's API to loopback unless remote dashboard access is needed. Then restrict inbound firewall access to your private subnet and the DNS port, use a trusted network only, and verify the machine's private IP. Never forward the DNS port from your router to the public internet. Do not point a whole household/router at this educational service without testing and having a rollback plan. Avoid port 53 until you know no other resolver uses it and have accounted for elevated permissions. No automatic firewall/router changes are made by MiniHole.

## Tests and learning exercises

Install dependencies, then run:

```powershell
python -m unittest discover -s tests -v
```

The tests cover name normalization, allowlist precedence, subdomain matching, cache TTL expiry/capacity, and an end-to-end API plus UDP/TCP DNS run against a local stub upstream (so the integration check does not depend on public DNS). Useful next learning tasks: expose a rule deletion endpoint, add per-client analytics, and measure latency/cache hit rate using a repeatable workload. Record only measurements you actually ran.

## Benchmarking honestly

Use a scripted set of repeated and unique domains against the same upstream, record request count and elapsed time, and compare cold cache with warm cache. Repeat runs, report machine/network details and median or percentile latency. Keep block rate, cache hit rate and latency separate: a high hit rate does not prove DNS correctness. Do not benchmark against third-party infrastructure aggressively.

## Resume bullet (fill in real measured values)

> Built MiniHole, an educational DNS filtering service using Python, dnslib, FastAPI and SQLite; implemented UDP/TCP forwarding, allow/block rules, TTL-aware bounded caching, and a query analytics dashboard. Measured **[X% cache hit rate / Y ms median latency]** over **[N requests]** on **[environment]**.

Do not include bracketed sample metrics until you measure them yourself.

## Known limits

This is a forwarder/filter, not a recursive resolver. It uses plaintext upstream DNS and the seed blocklist is only for demonstration. The DNS logger writes synchronously to SQLite for clarity; heavy load can increase latency. It does not implement encrypted DNS, per-client identities, rule-source updater/signature validation, authentication, rate limiting, IPv6 bind configuration, or full standards-level cache behavior. Add these deliberately as learning phases rather than treating the starter as a production firewall.
