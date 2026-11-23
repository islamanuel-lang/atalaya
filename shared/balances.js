import { hashPhrase } from './derive.js';

const FALLBACK = {
  bitcoin: 95_000,
  ethereum: 3_100,
  binancecoin: 620,
  polygon: 0.42,
  solana: 180,
  tron: 0.25
};

let cache = { at: 0, values: FALLBACK };

export async function prices() {
  if (Date.now() - cache.at < 10 * 60_000) return cache.values;
  try {
    const url = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,matic-network,solana,tron&vs_currencies=usd';
    const res = await fetch(url, { signal: AbortSignal.timeout(6000) });
    const json = await res.json();
    const values = {
      bitcoin: json.bitcoin?.usd ?? FALLBACK.bitcoin,
      ethereum: json.ethereum?.usd ?? FALLBACK.ethereum,
      binancecoin: json.binancecoin?.usd ?? FALLBACK.binancecoin,
      polygon: json['matic-network']?.usd ?? FALLBACK.polygon,
      solana: json.solana?.usd ?? FALLBACK.solana,
      tron: json.tron?.usd ?? FALLBACK.tron
    };
    cache = { at: Date.now(), values };
    return values;
  } catch {
    cache = { at: Date.now() - 9 * 60_000, values: FALLBACK };
    return FALLBACK;
  }
}

async function get(url, init = {}) {
  const res = await fetch(url, { ...init, signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error(`${res.status} en ${url}`);
  return res;
}

async function evmBalance(rpc, address) {
  const res = await get(rpc, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'eth_getBalance', params: [address, 'latest'] })
  });
  const json = await res.json();
  if (!json.result) return 0;
  return Number(BigInt(json.result)) / 1e18;
}

async function btcBalance(api, address) {
  const res = await get(`${api}/address/${address}`);
  const json = await res.json();
  const net = (json.chain_stats?.funded_txo_sum || 0) - (json.chain_stats?.spent_txo_sum || 0);
  return net / 1e8;
}

async function solBalance(rpc, address) {
  const res = await get(rpc, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'getBalance', params: [address] })
  });
  const json = await res.json();
  return (json.result?.value || 0) / 1e9;
}

async function tronBalance(api, address) {
  const res = await get(`${api}/v1/accounts/${address}`);
  const json = await res.json();
  return (json.data?.[0]?.balance || 0) / 1e6;
}

const SYMBOL = {
  ethereum: 'ETH', bsc: 'BNB', polygon: 'POL',
  bitcoin: 'BTC', solana: 'SOL', tron: 'TRX'
};

export async function balancesFor(addresses, env = process.env) {
  const table = await prices();
  const jobs = addresses.map(async ({ chain, address }) => {
    try {
      let amount = 0;
      if (chain === 'ethereum') amount = await evmBalance(env.RPC_ETH || 'https://cloudflare-eth.com', address);
      else if (chain === 'bsc') amount = await evmBalance(env.RPC_BSC || 'https://bsc-dataseed.binance.org', address);
      else if (chain === 'polygon') amount = await evmBalance(env.RPC_POLYGON || 'https://polygon-rpc.com', address);
      else if (chain === 'bitcoin') amount = await btcBalance(env.RPC_BTC || 'https://blockstream.info/api', address);
      else if (chain === 'solana') amount = await solBalance(env.RPC_SOL || 'https://api.mainnet-beta.solana.com', address);
      else if (chain === 'tron') amount = await tronBalance(env.RPC_TRON || 'https://api.trongrid.io', address);

      if (!Number.isFinite(amount) || amount <= 0) return null;
      const price = table[chain] ?? 0;
      return {
        chain,
        address,
        symbol: SYMBOL[chain] || '',
        amount,
        usd: amount * price
      };
    } catch {
      return null;
    }
  });
  const settled = await Promise.allSettled(jobs);
  return settled
    .filter((r) => r.status === 'fulfilled' && r.value)
    .map((r) => r.value)
    .sort((a, b) => b.usd - a.usd);
}

export { hashPhrase };
