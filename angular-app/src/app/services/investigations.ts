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
];
