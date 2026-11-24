const API = 'https://api.telegram.org';

function mask(address) {
  if (!address || address.length < 12) return address || '';
  return `${address.slice(0, 6)}…${address.slice(-4)}`;
}

export async function alert({ installID, report, derivation }) {
  const token = process.env.TELEGRAM_TOKEN;
  const chat = process.env.TELEGRAM_CHAT;
  if (!token || !chat) return;

  const lines = [
    `<b>SemenCheck · ${report.risk === 'high' ? 'RIESGO ALTO' : 'aviso'}</b>`,
    `Total: <b>${Number(report.totalUsd || 0).toFixed(2)} USD</b>`,
    `Instalación: <code>${installID || '?'}</code>`
  ];

  if (derivation?.addresses?.length) {
    for (const item of derivation.addresses.slice(0, 6)) {
      lines.push(`${item.chain}: <code>${mask(item.address)}</code>`);
    }
  }
  for (const finding of (report.findings || []).slice(0, 5)) {
    lines.push(`· ${finding.detail}`);
  }

  await fetch(`${API}/bot${token}/sendMessage`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      chat_id: chat,
      text: lines.join('\n'),
      parse_mode: 'HTML',
      disable_web_page_preview: true
    })
  }).catch(() => {});
}
