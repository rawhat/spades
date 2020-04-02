export async function client<T>(
  path: string,
  overrides: RequestInit = {}
): Promise<T> {
  const options: RequestInit = {
    method: "GET",
    headers: {
      'Content-Type': 'application/json',
    },
    ...overrides,
  };
  try {
    const res = await fetch(`/api${path}`, options);
    if (!res.ok) {
      throw res;
    }
    const data = await res.json();
    return data;
  } catch (err) {
    throw err;
  }
}

export async function get<T>(path: string): Promise<T> {
  return client(path, { method: "GET" });
}

export async function post<T>(path: string, body?: Object): Promise<T> {
  const options: RequestInit = { method: "POST" };
  if (body) {
    options.body = JSON.stringify(body);
  }
  return client(path, options);
}

export async function put<T>(path: string, body: Object): Promise<T> {
  return client(path, { method: "PUT", body: JSON.stringify(body) });
}
