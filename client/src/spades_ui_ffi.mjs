export function getHostnameAndPort() {
  return [window.location.hostname, window.location.port]
}

export function initSSE(path, callback) {
  const eventSource = new EventSource(path, { withCredentials: true });
  eventSource.onmessage = (event) => {
    callback(event.data)
  };
}
