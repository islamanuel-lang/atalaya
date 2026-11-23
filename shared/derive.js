import { mnemonicToSeedSync, validateMnemonic } from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';
import { HDKey } from '@scure/bip32';
import { p2wpkh } from '@scure/btc-signer';
import { secp256k1 } from '@noble/curves/secp256k1';
import { ed25519 } from '@noble/curves/ed25519';
import { keccak_256 } from '@noble/hashes/sha3';
import { sha256 } from '@noble/hashes/sha256';
import { sha512 } from '@noble/hashes/sha512';
import { hmac } from '@noble/hashes/hmac';
import bs58 from 'bs58';

function hex(bytes) {
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
}

// EIP-55 para mostrar la dirección con checksum
function checksumAddress(lower) {
  const body = lower.slice(2);
  const hash = keccak_256(new TextEncoder().encode(body));
  let result = '0x';
  for (let i = 0; i < body.length; i++) {
    const nibble = i % 2 === 0 ? hash[i >> 1] >> 4 : hash[i >> 1] & 0x0f;
    result += nibble >= 8 ? body[i].toUpperCase() : body[i];
  }
  return result;
}

export function normalizePhrase(phrase) {
  return String(phrase || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .split(/[^a-z]+/)
    .filter(Boolean)
    .join(' ');
}

export function isValid(phrase) {
  return validateMnemonic(phrase, wordlist);
}

function slip10(seed, path) {
  let I = hmac(sha512, new TextEncoder().encode('ed25519 seed'), seed);
  let key = I.slice(0, 32);
  let chain = I.slice(32);
  for (const index of path) {
    const data = new Uint8Array(37);
    data[0] = 0;
    data.set(key, 1);
    new DataView(data.buffer).setUint32(33, (index | 0x80000000) >>> 0, false);
    I = hmac(sha512, chain, data);
    key = I.slice(0, 32);
    chain = I.slice(32);
  }
  return key;
}

export function hashPhrase(phrase) {
  return Array.from(sha256(new TextEncoder().encode(phrase)))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function deriveAll(phrase) {
  if (!isValid(phrase)) throw new Error('checksum o palabras inválidas');

  const seed = mnemonicToSeedSync(phrase);
  const root = HDKey.fromMasterSeed(seed);

  const ethChild = root.derive("m/44'/60'/0'/0/0");
  const ethPub = secp256k1.getPublicKey(ethChild.privateKey, false).slice(1);
  const eth = checksumAddress('0x' + hex(keccak_256(ethPub).slice(-20)));

  const btcChild = root.derive("m/84'/0'/0'/0/0");
  const btc = p2wpkh(btcChild.publicKey).address;

  const solKey = slip10(seed, [44, 501, 0, 0]);
  const sol = bs58.encode(ed25519.getPublicKey(solKey));

  const tronChild = root.derive("m/44'/195'/0'/0/0");
  const tronPub = secp256k1.getPublicKey(tronChild.privateKey, false).slice(1);
  const tronHash = keccak_256(tronPub).slice(-20);
  const payload = new Uint8Array(21);
  payload[0] = 0x41;
  payload.set(tronHash, 1);
  const checksum = sha256(sha256(payload)).slice(0, 4);
  const tron = bs58.encode(new Uint8Array([...payload, ...checksum]));

  return {
    hash: hashPhrase(phrase),
    addresses: [
      { chain: 'ethereum', address: eth },
      { chain: 'bsc', address: eth },
      { chain: 'polygon', address: eth },
      { chain: 'bitcoin', address: btc },
      { chain: 'solana', address: sol },
      { chain: 'tron', address: tron }
    ]
  };
}
