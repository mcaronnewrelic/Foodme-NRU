# Security

What FoodMe does to protect secrets and customers, which checks exist, and what the source review of 2026-06-02 found. This page replaces three earlier documents (the security guide, the compliance report and the source review), which were merged here.

Status of every finding was checked against the code on 2026-10-31. Line numbers in the findings are from the review date and have moved.

## Where things stand

The backend's data layer is solid in one important respect: every PostgreSQL query in `server/database.js` uses parameterized queries (`$1`, `$2`...), so there is no SQL injection. Angular templates auto-escape output and the frontend contains no `innerHTML`, `bypassSecurityTrust*`, or `eval` sinks, so reflected/stored XSS risk is low.

The serious problems are about who can call the API and what it leaves running. There is no authentication or authorization anywhere, customer PII is freely enumerable, and several deliberately abusive "simulation" endpoints are wired into the production app. There is also a hardcoded database password in committed source.

| # | Severity | Issue | Status |
|---|----------|-------|--------|
| 1 | Critical | No authentication or authorization on any endpoint; customer PII enumerable | Open |
| 2 | High | DoS / availability endpoints exposed (`/simulate/*`) | Open. Kept on purpose: the New Relic exercises use them. Do not expose them on an internet-facing deployment. |
| 3 | High | Hardcoded database password in `server/database.js` and `db/scripts/test-database.js` | Open |
| 4 | High | Order totals trust client-supplied prices | Open |
| 5 | Medium | TLS certificate verification disabled for the database | Open |
| 6 | Medium | Sensitive PII and request bodies written to logs | Open |
| 7 | Medium | Verbose error disclosure | Partly fixed (handler now runs; stack still sent in development) |
| 8 | Medium | No `helmet`, CORS policy, rate limiting or body-size limits | Open |
| 9 | Medium | Mass assignment from `req.body` onto records | Open |
| 10 | Low | New Relic keys stored in plaintext in the local `.env` | Open |
| 11 | Low | Customer PII persisted in `localStorage` | Open |

The local `.env` is gitignored and not tracked, so its keys are not in the repository. Finding 10 is about the keys being live and on disk in cleartext.

## Practices in place

### Secrets
- Sensitive configuration comes from environment variables: `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_API_KEY`, `DB_PASSWORD` and others. `.env.example` is the template; `.env` and `.env.local` are not committed.
- The New Relic license key is read from `process.env` in `server/newrelic.js`, and the agent's attribute settings exclude cookie, authorization and `x*` headers.
- See [Secret Management](setup/SECRET_MANAGEMENT.md) for how to handle keys and passwords, and [Environment Variables](setup/ENVIRONMENT_VARIABLES.md) for the list.

### Files kept out of git and images
- `.gitignore` excludes `.env`, `.env.local` and `newrelic_agent.log`.
- `docker/.dockerignore` keeps `.env` files and logs out of the Docker build context.

### Containers
- The production Dockerfiles (`docker/Dockerfile`, `docker/Dockerfile.arm64`) are multi-stage builds on `node:22-alpine` and run as the non-root user `node`. The simple development image runs as `nextjs`.
- There are no `ARG` or `ENV` instructions carrying secrets. An earlier version had `ARG` lines for the New Relic keys, which expose secrets in the build cache and image layers. They were removed, and secrets reach containers only at runtime, through `env_file` in the compose files or `--env-file`.
- Never pass secrets as build arguments.

### Dependencies and logging
- Production dependencies are separate from development ones. Dependabot is configured in `.github/dependabot.yml`. Run `npm audit` for known vulnerabilities; the review itself did not include a dependency scan.
- Logging uses Pino. The New Relic agent log is excluded from git.

## Checks you can run

| Check | Command |
|---|---|
| Secret scan of Dockerfiles, scripts, compose files and source | `npm run security:validate` (runs `scripts/validate-security.sh`) |
| Dockerfile linting with Hadolint | `npm run security:docker` (lints `docker/Dockerfile`; rules are in `.hadolint.yaml`) |
| Known-vulnerable dependencies | `npm audit`, in `server/` and in `angular-app/` |

