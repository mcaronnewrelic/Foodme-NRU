export const DEMO_CODE_STORAGE_KEY = 'orderup-demo-code';
export const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_PATTERN = /^(OU|SIM)-[A-Z0-9]{4}$/;
let fallbackCode: string | undefined;

export function generateDemoCode(): string {
  let suffix = '';
  for (let index = 0; index < 4; index++) {
    suffix += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  }
  return `OU-${suffix}`;
}

export function loadOrCreateDemoCode(): string {
  try {
    const fromUrl = new URLSearchParams(location.search).get('demoCode');
    if (fromUrl && CODE_PATTERN.test(fromUrl)) {
      localStorage.setItem(DEMO_CODE_STORAGE_KEY, fromUrl);
      return fromUrl;
    }
    const stored = localStorage.getItem(DEMO_CODE_STORAGE_KEY);
    if (stored && CODE_PATTERN.test(stored)) return stored;
    const code = generateDemoCode();
    localStorage.setItem(DEMO_CODE_STORAGE_KEY, code);
    return code;
  } catch {
    return (fallbackCode ??= generateDemoCode());
  }
}

export function initializeBrowserIdentity(): string {
  const code = loadOrCreateDemoCode();
  window.newrelic?.setUserId?.(code);
  window.newrelic?.setCustomAttribute?.('demoCode', code, true);
  return code;
}
