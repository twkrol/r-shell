import { invoke } from '@tauri-apps/api/core';

/** Shape returned by the `get_websocket_endpoint` Tauri command. */
export interface WebSocketEndpoint {
  port: number;
  token: string;
}

/**
 * Build the URL for the local PTY/desktop WebSocket bridge.
 *
 * The bridge listens on loopback, which every local process — and, through a
 * browser, every web page — can reach. Since issue #138 the backend therefore
 * requires a per-launch token in the handshake; it is only ever handed to this
 * webview via IPC, so it must travel in the query string of every connection.
 *
 * The token is also the only sign that the listener is this app's bridge.
 * Without an endpoint (the bridge did not start, or there is no backend) this
 * rejects: any program may hold a fixed port, and it would get the terminal
 * input.
 */
export async function getWebSocketUrl(): Promise<string> {
  const { port, token } = await invoke<WebSocketEndpoint>('get_websocket_endpoint');
  if (!token || !Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid bridge endpoint');
  return `ws://127.0.0.1:${port}/?token=${encodeURIComponent(token)}`;
}
