import { CheckKind } from '../components/nr-check/nr-check';

/**
 * Investigations (spec section 11): longer, question-gated cases beyond
 * the five missions. Same contract as browser.nru.to's originals: 6
 * checkpoints, one question each; a correct answer reveals the next
 * step; answers are recorded as OrderupQuizAnswer with
 * missionId = 'inv-<slug>' (the check component does the recording -
 * it takes the missionId as an input like any mission check).
 *
 * Fault investigations are armed by the instructor and report
 * live: 'armed'; I3 is structural (the fan-out is a property of the
 * code), so it is always live.
 */
export interface InvestigationCheckpoint {
  questionId: string;
  title: string;
  /** What to do, in order. Plain text; blank line = new paragraph. */
  prompt: string;
  /** Evidence query for the callout, when the checkpoint has one. */
  nrql?: string;
  learn?: string;
  kind: CheckKind;
  question: string;
  options?: string[];
  answer: string | string[] | number;
  tolerance?: number;
  proves?: string;
  /** Shown once the checkpoint is solved: the interpretation. */
  reveal: string;
}

export interface InvestigationDef {
  slug: string;
  title: string;
  summary: string;
  live: 'always' | 'armed';
  liveNote: string;
  caseClosed: string;
  checkpoints: InvestigationCheckpoint[];
}

export function investigationMissionId(slug: string): string {
  return `inv-${slug}`;
}

