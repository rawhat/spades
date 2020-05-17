export enum Progress {
  Idle,
  Loading,
  Loaded,
  Error
}

export function request(request: FetchArguments) {
  return fetch(...request);
}

export async function client<T>(
  path: string,
  overrides: RequestInit = {}
): Promise<T> {
  const options: RequestInit = {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
    },
    ...overrides,
  };
  try {
    console.log('options are', options);
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

export function makeRequest(
  method: "GET" | "POST" | "PUT",
  body?: Object,
  overrides?: RequestInit
): RequestInit {
  return {
    method,
    body: JSON.stringify(body),
    ...overrides
  }
}

export type FetchArguments = [string, RequestInit];

export const getRequest = (
  path: string,
  overrides?: RequestInit
): FetchArguments => [path, makeRequest("GET", undefined, overrides)];

export const postRequest = (
  path: string,
  body?: Object,
  overrides?: RequestInit
): FetchArguments => [path, makeRequest("POST", body, overrides)];

export const putRequest = (
  path: string,
  body: Object,
  overrides?: RequestInit
): FetchArguments => [path, makeRequest("POST", body, overrides)];

export async function get<T>(path: string, overrides?: RequestInit): Promise<T> {
  return client(...getRequest(path, overrides));
}

export async function post<T>(path: string, body?: Object, overrides?: RequestInit): Promise<T> {
  return client(...postRequest(path, body, overrides));
}

export async function put<T>(path: string, body: Object, overrides?: RequestInit): Promise<T> {
  return client(...putRequest(path, body, overrides));
}
