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