export const INVESTIGATIONS: InvestigationDef[] = [
  {
    slug: 'its-not-checkout',
    title: "It's not checkout",
    summary:
      'Checkout has gone slow — placing an order takes seconds, and the ' +
      'obvious suspect is the checkout code. Prove where the time ' +
      'actually sits before anyone rewrites anything.',
    live: 'armed',
    liveNote: 'Armed by your instructor — when it is live, the banner at the top names it and the checkpoints open.',
    caseClosed:
      'The checkout code was innocent: the order spent its time waiting ' +
      'inside a single database call, and the app around it was idle. ' +
      'That distinction — waiting vs working — is the first fork in ' +
      'almost every slowness investigation, and the trace answers it ' +
      'before any code is read. (In this demo the slow query is a ' +
      'stand-in your instructor armed; the reading skill is identical ' +
      'when the culprit is a real query plan.) Real-world next steps: ' +
      'take the guilty query to the database — its plan (I8\u2019s missing ' +
      'index), its locks (I7), its load — and alert on datastore time ' +
      'share, not just endpoint duration, so the next one pages the ' +
      'right suspect.',
    checkpoints: [
      {
        questionId: 'slow-transaction',
        title: 'Find the slow transaction',
        prompt:
          'Place an order (any cart, your sample customer) and feel the ' +
          'wait on the Thank You page. Then find it in the data: the ' +
          'query ranks every transaction by its average duration over ' +
          'the last half hour.',
        nrql:
          "SELECT average(duration) AS 'Avg seconds', count(*) AS 'Calls' FROM Transaction WHERE appName = 'OrderUp' FACET name SINCE 30 minutes ago LIMIT 10",
        learn:
          'Start every slowness case by ranking, not guessing: average ' +
          'duration per transaction name separates the one sick route ' +
          'from the healthy rest.',
        kind: 'choice',
        question: 'Which transaction is carrying the slowness?',
        options: [
          'POST /api/order',
          'GET /api/restaurant/by-name (the menu)',
          'GET /api/orders (the lookup)',
          'All of them, about equally',
        ],
        answer: 'POST /api/order',
        proves: 'One route is sick; the rest of the app is healthy.',
        reveal:
          'Only the order route is slow. Menus, lists and lookups answer ' +
          'in their usual milliseconds from the same app and the same ' +
          'database — so "the site is slow" is already wrong. It is ' +
          'checkout-shaped. Onward, carefully.',
      },
      {
        questionId: 'time-location',
        title: 'Open the trace: where does the time sit?',
        prompt:
          'Open APM → Transactions → POST /api/order → a recent trace ' +
          '(pick your own via its requestId if you can). Look at the ' +
          'waterfall: each span is a piece of work, and the widths are ' +
          'time.',
        kind: 'choice',
        question: 'Where does nearly all of the trace\u2019s time sit?',
        options: [
          'In the application code, spread across many small spans',
          'In a single datastore (Postgres) span',
          'In the browser, before the request reaches the server',
          'Evenly — no span stands out',
        ],
        answer: 'In a single datastore (Postgres) span',
        proves: 'The app is waiting on the database, not working.',
        reveal:
          'One wide datastore span, and the code around it finishing in ' +
          'milliseconds. The handler is not slow — it is parked, ' +
          'waiting for Postgres to answer. Every minute spent reading ' +
          'checkout code would have been wasted.',
      },
      {
        questionId: 'span-share',
        title: 'Measure the share',
        prompt:
          'Put a number on "nearly all": in that same trace, compare ' +
          'the big datastore span\u2019s duration with the whole ' +
          'transaction\u2019s duration, as a percentage.',
        kind: 'number',
        question: 'About what share of the transaction\u2019s time is that one datastore span? (%)',
        answer: 90,
        tolerance: 10,
        proves: 'Measured, not eyeballed: the database call IS the transaction.',
        reveal:
          'Roughly nine-tenths or more. When one span is ~90% of a ' +
          'transaction, optimizing anything else is decoration — the ' +
          'whole incident lives inside that one call.',
      },
      {
        questionId: 'guilty-query',
        title: 'Read the guilty query',
        prompt:
          'Click into that datastore span and read its statement — the ' +
          'actual SQL the span ran.',
        kind: 'choice',
        question: 'What is the slow span doing?',
        options: [
          'Inserting the order row (INSERT INTO orders)',
          'Looking up menu items by name (SELECT FROM menu_items)',
          'Sleeping — a pg_sleep stand-in for a slow query',
          'Updating the order status (UPDATE orders)',
        ],
        answer: 'Sleeping — a pg_sleep stand-in for a slow query',
        proves: 'You read the culprit\u2019s name off the span, not off a guess.',
        reveal:
          'Honest mechanics: in this demo the slow query is a pg_sleep ' +
          'your instructor armed — a stand-in. In production this same ' +
          'span would hold a real statement: an unindexed scan, a ' +
          'lock wait, a plan gone wrong (I7 and I8 are exactly those ' +
          'cases). The skill you just used — find the span, read its ' +
          'statement — does not change.',
      },
      {
        questionId: 'not-the-app',
        title: 'Clear the suspect',
        prompt:
          'Someone in the room has already said "the checkout code is ' +
          'slow, rewrite it." Using only what the trace showed, close ' +
          'that theory.',
        kind: 'choice',
        question: 'Why is "the checkout code is slow" the wrong conclusion?',
        options: [
          'The code\u2019s own spans are milliseconds; the time is spent waiting inside one database call',
          'Checkout code can never be slow',
          'The browser agent inflates checkout timings',
          'Slow orders are normal for a food app',
        ],
        answer: 'The code\u2019s own spans are milliseconds; the time is spent waiting inside one database call',
        proves: 'Waiting vs working — the fork this whole case turns on.',
        reveal:
          'Exactly. Duration is not effort: a transaction can be 3 ' +
          'seconds long while its code runs for 30 milliseconds. ' +
          'Rewriting the handler would have shipped a refactor and ' +
          'kept the incident.',
      },
      {
        questionId: 'verdict',
        title: 'The verdict',
        prompt: 'Close the case: name the culprit and the first move.',
        kind: 'choice',
        question: 'What is the verdict, and where does the fix start?',
        options: [
          'The checkout handler — rewrite it in a faster style',
          'The database call inside checkout — take that query to the database (plan, locks, load) before touching app code',
          'The network — the data center is far away',
          'New Relic — the agent is adding the delay',
        ],
        answer: 'The database call inside checkout — take that query to the database (plan, locks, load) before touching app code',
        proves: 'Case ready to close.',
        reveal: 'Verdict recorded. The summary below is the whole case in one paragraph.',
      },
    ],
  },
  {
    slug: 'the-502-didnt-come-from-the-app',
    title: "The 502 didn't come from the app",
    summary:
      'Restaurant and menu pages have started failing about half the ' +
      'time with 502 Bad Gateway. The app insists nothing is wrong — ' +
      'and for once, the app is telling the truth. Work out which ' +
      'layer is actually talking.',
    live: 'armed',
    liveNote: 'Armed by your instructor — when it is live, the banner at the top names it and the checkpoints open.',
    caseClosed:
      'The 502s were minted by nginx, the proxy in front of the app, ' +
      'when its upstream died mid-answer — the app never produced an ' +
      'error because, from its side, those requests simply vanished. ' +
      'Read an error\u2019s layer before its message: the same 502 from ' +
      'a refusal would mean the upstream is down, from a timeout a 504 ' +
      'and a slow upstream, and only the proxy\u2019s own error log ' +
      'says which. (Here the dying upstream is a stand-in your ' +
      'instructor armed — the app destroys the sockets itself — but ' +
      'the 502s, the log lines and the APM silence are genuinely ' +
      'nginx\u2019s.) Two production notes: this site\u2019s real config ' +
      'sets proxy_read_timeout to 86400s on /api/, so a hanging ' +
      'upstream would never produce even this signal — it would just ' +
      'hang; and the load balancer in front passes the proxy\u2019s ' +
      '502 through, which is why the source split matters. Real-world ' +
      'next steps: alert on the proxy\u2019s 5xx rate, give upstreams ' +
      'health checks and sane timeouts, and start proxy incidents in ' +
      'the proxy\u2019s error log — not the app\u2019s dashboards.',
    checkpoints: [
      {
        questionId: 'status-received',
        title: 'Name what visitors receive',
        prompt:
          'Browse the Restaurants page and open a menu or two, ' +
          'refreshing as needed. About half the loads fail. Before ' +
          'theorizing, pin down exactly what a failed load returns — ' +
          'the browser\u2019s network tab shows it, and the query lists ' +
          'what the proxy\u2019s access log recorded for the same ' +
          'requests.',
        nrql:
          "SELECT count(*) FROM Log WHERE logtype = 'nginx-access' AND uri LIKE '%/api/restaurant%' FACET status SINCE 30 minutes ago",
        learn:
          'A reverse proxy answers on the app\u2019s behalf when the app ' +
          'can\u2019t. The status code it chooses is the first clue ' +
          'about which side of the proxy the trouble lives on. (This ' +
          'access log is JSON, so status is a field you can FACET — ' +
          'no text parsing.)',
        kind: 'choice',
        question: 'What does a failed page load actually receive?',
        options: [
          '502 Bad Gateway, generated by the proxy',
          '500 with an application stack trace',
          'The app\u2019s own error page, rendered normally',
          'A 404 — the pages are gone',
        ],
        answer: '502 Bad Gateway, generated by the proxy',
        proves: 'The failure wears the proxy\u2019s uniform, not the app\u2019s.',
        reveal:
          '502 Bad Gateway — a status the application never sends for ' +
          'these pages. Something between the visitor and the app is ' +
          'answering on the app\u2019s behalf. Hold that thought and ' +
          'check the suspect everyone blames first.',
      },
      {
        questionId: 'apm-silence',
        title: 'Interrogate the usual suspect',
        prompt:
          'Open APM for the same window. If the app were failing half ' +
          'its page loads, its error data would be lit up. The query ' +
          'facets every error transaction in the account by name — ' +
          'look for anything corresponding to the failing restaurant ' +
          'and menu loads.',
        nrql:
          "SELECT count(*) FROM TransactionError WHERE appName = 'OrderUp' SINCE 30 minutes ago FACET transactionName LIMIT 10",
        learn:
          'Absence is evidence. An instrumented app that fails records ' +
          'the failure; when the errors aren\u2019t there, the fault ' +
          'isn\u2019t either.',
        kind: 'choice',
        question: 'What does APM show for the failing page loads?',
        options: [
          'Matching 500 errors on the restaurant transactions',
          'Nothing — no error transactions correspond to them',
          'The errors, filed under a different service',
          'APM stopped reporting altogether',
        ],
        answer: 'Nothing — no error transactions correspond to them',
        proves: 'The app never got to fail: from its side, those requests simply never completed.',
        reveal:
          'Silence. The app answered every request it actually ' +
          'processed, and recorded no errors for the failures — ' +
          'because the failing requests died before the app could ' +
          'respond to them. The crime scene is not in the app. It\u2019s ' +
          'in the layer in front of it, whose own logs you haven\u2019t ' +
          'opened yet.',
      },
      {
        questionId: 'error-phrase',
        title: 'Read the proxy\u2019s error log',
        prompt:
          'nginx keeps an error log, and it is forwarded like the ' +
          'others. The query ranks the actual upstream error lines ' +
          'from the last half hour — read the majority line carefully; ' +
          'nginx phrases are precise, and each one is a different ' +
          'disease.',
        nrql:
          "SELECT count(*) FROM Log WHERE logtype = 'nginx-error' AND message LIKE '%upstream%' SINCE 30 minutes ago FACET message LIMIT 5",
        learn:
          'The classic phrases: "upstream timed out" = too slow to ' +
          'answer (a 504). "connect() failed" = couldn\u2019t reach it ' +
          'at all. "prematurely closed connection" = it died ' +
          'mid-answer. Same neighborhood, three different incidents.',
        kind: 'choice',
        question: 'What does the majority of the error log say?',
        options: [
          'upstream prematurely closed connection',
          'upstream timed out while reading response header',
          'connect() failed (111: Connection refused)',
          'no live upstreams while connecting to upstream',
        ],
        answer: 'upstream prematurely closed connection',
        proves: 'The upstream starts answering and dies mid-sentence.',
        reveal:
          '"Upstream prematurely closed connection while reading ' +
          'response header" — the app side of the connection begins ' +
          'responding and then vanishes, so nginx, left holding an ' +
          'empty socket, returns 502 to the visitor. Not down ' +
          '(that\u2019s a refusal), not slow (that\u2019s a timeout): ' +
          'dying mid-answer.',
      },
      {
        questionId: 'share-502',
        title: 'Measure the blast radius',
        prompt:
          'Back in the access log: of all the /api/restaurant ' +
          'requests in the window, what share came back 502? The ' +
          'query computes the percentage.',
        nrql:
          "SELECT percentage(count(*), WHERE status = 502) AS '% 502' FROM Log WHERE logtype = 'nginx-access' AND uri LIKE '/api/restaurant%' SINCE 30 minutes ago",
        learn:
          'Intermittency is a quantity, not a vibe: a percentage ' +
          'distinguishes "every request" from "every other request" ' +
          'from "one in a thousand", and each points at a different ' +
          'mechanism.',
        kind: 'number',
        question: 'About what percentage of those requests returned 502? (%)',
        answer: 50,
        tolerance: 12,
        proves: 'Every other request — a pattern, not random breakage.',
        reveal:
          'Roughly half. Clean alternation like that is a signature: ' +
          'something is failing on a rhythm — one backend of two, ' +
          'every other connection, a process dying on a schedule — ' +
          'not random load. (In this demo the rhythm is deliberate; ' +
          'the measuring is the skill.)',
      },
      {
        questionId: 'which-layer',
        title: 'Rule out the middleman\u2019s health',
        prompt:
          'One suspect remains between the ALB and the app: nginx ' +
          'itself. Its own integration reports it healthy — accepting ' +
          'connections, serving the requests it can pass on. Weigh ' +
          'everything: app silent, proxy logging upstream deaths, ' +
          'proxy itself healthy.',
        nrql:
          "SELECT average(connectionsActive) AS 'Active connections' FROM NginxSample SINCE 30 minutes ago",
        learn:
          'Each layer testifies about the others: the proxy\u2019s ' +
          'metrics clear the proxy, its error log indicts the ' +
          'upstream, and the app\u2019s silence corroborates both.',
        kind: 'choice',
        question: 'Which layer produced the 502s?',
        options: [
          'The app, throwing errors it forgot to log',
          'nginx, reporting that its upstream died mid-answer',
          'The visitors\u2019 browsers, timing out',
          'New Relic, dropping the error data',
        ],
        answer: 'nginx, reporting that its upstream died mid-answer',
        proves: 'Three sources, one story.',
        reveal:
          'nginx minted them — faithfully reporting that the thing ' +
          'behind it kept dying mid-answer. nginx is the witness, not ' +
          'the culprit; the culprit is whatever makes the upstream ' +
          'unstable, and that hunt starts from the phrase in its log.',
      },
      {
        questionId: 'verdict',
        title: 'The verdict',
        prompt: 'Close the case: the culprit, and the first move.',
        kind: 'choice',
        question: 'What is the verdict, and where does the fix start?',
        options: [
          'The app — add error logging until the failures show up in APM',
          'The upstream\u2019s stability — and monitor the proxy\u2019s 5xx rate and error log, where this class of failure is actually visible',
          'nginx — remove the proxy so errors come straight from the app',
          'The visitors — ask them to refresh less',
        ],
        answer: 'The upstream\u2019s stability — and monitor the proxy\u2019s 5xx rate and error log, where this class of failure is actually visible',
        proves: 'Case ready to close.',
        reveal: 'Verdict recorded. The summary below is the whole case in one paragraph.',
      },
    ],
  },
  {
    slug: 'one-connection-for-the-whole-restaurant',
    title: 'One connection for the whole restaurant',
    summary:
      'A burst of orders has arrived — and everything has slowed down ' +
      'uniformly: orders, menus, lists. Postgres is idle, no query is ' +
      'slow, and yet nothing can get through. Find the shape of the ' +
      'bottleneck. (If this app ever gets a connection pool, this case ' +
      'goes cold — retire it rather than re-arming it.)',
    live: 'armed',
    liveNote: 'Armed by the burst script your instructor runs (scripts/burst-orders.js), which places concurrent orders as a simulated visitor, SIM-BST1. When it runs, the banner names this investigation.',
    caseClosed:
      'The bottleneck was never a query — it was a queue. Every query ' +
      'in the app funnels through a single database connection, so ' +
      'concurrency doesn\u2019t parallelize anything; it just lines up. ' +
      'Throughput capped at one-request-at-a-time while the database ' +
      'sat idle is the fingerprint: the resource being waited on ' +
      'wasn\u2019t Postgres, it was the doorway into it. Real-world ' +
      'next steps: use a connection pool with a deliberate size (and ' +
      'know why that size), put connection counts on the dashboard ' +
      'next to latency so the next queue is visible at a glance, and ' +
      'load-test before and after the change — the same burst that ' +
      'exposed this should show the ceiling lift.',
    checkpoints: [
      {
        questionId: 'symptom-shape',
        title: 'Characterize the slowdown',
        prompt:
          'While the burst runs, use the site yourself: open menus, ' +
          'browse restaurants, place an order. Then check APM: it ' +
          'isn\u2019t one route suffering.',
        nrql:
          "SELECT average(duration) AS 'Avg seconds', count(*) AS 'Calls' FROM Transaction WHERE appName = 'OrderUp' FACET name SINCE 10 minutes ago LIMIT 10",
        learn:
          'A single sick route points at code. Everything sick at once ' +
          'points at a shared resource underneath all of them.',
        kind: 'choice',
        question: 'What does the slowdown look like?',
        options: [
          'Everything is slow, roughly uniformly — menus, lists and orders alike',
          'Only placing orders is slow',
          'Only one restaurant\u2019s menu is slow',
          'Nothing is slow; the burst changed nothing',
        ],
        answer: 'Everything is slow, roughly uniformly — menus, lists and orders alike',
        proves: 'Uniform slowness = a shared resource, not a route.',
        reveal:
          'Uniform, across reads and writes that share nothing except ' +
          'the road into the database. Whatever is saturated, every ' +
          'page in the app queues behind it.',
      },
      {
        questionId: 'db-not-busy',
        title: 'Check the usual suspect\u2019s alibi',
        prompt:
          'The obvious theory is "the database is overwhelmed." Test ' +
          'it in the Postgres integration\u2019s data: host CPU, and the ' +
          'per-query durations inside the traces you\u2019ve been ' +
          'reading.',
        kind: 'choice',
        question: 'What is Postgres itself doing during the burst?',
        options: [
          'CPU pinned, queries individually slow — it is overwhelmed',
          'Mostly idle, and each query is as fast as ever — the wait is elsewhere',
          'Down — connections are being refused',
          'Restarting repeatedly',
        ],
        answer: 'Mostly idle, and each query is as fast as ever — the wait is elsewhere',
        proves: 'The database is not the bottleneck; it is barely being used.',
        reveal:
          'An idle database with slow applications is a paradox only ' +
          'until you ask how the app reaches it. The queries are fine. ' +
          'Something is rationing access to them.',
      },
      {
        questionId: 'pinned-connections',
        title: 'Count the connections',
        prompt:
          'The Postgres integration collects this app\u2019s connection ' +
          'counts (a custom query counts sessions by state). During ' +
          'the burst — with a dozen-plus orders in flight — read the ' +
          'active connection count.',
        nrql:
          "SELECT latest(active_connections) AS 'Active connections' FROM PostgresqlCustomSample SINCE 10 minutes ago",
        learn:
          'If load rises and the connection count doesn\u2019t, the ' +
          'application isn\u2019t using the database in parallel — no ' +
          'matter how concurrent the callers are.',
        kind: 'number',
        question: 'How many database connections are active at the peak of the burst?',
        answer: 1,
        tolerance: 0,
        proves: 'Exactly one: the whole restaurant really does share a single connection.',
        reveal:
          'One. Not "few" — one. Every transaction, read or write, ' +
          'takes its turn on a single connection while its caller ' +
          'waits. (If this number is ever higher, someone has given ' +
          'the app a pool — and this investigation should be retired, ' +
          'per its own summary.)',
      },
      {
        questionId: 'throughput-ceiling',
        title: 'Spot the ceiling',
        prompt:
          'Watch the order transaction\u2019s throughput and average ' +
          'duration together during the burst (APM\u2019s transaction ' +
          'page graphs both). Sixteen callers are ordering at once.',
        kind: 'choice',
        question: 'What do throughput and duration do?',
        options: [
          'Throughput climbs with the callers and duration stays flat — healthy parallelism',
          'Throughput flattens at roughly one order\u2019s pace while duration stretches — requests are effectively processed one at a time',
          'Throughput falls to zero — the app has crashed',
          'Both stay at pre-burst levels — the burst isn\u2019t reaching the app',
        ],
        answer: 'Throughput flattens at roughly one order\u2019s pace while duration stretches — requests are effectively processed one at a time',
        proves: 'Duration × throughput ≈ 1: a queue, not a workload problem.',
        reveal:
          'That is the arithmetic of a single file line: add callers ' +
          'and nobody goes faster — everybody just waits longer. The ' +
          'system\u2019s capacity is one request\u2019s service time, ' +
          'full stop.',
      },
      {
        questionId: 'the-shape',
        title: 'Name the bottleneck',
        prompt:
          'Assemble it: uniform slowness, an idle database, exactly ' +
          'one active connection, a throughput ceiling of one at a ' +
          'time. The code confirms what the data already told you — ' +
          'server/database.js constructs a single pg Client, not a ' +
          'pool, and every method queues on it.',
        kind: 'choice',
        question: 'What is the bottleneck?',
        options: [
          'One slow query that needs an index',
          'Postgres, which needs a bigger instance',
          'The shape of the connection: a single client serializing every query in the app',
          'The network between the app and the database',
        ],
        answer: 'The shape of the connection: a single client serializing every query in the app',
        proves: 'Not a slow query — a narrow door.',
        reveal:
          'A queue is not a slow query. No index, no tuning, no ' +
          'bigger database fixes a doorway that only admits one ' +
          'request at a time.',
      },
      {
        questionId: 'verdict',
        title: 'The verdict',
        prompt: 'Close the case: the fix, and how you would prove it worked.',
        kind: 'choice',
        question: 'What is the fix, and the proof?',
        options: [
          'Replace the single client with a connection pool of a deliberate size — then re-run the same burst: active connections rise above 1 and the throughput ceiling lifts',
          'Restart Postgres nightly so connections stay fresh',
          'Add an index to every table, just in case',
          'Cache the menu page and call it done',
        ],
        answer: 'Replace the single client with a connection pool of a deliberate size — then re-run the same burst: active connections rise above 1 and the throughput ceiling lifts',
        proves: 'Case ready to close.',
        reveal: 'Verdict recorded. The summary below is the whole case in one paragraph.',
      },
    ],
  },
  {
    slug: 'the-table-is-locked',
    title: 'The table is locked',
    summary:
      'Placing an order hangs — and in this app, one stuck query ' +
      'doesn\u2019t stay in its lane. Postgres is idle, no query is ' +
      'slow, and yet nothing can get a write through. Learn to tell ' +
      'blocked from blocking, and why you check before you kill.',
    live: 'armed',
    liveNote: 'Armed by your instructor: a helper transaction locks the orders table for a 15-minute window, then releases it no matter what. The banner names this investigation while it runs, and the instructor panel shows the helper\u2019s backend PID.',
    caseClosed:
      'The order wasn\u2019t slow — it was waiting, behind a lock held ' +
      'by a transaction that had opened, done its one statement, and ' +
      'never committed: idle in transaction, the most dangerous ' +
      'ordinary state in Postgres. Two lessons compound here. First, ' +
      'blocked vs blocking: the sessions you see waiting are the ' +
      'victims, not the cause; the fix targets the one session ' +
      'holding the lock, and only after you\u2019ve identified it. ' +
      'Second, the spread: because every query in this app shares ' +
      'one connection (I6\u2019s lesson), one blocked write queued the ' +
      'whole site behind it. Real-world next steps: never hold a ' +
      'transaction open across user think-time, set lock_timeout so ' +
      'waiters fail loudly instead of silently, alert on ungranted ' +
      'locks and on idle-in-transaction age — and if you must kill a ' +
      'backend, pg_terminate_backend on the blocker, after the check, ' +
      'is the whole procedure. The demo helper releases itself after ' +
      '15 minutes; production transactions have no such mercy, which ' +
      'is exactly the point.',
    checkpoints: [
      {
        questionId: 'first-symptom',
        title: 'Reproduce the hang',
        prompt:
          'Place an order — any restaurant, any items — and watch it. ' +
          'Not slow: stuck. Give it a good ten seconds before you ' +
          'conclude anything.',
        kind: 'choice',
        question: 'What happens when you place the order?',
        options: [
          'It never completes — the request just hangs',
          'It completes, but slowly (about 3 seconds)',
          'It fails immediately with a 500 error',
          'It completes at normal speed',
        ],
        answer: 'It never completes — the request just hangs',
        proves: 'Stuck is not slow: a hang is a wait, and waits have owners.',
        reveal:
          'A slow request is doing work. A hung request is waiting ' +
          'for something — and something specific always owns a wait. ' +
          'The rest of this case is finding the owner.',
      },
      {
        questionId: 'the-spread',
        title: 'Watch it spread',
        prompt:
          'Leave that order hanging and keep using the site: open the ' +
          'restaurant list, open a menu. Compare with how the site ' +
          'felt before you placed the order.',
        learn:
          'Every query in this app shares a single database ' +
          'connection (I6). One blocked query doesn\u2019t just wait — ' +
          'everything issued after it queues behind it.',
        kind: 'choice',
        question: 'What happens to the rest of the site?',
        options: [
          'Everything stalls — pages that were instant now hang too',
          'Everything else stays fast; only order placement hangs',
          'The site crashes and restarts',
          'Nothing else changes at all',
        ],
        answer: 'Everything stalls — pages that were instant now hang too',
        proves: 'The hang spread through the shared connection, not through Postgres.',
        reveal:
          'The lock blocks one statement — the order insert. But ' +
          'that statement is sitting in the app\u2019s only connection, ' +
          'so every later query lines up behind it. In a pooled app ' +
          'this incident hurts one path; in this architecture it ' +
          'hurts the whole house. Same lock, bigger blast radius.',
      },
      {
        questionId: 'wait-not-work',
        title: 'Wait, not work',
        prompt:
          'When the lock window ends (15 minutes, or your instructor ' +
          'disarms), the stuck order finally lands. Find the ' +
          'POST /api/order transaction for that moment in APM and ' +
          'look at where its time went.',
        nrql:
          "SELECT max(duration) AS 'Slowest order (s)', average(duration) AS 'Avg (s)' FROM Transaction WHERE name LIKE '%order%' SINCE 1 hour ago",
        kind: 'choice',
        question: 'Where did the order transaction\u2019s time go?',
        options: [
          'Waiting — the statement wasn\u2019t running at all; it was queued for a lock',
          'Executing SQL on the server, start to finish',
          'Network time between the app and Postgres',
          'In the checkout application code',
        ],
        answer: 'Waiting — the statement wasn\u2019t running at all; it was queued for a lock',
        proves: 'Duration without execution is the signature of a lock wait.',
        reveal:
          'Minutes of duration, microseconds of actual work. When a ' +
          'transaction\u2019s clock runs but its statements don\u2019t, ' +
          'something else holds a resource it needs — and Postgres ' +
          'keeps the receipts: the lock data.',
      },
      {
        questionId: 'ungranted-lock',
        title: 'Read the lock data',
        prompt:
          'Open the Postgres integration (its config collects lock ' +
          'metrics for this database). During the window there is a ' +
          'lock on the orders table that has been requested but not ' +
          'granted — and a session holding the conflicting lock.',
        nrql:
          "SELECT latest(locksWaiting) AS 'Waiting locks' FROM PostgresqlDatabaseSample SINCE 30 minutes ago",
        kind: 'choice',
        question: 'What does the lock data show?',
        options: [
          'An ungranted lock: a session waiting on the orders table, and another session holding the lock that blocks it',
          'Hundreds of granted locks, all healthy',
          'No lock activity at all',
          'A deadlock between two order transactions',
        ],
        answer: 'An ungranted lock: a session waiting on the orders table, and another session holding the lock that blocks it',
        proves: 'Blocked and blocking are two different sessions — the waiter is the victim.',
        reveal:
          'Two roles, and mixing them up is the classic mistake: the ' +
          'waiting session is the stuck order (the victim); the ' +
          'holding session is the cause. Interventions target the ' +
          'holder. So: what is the holder doing?',
      },
      {
        questionId: 'blocking-state',
        title: 'Interrogate the blocker',
        prompt:
          'The instructor panel names the helper\u2019s backend PID. ' +
          'Find that session in the database activity data (the ' +
          'integration\u2019s activity view, or pg_stat_activity if ' +
          'you have shell access) and read its state.',
        kind: 'choice',
        question: 'What is the blocking session doing?',
        options: [
          'Nothing — it is idle in transaction: it opened a transaction, took the lock, and never committed',
          'Actively running a long UPDATE over millions of rows',
          'Waiting on a lock of its own',
          'Running a backup',
        ],
        answer: 'Nothing — it is idle in transaction: it opened a transaction, took the lock, and never committed',
        proves: 'Idle in transaction: the lock\u2019s owner is absent, not busy.',
        reveal:
          'The most dangerous ordinary state in Postgres. The ' +
          'transaction did its work long ago; it\u2019s the uncommitted ' +
          'openness that holds the lock — a connection checked out ' +
          'and forgotten, a code path that waits for a human before ' +
          'committing. (The demo helper holds it on purpose, and ' +
          'lets go after 15 minutes no matter what.)',
      },
      {
        questionId: 'verdict',
        title: 'The verdict',
        prompt: 'Close the case: the safe intervention, and the fix that prevents the rerun.',
        kind: 'choice',
        question: 'What do you do — now, and for good?',
        options: [
          'Identify the blocker first, then end its transaction if it is safe to do so — and for good: never hold transactions open across think-time, and set lock timeouts so waiters fail loudly',
          'Kill every waiting session — there are more of them',
          'Restart Postgres immediately; locks clear on restart',
          'Add an index to the orders table',
        ],
        answer: 'Identify the blocker first, then end its transaction if it is safe to do so — and for good: never hold transactions open across think-time, and set lock timeouts so waiters fail loudly',
        proves: 'Case ready to close.',
        reveal: 'Verdict recorded. The summary below is the whole case in one paragraph.',
      },
    ],
  },
  {
    slug: 'the-slow-lookup',
    title: 'The slow lookup',
    summary:
      'The Orders lookup — type a phone number, get your orders — ' +
      'has been getting slower for weeks. Everything else is fine. ' +
      'History grew underneath it, one ordinary day at a time. Find ' +
      'the query, prove why it\u2019s slow, fix it, and verify the fix ' +
      'in the same data that convicted it.',
    live: 'armed',
    liveNote: 'Armed by your instructor: the server seeds about 200,000 synthetic customers and their order history (clearly synthetic — 555 numbers, SEED- order numbers). Seeding takes a minute or two after the banner appears. Disarming removes the seed.',
    caseClosed:
      'Nothing was ever wrong with the lookup\u2019s code — the table ' +
      'outgrew the plan. An unindexed filter is a full table scan, ' +
      'and a scan\u2019s cost grows linearly with history: invisible ' +
      'at a hundred customers, obvious at two hundred thousand. The ' +
      'discipline this case teaches: rank queries by total time, ' +
      'not by count or by how a single run feels; read rows examined ' +
      'against rows returned — that ratio is the index\u2019s job ' +
      'description; and verify a fix in the same measurement that ' +
      'found the problem. Real-world next steps: index for the ' +
      'queries you actually run, keep an eye on top-by-total-time ' +
      'weekly, and remember the demo seeded in two minutes what ' +
      'production accumulates in two years — slowly enough that ' +
      'nobody notices until the scan crosses a threshold.',
    checkpoints: [
      {
        questionId: 'only-the-lookup',
        title: 'Isolate the symptom',
        prompt:
          'Use the site: browse menus, place an order (Mission 3 ' +
          'still works — try it), then run the Orders phone lookup ' +
          'with your sample customer\u2019s number. APM\u2019s ' +
          'transaction table shows the same split.',
        nrql:
          "SELECT average(duration) AS 'Avg seconds', count(*) AS 'Calls' FROM Transaction WHERE appName = 'OrderUp' FACET name SINCE 30 minutes ago LIMIT 10",
        kind: 'choice',
        question: 'Which part of the site is slow?',
        options: [
          'Only the Orders phone lookup — menus, ordering, everything else are normal',
          'Everything, roughly uniformly',
          'Only placing orders',
          'Only the restaurant list',
        ],
        answer: 'Only the Orders phone lookup — menus, ordering, everything else are normal',
        proves: 'One slow path, healthy database: a query problem, not a system problem.',
        reveal:
          'The mirror image of I6 and I7: not a shared resource, not ' +
          'a lock — one feature, limping on its own. The suspect ' +
          'list narrows to the queries that feature runs.',
      },
      {
        questionId: 'top-by-total-time',
        title: 'Rank by total time',
        prompt:
          'The Postgres query-performance data ranks statements by ' +
          'the time they consume in total (the APM datastore view ' +
          'below tells the same story). Don\u2019t rank by call count, ' +
          'and don\u2019t rank by how one run feels — rank by total ' +
          'time and read the top entry\u2019s text.',
        nrql:
          "SELECT sum(duration) AS 'Total seconds in DB' FROM Span WHERE category = 'datastore' FACET name SINCE 30 minutes ago LIMIT 10",
        kind: 'choice',
        question: 'Which query eats the most total database time?',
        options: [
          'The phone lookup — one query, run on every lookup, reading the whole customers table every time',
          'The menu item fetch',
          'The order insert',
          'No single query — dozens share it evenly',
        ],
        answer: 'The phone lookup — one query, run on every lookup, reading the whole customers table every time',
        proves: 'Top by total time = a mediocre query at high frequency, or a bad one at any frequency.',
        reveal:
          'The lookup joins orders to customers and filters on ' +
          'customers.phone. There is no index on that column — the ' +
          'schema indexes orders.customer_id carefully and never ' +
          'gave the lookup\u2019s own filter a thought. So every ' +
          'lookup reads every customer who ever ordered.',
      },
      {
        questionId: 'rows-examined',
        title: 'Count the waste',
        prompt:
          'The query-performance data (and any EXPLAIN) reports rows ' +
          'examined alongside rows returned. One lookup, for one ' +
          'customer\u2019s handful of orders: how many customer rows ' +
          'does Postgres have to read to answer it?',
        learn:
          'Rows examined vs rows returned is the most honest ratio ' +
          'in database work. Near 1:1, an index is doing its job. ' +
          'Thousands to one, you are paying for a scan.',
        kind: 'number',
        question: 'Roughly how many customer rows does one phone lookup examine?',
        answer: 200000,
        tolerance: 60000,
        proves: 'The whole table, every time — the scan is the symptom.',
        reveal:
          'About two hundred thousand rows examined to return one ' +
          'customer\u2019s orders. That\u2019s the seeded history — ' +
          'and in production it\u2019s simply what two years of ' +
          'signups looks like. The query didn\u2019t change; the ' +
          'table did.',
      },
      {
        questionId: 'why-now',
        title: 'Why now?',
        prompt:
          'This lookup was fast when the site launched. Nobody ' +
          'deployed anything to it. The database-size data in the ' +
          'Postgres integration and the panel\u2019s seeded count ' +
          'tell the story.',
        nrql:
          "SELECT latest(database_size) AS 'Database size (bytes)' FROM PostgresqlCustomSample SINCE 30 minutes ago",
        kind: 'choice',
        question: 'Why did the lookup get slow?',
        options: [
          'The customers table grew — and an unindexed scan costs in proportion to the table, so the lookup slowed a little every day',
          'A deploy changed the lookup query recently',
          'Postgres just needs a restart',
          'The network between the app and the database got slower',
        ],
        answer: 'The customers table grew — and an unindexed scan costs in proportion to the table, so the lookup slowed a little every day',
        proves: 'Growth is a change, even when no deploy is.',
        reveal:
          'No change event, no culprit deploy — just arithmetic. ' +
          'This is why "it was fine last quarter" is evidence of ' +
          'nothing: scans degrade on a slope, and the slope only ' +
          'announces itself when it crosses what a user can feel.',
      },
      {
        questionId: 'the-fix',
        title: 'Name the fix',
        prompt:
          'One change removes the scan. When the class is ready, ' +
          'your instructor applies it from the panel above ' +
          '("Apply I8 fix") — then the next checkpoint makes them ' +
          'prove it.',
        kind: 'choice',
        question: 'What is the fix?',
        options: [
          'Create an index on customers(phone) — the column the lookup filters by',
          'Create an index on orders(created_at)',
          'VACUUM the customers table',
          'Give Postgres more memory',
        ],
        answer: 'Create an index on customers(phone) — the column the lookup filters by',
        proves: 'Index the predicate you actually filter on.',
        reveal:
          'An index on the filtered column turns "read everyone, ' +
          'keep one" into "go straight to the one." Indexes are not ' +
          'free — every write maintains them — which is why you ' +
          'index for the queries you run, not for every column you ' +
          'own.',
      },
      {
        questionId: 'verify-fix',
        title: 'Verify in the same data',
        prompt:
          'The index is in. Run the phone lookup again — then check ' +
          'the same evidence that convicted it: rows examined, and ' +
          'the lookup\u2019s duration in APM.',
        kind: 'choice',
        question: 'What does the same measurement show now?',
        options: [
          'It collapsed — the lookup reads just the matching rows instead of the whole table, and its database time falls to a fraction of what the scan cost',
          'About the same — the index changed nothing',
          'Slightly better — maybe 20% faster',
          'Worse — indexes slow down reads',
        ],
        answer: 'It collapsed — the lookup reads just the matching rows instead of the whole table, and its database time falls to a fraction of what the scan cost',
        proves: 'A fix isn\u2019t done when it\u2019s applied; it\u2019s done when the evidence moves.',
        reveal: 'Verdict recorded. The summary below is the whole case in one paragraph.',
      },
    ],
  },
  {
    slug: 'one-page-a-dozen-calls',
    title: "One page, a dozen calls — twice",
    summary:
      'A menu page displays a dozen items. An order submits a handful. ' +
      'One of those two shapes hides a fan-out that grows with whatever ' +
      'the visitor does — count the calls, then count the queries, and ' +
      'find out which layer the N+1 lives in.',
    live: 'always',
    liveNote: 'Always live — this one is a property of the code, not an armed fault.',
    caseClosed:
      'The page that displays a dozen items costs one API call and two ' +
      'queries; the single request that submits four items costs ten ' +
      'queries — and every extra item in the cart adds two more. Same ' +
      'app, opposite shapes: the read was written set-based, the write ' +
      'loops. Those looped queries all queue on this app\u2019s single ' +
      'database connection, which is its own investigation (I6, ' +
      '\u201cOne connection for the whole restaurant\u201d). Real-world next ' +
      'steps: return item ids with the menu and send them back at order ' +
      'time (the endpoint already accepts them), batch what remains, ' +
      'and watch datastore-span counts per transaction — a span count ' +
      'that grows with input size is the N+1 smell, visible in the data ' +
      'before users ever feel it.',
    checkpoints: [
      {
        questionId: 'menu-api-calls',
        title: 'Count the calls behind one page',
        prompt:
          'Start from the Restaurants page and open any restaurant\u2019s ' +
          'menu. The page shows a dozen or so items — but look at what ' +
          'your browser actually fetched to build it.\n\n' +
          'Run the query: it lists every API request your session made ' +
          'from the menu page, grouped by URL.',
        nrql:
          "SELECT count(*) FROM AjaxRequest WHERE demoCode = '<code>' AND pageUrl LIKE '%/menu/%' SINCE 30 minutes ago FACET requestUrl LIMIT 20",
        learn:
          'One page view can fan out into many requests. FACET requestUrl ' +
          'turns "the page felt heavy" into a list you can count.',
        kind: 'choice',
        question: 'How many API calls fetched the restaurant and its menu for that page?',
        options: ['1', '2', '4', 'One per menu item'],
        answer: '1',
        proves: 'One request carried the whole page.',
        reveal:
          'One call: GET /api/restaurant/by-name/<slug>. The name, the ' +
          'details and every menu item arrived in that single response. ' +
          'Remember the shape: one page, one call.',
      },
      {
        questionId: 'menu-db-queries',
        title: 'Count the queries behind the call',
        prompt:
          'Now the server side of that same call. In New Relic, open ' +
          'APM → Transactions → the GET /api/restaurant/by-name ' +
          'transaction → one of its traces, and count the datastore ' +
          '(Postgres) spans. The query does the same count if you paste ' +
          'in the trace id from that screen.',
        nrql:
          "SELECT count(*) FROM Span WHERE traceId = 'PASTE_TRACE_ID' AND category = 'datastore' SINCE 1 hour ago",
        learn:
          'A trace breaks one request into its spans. The datastore spans ' +
          'are the database queries — counting them per transaction is ' +
          'how fan-outs show up in APM.',
        kind: 'number',
        question: 'How many database queries did that one API call run?',
        answer: 2,
        tolerance: 0,
        proves: 'A fixed two, however long the menu is.',
        reveal:
          'Two queries — one for the restaurant row, one for all of its ' +
          'menu items — whether the menu has 4 items or 40. The read ' +
          'side was written set-based: the count does not grow with the ' +
          'data it returns.',
      },
      {
        questionId: 'order-prediction',
        title: 'Predict the order',
        prompt:
          'In a moment you will place an order: ONE POST /api/order ' +
          'carrying a cart with exactly 4 items. Before you look — ' +
          'based on how the menu read behaved, what should that single ' +
          'request need?',
        kind: 'choice',
        question: 'How many database queries should one 4-item order take?',
        options: [
          'About 2 — a fixed handful, like the menu read',
          'About 5',
          'About 10',
          'It depends on the restaurant, not the cart',
        ],
        answer: 'About 2 — a fixed handful, like the menu read',
        proves: 'That is the reasonable expectation. The next checkpoint tests it.',
        reveal:
          'A fair prediction — it is exactly how the menu read behaved. ' +
          'Now test it: add exactly 4 items to your cart (any items, one ' +
          'restaurant, your sample customer from Mission 1) and place ' +
          'the order.',
      },
      {
        questionId: 'order-db-queries',
        title: 'Count the queries behind the order',
        prompt:
          'Find your order\u2019s transaction — Mission 4\u2019s trick: ' +
          'Transactions → POST /api/order, the one carrying your ' +
          'requestId — open its trace and count the datastore spans, ' +
          'or run the query with its trace id.',
        nrql:
          "SELECT count(*) FROM Span WHERE traceId = 'PASTE_TRACE_ID' AND category = 'datastore' SINCE 1 hour ago",
        learn:
          'Same counting method as checkpoint 2, different transaction. ' +
          'Comparing like with like is what makes the next number mean ' +
          'something.',
        kind: 'number',
        question: 'How many database queries did your 4-item order run?',
        answer: 10,
        tolerance: 2,
        proves: 'Roughly ten — five times the menu read, inside one request.',
        reveal:
          'Counted: 1 to find your customer, 1 to insert the order, ' +
          'and then per item — 1 to look the item up, 1 to insert it: ' +
          '2 × 4 = 8, plus the fixed 2, makes 10 (a trace may also show ' +
          'the transaction\u2019s BEGIN/COMMIT). The count grows with ' +
          'the cart. That growth is the signature of an N+1.',
      },
      {
        questionId: 'repeating-queries',
        title: 'Name the loop',
        prompt:
          'Read the statements on the spans in that same order trace. ' +
          'Two of the four query shapes below repeat once for every ' +
          'item in the cart; the other two run exactly once.',
        kind: 'multi',
        question: 'Which queries repeat once per item?',
        options: [
          'Look up the menu item by name',
          'Insert the order item row',
          'Find the customer by name',
          'Insert the order row',
        ],
        answer: ['Look up the menu item by name', 'Insert the order item row'],
        proves: 'The loop is in the order code: lookup + insert, per item.',
        reveal:
          'Exactly those two. And the lookup is the galling one: the ' +
          'server looks each item up by name because the menu response ' +
          'never included item ids — even though the order endpoint ' +
          'already accepts a menu_item_id. Half the loop exists because ' +
          'of a field that never made the trip.',
      },
      {
        questionId: 'verdict',
        title: 'The verdict',
        prompt:
          'You have counted both layers. The menu page: 1 call, 2 ' +
          'queries, fixed. The order: 1 call, ~2 queries per item, ' +
          'growing. Close the case.',
        kind: 'choice',
        question: 'Which layer has the real N+1, and what is the fix?',
        options: [
          'The menu page — it should batch its API calls',
          'The order endpoint — fetch all items in one query (or send their ids) and write the rows in one statement',
          'Neither — a query per item is normal and harmless',
          'The browser agent — it is over-reporting spans',
        ],
        answer:
          'The order endpoint — fetch all items in one query (or send their ids) and write the rows in one statement',
        proves: 'Case ready to close.',
        reveal: 'Verdict recorded. The summary below is the whole case in one paragraph.',
      },
    ],
  },
  {
    slug: 'the-kitchen-never-got-the-ticket',
    title: 'The kitchen never got the ticket',
    summary:
      'Orders are placing fine — and never moving. Pending, ' +
      'preparing, out for delivery, delivered: a background worker ' +
      'walks every order through those stages, and it has stopped ' +
      'walking. The site has not noticed. Your customers\' orders ' +
      'have. Find why a queue can be down while everything it feeds ' +
      'looks healthy.',
    live: 'armed',
    liveNote: 'Armed by your instructor: a single legacy order — imported history, order number LEGACY-0001 — is sitting in the orders table carrying a status from the pre-OrderUp system. Nothing about the website changes. Watch My Orders and the Order pipeline widgets on the Overview dashboard.',
    caseClosed:
      'One row the worker could not classify took down every ' +
      'order behind it, because the worker advanced its whole ' +
      'claimed batch in a single transaction: one throw, everyone ' +
      'rolls back. The website never noticed because the worker ' +
      'runs on its own connection and its own schedule — async ' +
      'processing fails silently by default, and the first symptom ' +
      'is a queue that quietly stops ageing. The disciplines this ' +
      'case teaches: advance items independently, so one bad item ' +
      'costs one item; skip and quarantine what you cannot classify ' +
      '(a dead-letter pile you can inspect beats a silent rollback); ' +
      'migrate legacy values at import time; and alert on queue ' +
      'age — the oldest unfinished order — not just on error rates. ' +
      'A system is not healthy because its pages load.',
    checkpoints: [
      {
        questionId: 'stuck-but-fine',
        title: 'Isolate the symptom',
        prompt:
          'Use the site: browse, and place an order. It succeeds ' +
          'instantly. Now watch it on My Orders for a minute — a ' +
          'healthy order leaves pending within the minute and is ' +
          'delivered in about three.',
        kind: 'choice',
        question: 'What is true of orders right now?',
        options: [
          'They place fine and instantly — and then never move; nothing leaves pending',
          'Placing an order errors out',
          'Orders move, just slowly — about ten minutes a stage',
          'Only orders to one restaurant are stuck',
        ],
        answer: 'They place fine and instantly — and then never move; nothing leaves pending',
        proves: 'The write path is healthy; the processing behind it is not.',
        reveal:
          'Total stall, zero user-facing errors. Whatever walks ' +
          'orders through their stages has stopped walking — and ' +
          'it is not the website, which just proved it can take ' +
          'an order perfectly well.',
      },
      {
        questionId: 'advances-per-poll',
        title: 'Read the pipeline',
        prompt:
          'The worker reports every poll as an OrderPipelineSample ' +
          'event — how many orders it advanced, and how many are ' +
          'waiting in each stage. The Order pipeline widgets on ' +
          'the Overview dashboard chart the same data. Sum what it ' +
          'has advanced in the last half hour.',
        nrql:
          "SELECT sum(advanced) AS 'Orders advanced', latest(pending) AS 'Pending now', latest(oldestUnfinishedAgeSeconds) AS 'Oldest waiting (s)' FROM OrderPipelineSample SINCE 30 minutes ago",
        kind: 'number',
        question: 'How many orders has the worker advanced in the last 30 minutes?',
        answer: 0,
        tolerance: 0,
        proves: 'Not slow — stopped. And the stop has a sharp edge in time.',
        reveal:
          'Zero. Not a trickle — a cliff. The samples keep ' +
          'arriving (the worker is alive and polling), the pending ' +
          'count keeps growing, and the advances stopped at one ' +
          'specific moment. Whatever happened, happened then.',
      },
      {
        questionId: 'worker-error',
        title: 'Ask the worker',
        prompt:
          'In APM, look past the web transactions (clean) to the ' +
          'app\u2019s background transactions: OrderStatusWorker/poll ' +
          'runs every twenty seconds. Its error rate went to 100% ' +
          'at the same moment the advances stopped.',
        nrql:
          "SELECT count(*) FROM Transaction WHERE name = 'OrderStatusWorker/poll' AND error IS true SINCE 30 minutes ago",
        kind: 'choice',
        question: 'What does the worker keep reporting?',
        options: [
          'Unknown order status: "confirmed" — it keeps meeting one row it cannot classify',
          'Connection refused — it cannot reach Postgres at all',
          'Deadlock detected — its updates keep colliding with the web tier\u2019s',
          'Query timeout — one restaurant\u2019s orders are too large to advance',
        ],
        answer: 'Unknown order status: "confirmed" — it keeps meeting one row it cannot classify',
        proves: 'The worker is not down or locked out — it is objecting to one specific row, by value.',
        reveal:
          'The error names the culprit\u2019s fingerprint: a status ' +
          'value, "confirmed", that is not one of the four the ' +
          'worker knows (pending, preparing, out_for_delivery, ' +
          'delivered). It is the status the pre-OrderUp system ' +
          'wrote — and one legacy order, LEGACY-0001, still ' +
          'carries it.',
      },
      {
        questionId: 'why-everyone',
        title: 'Why does everyone wait?',
        prompt:
          'One bad row explains one stuck order. It does not, by ' +
          'itself, explain why YOUR freshly placed order — perfect ' +
          'status, nothing wrong with it — is also frozen. The ' +
          'worker\u2019s poll, visible in its transaction traces, ' +
          'claims a batch of a few hundred unfinished orders per ' +
          'poll and advances them together.',
        kind: 'choice',
        question: 'Why does one unclassifiable order freeze every order?',
        options: [
          'The batch advances in one transaction — one throw rolls back everyone it claimed',
          'The worker processes orders strictly one per poll, and the bad one is first in line',
          'The worker and the website share one connection, and the bad order holds it',
          'The bad order is the oldest, and the worker refuses to skip ahead on principle',
        ],
        answer: 'The batch advances in one transaction — one throw rolls back everyone it claimed',
        proves: 'The failure is the batching, not the row: atomicity turned one bad item into a total stall.',
        reveal:
          'Exactly: claim a few hundred, advance them in a single ' +
          'transaction, and the legacy row aborts the lot — every ' +
          'poll, identically. The web tier never shares the pain: ' +
          'the worker runs on its own connection, which is why ' +
          'the site stayed perfect while the queue died.',
      },
      {
        questionId: 'postgres-view',
        title: 'Confirm it in Postgres',
        prompt:
          'Now the database\u2019s own account of the last half ' +
          'hour — the Postgres integration\u2019s data (its ' +
          'dashboard shows commits and rollbacks per database). ' +
          'The web tier has been committing normally the whole ' +
          'time. What have rollbacks been doing?',
        nrql:
          "SELECT sum(transactionsRolledBack) AS 'Rollbacks', sum(transactionsCommitted) AS 'Commits' FROM PostgresqlDatabaseSample SINCE 30 minutes ago TIMESERIES",
        kind: 'choice',
        question: 'What does the Postgres data show?',
        options: [
          'Rollbacks ticking up in lockstep with the polls — one doomed transaction every twenty seconds — while commits flow normally',
          'Nothing at all — the database has been idle and unreachable',
          'Commits stopped too — the whole database is wedged',
          'Connections exhausted — hundreds of sessions piled up',
        ],
        answer: 'Rollbacks ticking up in lockstep with the polls — one doomed transaction every twenty seconds — while commits flow normally',
        proves: 'The database is healthy and busy — faithfully rolling back the same doomed batch, three times a minute.',
        reveal:
          'That is the signature from the database\u2019s chair: ' +
          'not load, not locks, not an outage — a metronome of ' +
          'rollbacks keeping time with the poll interval. The ' +
          'worker asks, Postgres refuses the transaction, both ' +
          'write it down.',
      },
      {
        questionId: 'the-fix',
        title: 'The verdict',
        prompt:
          'Close the case: what change means one bad order can ' +
          'never freeze the queue again?',
        kind: 'choice',
        question: 'What is the fix?',
        options: [
          'Advance each order in its own transaction, and skip-and-quarantine statuses the worker cannot classify',
          'Restart the app every hour so the worker starts fresh',
          'Add an index on orders.status so the batch runs faster',
          'Delete the legacy order and change nothing else — it was a freak row',
        ],
        answer: 'Advance each order in its own transaction, and skip-and-quarantine statuses the worker cannot classify',
        proves: 'Case ready to close.',
        reveal:
          'Deleting the row alone leaves the design that made it ' +
          'fatal — and there is always another legacy value. ' +
          'Independent items, a quarantine for the unclassifiable, ' +
          'and migrated values at import: then one bad row costs ' +
          'one row.',
      },
    ],
  },
];
