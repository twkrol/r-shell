import { beforeEach, describe, expect, it, vi } from 'vitest';

const invoke = vi.hoisted(() => vi.fn());

vi.mock('@tauri-apps/api/core', () => ({
  invoke: (...args: unknown[]) => invoke(...args),
}));

import { getWebSocketUrl } from '../lib/websocket-endpoint';

describe('getWebSocketUrl (bridge handshake token, issue #138)', () => {
  beforeEach(() => {
    invoke.mockReset();
  });

  it('asks the backend for the endpoint and puts the token in the query string', async () => {
    invoke.mockResolvedValue({ port: 9004, token: 'abc-DEF_123' });

    await expect(getWebSocketUrl()).resolves.toBe('ws://127.0.0.1:9004/?token=abc-DEF_123');
    expect(invoke).toHaveBeenCalledWith('get_websocket_endpoint');
  });

  it('percent-encodes a token that is not URL-safe', async () => {
    invoke.mockResolvedValue({ port: 9001, token: 'a+b/c=' });

    await expect(getWebSocketUrl()).resolves.toBe('ws://127.0.0.1:9001/?token=a%2Bb%2Fc%3D');
  });

  it('gives no address without a token, so nothing is sent to a port that another program may hold', async () => {
    invoke.mockRejectedValue(new Error('WebSocket bridge is not running'));
    await expect(getWebSocketUrl()).rejects.toThrow('WebSocket bridge is not running');

    for (const endpoint of [{ port: 9001, token: '' }, { port: 0, token: 'abc' }, { port: 9001.5, token: 'abc' }]) {
      invoke.mockResolvedValue(endpoint);
      await expect(getWebSocketUrl()).rejects.toThrow('Invalid bridge endpoint');
    }
  });
});
