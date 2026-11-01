export interface Mission {
  id: string;
  number: number;
  title: string;
  /** Where the progress strip's tick takes the visitor to start (or revisit) the mission. */
  link: string;
  /** The mission's check question id - a mission counts as checked when that question is solved. */
  questionId: string;
}

/** The five missions of spec section 2, in journey order. */
export const MISSIONS: Mission[] = [
  { id: 'mission-1', number: 1, title: 'Say who you are', link: '/customer', questionId: 'event-type-count' },
  { id: 'mission-2', number: 2, title: 'Find a menu in the data', link: '/restaurants', questionId: 'filter-no-request' },
  { id: 'mission-3', number: 3, title: 'Place the order, keep the receipt', link: '/checkout', questionId: 'request-id-tail' },
  { id: 'mission-4', number: 4, title: 'Find it again later', link: '/orders', questionId: 'join-keys' },
  { id: 'mission-5', number: 5, title: 'Break it on purpose', link: '/how-it-works', questionId: 'simulated-error-type' },
];

export function missionById(id: string): Mission | undefined {
  return MISSIONS.find(m => m.id === id);
}

/** The mission a route belongs to, for the strip's "Mission N of 5" label. */
export function missionForUrl(url: string): Mission | null {
  if (url.startsWith('/customer')) return MISSIONS[0];
  if (url.startsWith('/restaurants') || url.startsWith('/menu/')) return MISSIONS[1];
  if (url.startsWith('/checkout') || url.startsWith('/thank-you')) return MISSIONS[2];
  if (url.startsWith('/orders')) return MISSIONS[3];
  if (url.startsWith('/how-it-works')) return MISSIONS[4];
  return null;
}