The validation script looks for `ARG` and `ENV` instructions with secrets in `docker/Dockerfile*`, `--build-arg` with secrets in shell scripts, build args in `docker/docker-compose*.yml`, hardcoded keys in `.js` and `.ts` source, and `.env` missing from `.gitignore` or `docker/.dockerignore`. It exits with an error if it finds anything. The review itself did not include a dependency scan, so run `npm audit` too.

## If a secret is exposed

1. Rotate the affected credential immediately.
2. Update the value wherever the app runs (`.env`, the deployment's secret store, repository secrets).
3. Recreate the containers or redeploy so they read the new value. A container reads `.env` only when it is created.
4. Review logs for data exposure.
5. Run the checks above.

## Source review, 2026-06-02

**Scope:** whole application: Angular frontend (`angular-app/`), Node/Express backend (`server/`), plus supporting Docker, nginx and config. Static review of source only; no live exploitation and no dependency CVE scan (network-restricted environment).
**Method:** manual source review focused on the OWASP Top 10: access control, injection, secrets, data exposure, security misconfiguration and DoS.

## Findings

### 1. No authentication or authorization (Critical)

Every route is open to anyone who can reach the server. There is no login, session, token check, or ownership check on any endpoint. The most damaging consequences:

- `GET /api/orders/customer/:email` (`index.js:895`) and `GET /api/orders/customer/phone/:phone` (`index.js:965`) return a customer's full order history, including name, delivery address, phone, and email, to anyone who supplies an email or phone string. This is direct PII disclosure and allows enumeration.
- `GET /api/orders/:id` (`index.js:1035`) returns an order by ID, including its `delivery_address`, items, and totals. Order IDs are sequential database integers, so an attacker can walk `1, 2, 3...` and harvest every order and delivery address (Insecure Direct Object Reference). (Note: `database.js` defines `getOrderById` twice; the second, effective definition does not join customer email/phone, but `delivery_address` is still returned. The first, shadowed definition does join full customer PII, so this is one refactor away from being worse.)
- `POST/PUT/DELETE /api/restaurant[/:id]` (`index.js:501,840,872`) let any caller create, modify, or soft-delete restaurant records.

This is OWASP A01:2021 (Broken Access Control), the highest-impact issue in the app.

**Suggested fix:** Put authentication in front of the API and an ownership check on order lookups. Minimum viable approach:

```js
// auth.js
const jwt = require('jsonwebtoken'); // add as dependency

function requireAuth(req, res, next) {
  const header = req.get('Authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Authentication required' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET); // { email, ... }
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Only let a customer read their own orders
function requireSelf(getEmail) {
  return (req, res, next) =>
    getEmail(req).toLowerCase() === (req.user.email || '').toLowerCase()
      ? next()
      : res.status(403).json({ error: 'Forbidden' });
}

module.exports = { requireAuth, requireSelf };
```

```js
// index.js
const { requireAuth, requireSelf } = require('./auth');

app.get('/api/orders/customer/:email',
  requireAuth,
  requireSelf(req => req.params.email),
  async (req, res) => { /* ...existing... */ });

// Restrict write operations to an admin role
app.post(API_URL,   requireAuth, requireAdmin, /* ...existing... */);
app.put(API_URL_ID, requireAuth, requireAdmin, /* ...existing... */);
app.delete(API_URL_ID, requireAuth, requireAdmin, /* ...existing... */);
```

For order-by-id, verify the order belongs to `req.user` after fetching it, returning 404 (not 403) to avoid confirming existence.

### 2. Availability / DoS endpoints exposed in production (High)

A block of "simulation" endpoints is registered unconditionally and is reachable through the nginx catch-all proxy:

- `GET /simulate/cpu-hog?iterations=` (`index.js:272`) runs a busy loop for a **client-controlled, uncapped** iteration count. `?iterations=100000000000` blocks the event loop and starves all other requests.
- `GET /simulate/memory-leak` (`index.js:315`) appends ~100 MB-equivalent of objects to a module-level array on every hit, with no cap; repeated calls exhaust memory (OOM).
- `GET /simulate/slow-response?delay=` (`index.js:334`) holds a connection open for a client-controlled delay.
- `GET /simulate/uncaught-exception` (`index.js:366`) deliberately throws an uncaught exception.

Any unauthenticated user can degrade or crash the service.

**Suggested fix:** Do not ship these to production. Gate the entire block behind an explicit, non-production flag:

```js
if (process.env.ENABLE_SIMULATION === 'true' && process.env.NODE_ENV !== 'production') {
  app.get('/simulate/cpu-hog', /* ... */);
  // ...all other /simulate/* routes...
}
```

If they must exist for load-testing, also cap the inputs (`Math.min(parseInt(req.query.iterations) || 1e6, 1e7)`) and require auth.

### 3. Hardcoded database password in source (High)

`server/database.js:49` falls back to a literal password:

```js
if (!dbPassword) {
  dbPassword = 'foodme_secure_password_2025!';
}
```

The same literal appears in `db/scripts/test-database.js:16`. These are committed to the repository. Anyone with repo access (or anyone who finds the repo) learns a credential that is likely reused across environments.

**Suggested fix:** Remove the fallback and fail closed:

```js
if (!dbPassword) {
  throw new Error('DB_PASSWORD is not configured');
}
```

Rotate the password if `foodme_secure_password_2025!` was ever used in a real environment, and remove the literal from `test-database.js`.

### 4. Order totals trust client-supplied prices (High)

In `POST /api/order` (`index.js:579`) the server computes the order total from prices sent by the client:

```js
order.items.forEach(function(item) {
  itemCount += item.qty;
  orderTotal += item.price * item.qty; // price comes from the request body
});
```

`database.createOrder` likewise uses `item.unit_price || item.price` and `orderData.total_amount || orderData.total || subtotal` from the request. A client can submit `price: 0` (or any value) and have the order persisted at that price. For an ordering/checkout flow this is a financial integrity flaw (price tampering / business-logic abuse).

**Suggested fix:** Never trust client prices. Look up each item's authoritative price from the database (by `menu_item_id` / restaurant + name) and compute the total server-side; reject the order if a submitted price disagrees, or simply ignore the submitted price.

### 5. TLS certificate verification disabled for DB (Medium)

`server/database.js:30` and `:58`:

```js
ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
```

When SSL is enabled, certificate validation is turned off, which defeats the point of TLS and allows a man-in-the-middle to intercept database traffic (including credentials and PII).

**Suggested fix:** Set `rejectUnauthorized: true` and provide the CA cert (`ca: fs.readFileSync(process.env.DB_CA_CERT)`), so the connection is both encrypted and authenticated.

### 6. Sensitive data written to logs (Medium)

The request logger and several handlers log PII and full payloads to stdout/`pino`:

- Request middleware logs client IP and User-Agent for every request.
- The error handler logs the full `req.body` of POST requests (`index.js`, error middleware), which for `/api/order` includes customer name, email, phone, and delivery address.
- `POST /api/order` logs `order` at debug level and customer email/name as custom attributes.

Anyone with log access (or a log-shipping pipeline) sees customer PII in cleartext, which is a privacy and compliance concern.

**Suggested fix:** Redact PII before logging. `pino` supports redaction:

```js
const logger = require('pino')({
  redact: ['req.body.deliverTo', 'req.body.customer', 'req.headers.authorization',
           '*.email', '*.phone', '*.address', 'customerEmail', 'customerPhone'],
});
```

Avoid logging full request bodies; log a minimal, non-identifying summary instead.

### 7. Verbose error disclosure (Medium) - partly fixed

The global error handler returns `err.stack` to the client when `NODE_ENV === 'development'`, and always returns an `errorId` plus timestamp. Stack traces reveal file paths, library versions, and internal structure useful to an attacker.

**Fixed 2026-10-31:** the handler was registered before the route handlers, so it never ran for errors thrown by routes. It is now the last middleware in `server/index.js`, and route errors reach it.

**Still open:** the stack trace is returned in development mode. Log it server-side and return only `{ status: 'error', errorId }`.

### 8. Missing security middleware (Medium)

The Express app uses no `helmet` (so no `Content-Security-Policy` or other hardening headers at the app layer), no CORS policy, no rate limiting, and relies on default body-parser limits. While the production nginx config does add `X-Frame-Options`, `X-Content-Type-Options`, `X-XSS-Protection`, and HSTS, there is no CSP anywhere, and rate limiting in particular would blunt findings 1, 2, and 4.

**Suggested fix:**

```js
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

app.use(helmet());                                  // adds CSP + hardening headers
app.use(express.json({ limit: '100kb' }));          // cap body size
app.use('/api/', rateLimit({ windowMs: 60_000, max: 100 }));
```

Add an explicit CORS allowlist if the API is consumed cross-origin.

### 9. Mass assignment from request body (Medium)

`Restaurant.prototype.update` (`server/model.js`) copies every key of the incoming object onto the record:

```js
Object.keys(data).forEach(function(key) { this[key] = data[key]; }, this);
```

`PUT /api/restaurant/:id` passes `req.body` straight into `update`, and `addRestaurant` reads arbitrary fields. A client can set unexpected properties (e.g. `is_active`, `id`, or inject fields the model later trusts).

**Suggested fix:** Whitelist allowed fields explicitly before assigning, both in `model.js` and in the DB insert/update paths.

### 10. New Relic keys in plaintext local `.env` (Low)

The on-disk `.env` contains a real-looking `NEW_RELIC_LICENSE_KEY`, `NRIA_LICENSE_KEY`, and a `NEW_RELIC_API_KEY` (`NRAK-...`, a user API key). The file is gitignored and not committed, so this is not a repo leak, but the keys are live secrets stored in cleartext. A user API key can modify New Relic account data.

**Suggested fix:** Treat these as secrets: load from a secrets manager or the deployment platform's secret store rather than a cleartext file, and rotate the `NRAK-` key if it has been shared.

### 11. Customer PII in localStorage (Low)

`customer.service.ts` persists the full customer object (name, email, phone, address) to `localStorage` under `foodme-customer`. `localStorage` is readable by any JavaScript on the origin, so any future XSS or malicious third-party script would exfiltrate it. Given Angular's escaping the XSS risk is currently low, hence Low severity.

**Suggested fix:** Store only what is needed, prefer in-memory state for sensitive fields, and consider clearing on logout/session end (the service already exposes `clearCustomer`).

---

## What looked good

- All database access uses parameterized queries; no string-concatenated SQL.
- No dangerous client-side sinks (`innerHTML`, `bypassSecurityTrust*`, `eval`); Angular auto-escaping is intact.
- Docker images run as a non-root `USER` (`node`/`nextjs`) and docker-compose reads `POSTGRES_PASSWORD` from an env variable rather than hardcoding it.
- nginx restricts `/nginx_status` with `allow`/`deny` and sets several response security headers; TLS config uses TLS 1.2/1.3 with `HIGH:!aNULL:!MD5`.
- `.env` and `db/password.txt` are correctly gitignored.

## Recommended priority

1. Add authentication + per-user authorization (Finding 1) and rate limiting (Finding 8).
2. Remove/guard the `/simulate/*` endpoints (Finding 2).
3. Remove the hardcoded DB password and rotate it (Finding 3).
4. Stop trusting client prices in checkout (Finding 4).
5. Then work through findings 5-11.

*This review is based on static source analysis and does not include a runtime/dependency-CVE scan. Run `npm audit` (and ideally Dependabot/Trivy) in a networked environment to cover known-vulnerable dependencies.*
