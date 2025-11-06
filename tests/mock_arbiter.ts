import fetch from 'node-fetch';
import nacl from 'tweetnacl';
import bs58 from 'bs58';

// Simple helper to request a ticket from the mock arbiter and verify signature
export async function requestAndVerifyTicket(url: string, dealId: string, verdict: number) {
  const res = await fetch(url + '/ticket', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ dealId, verdict }),
  });
  const json = await res.json();
  const { ticket, signature, pubkey } = json;
  const payloadBytes = Buffer.from(ticket.payload, 'utf8');
  const sigBytes = bs58.decode(signature);
  const pubkeyBytes = bs58.decode(pubkey);

  const ok = nacl.sign.detached.verify(payloadBytes, sigBytes, pubkeyBytes);
  if (!ok) throw new Error('Invalid ticket signature');
  return { ticket, pubkey };
}

// Example usage in Anchor test
if (require.main === module) {
  (async () => {
    try {
      const result = await requestAndVerifyTicket('http://localhost:4001', 'deal-123', 2);
      console.log('Verified ticket:', result);
    } catch (err) {
      console.error(err);
      process.exit(1);
    }
  })();
}
