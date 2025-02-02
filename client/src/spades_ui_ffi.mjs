import { scheme_to_string } from "../gleam_http/gleam/http.mjs"

export function getHostnameAndPort() {
  return [window.location.hostname, window.location.port]
}

export function urlFromRequest(req) {
  const url = new URL(`${scheme_to_string(req.scheme)}://${req.host}:${req.port}${req.path}`);
  return url;
}

export function initSSE(req, callback) {
  const url = urlFromRequest(req);
  const eventSource = new EventSource(url, { withCredentials: true });
  eventSource.onmessage = (event) => {
    callback(event.data)
  };
}
