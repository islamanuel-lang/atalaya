import assert from 'node:assert/strict';
import { deriveAll, isValid, normalizePhrase } from '../../shared/derive.js';

const PHRASE = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

assert.equal(normalizePhrase('  Abandon, abandon. ABANDON\t'), 'abandon abandon abandon');
assert.equal(isValid(PHRASE), true);
assert.equal(isValid('abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon'), false);

const out = deriveAll(PHRASE);
const byChain = Object.fromEntries(out.addresses.map((a) => [a.chain, a.address]));

assert.equal(byChain.ethereum, '0x9858EfFD232B4033E47d90003D41EC34EcaEda94');
assert.equal(byChain.bitcoin, 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu');
assert.equal(byChain.solana, 'HAgk14JpMQLgt6rVgv7cBQFJWFto5Dqxi472uT3DKpqk');
assert.equal(byChain.tron.startsWith('T'), true);
assert.equal(byChain.tron.length, 34);
assert.equal(out.hash.length, 64);

// Determinismo
assert.deepEqual(deriveAll(PHRASE).addresses, out.addresses);

console.log('derive OK', byChain);
