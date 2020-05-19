export enum Progress {
  Idle,
  Loading,
  Loaded,
  Error,
}

export async function request<T>([path, options]: FetchArguments): Promise<T> {
  try {
    if (path.search("/api") === -1) {
      path = `/api${path}`;
    }
    const results = await fetch(path, options);
    if (!results.ok) {
      const err = await results.json();
      throw err.error;
    }
    return await results.json();
  } catch (err) {
    throw err;
  }
}

export function makeRequest(
  method: "GET" | "POST" | "PUT" | "DELETE",
  body?: Object,
  overrides?: RequestInit
): RequestInit {
  return {
    method,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
    credentials: "include",
    ...overrides,
  };
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

export const deleteRequest = (
  path: string,
  body?: Object,
  overrides?: RequestInit
): FetchArguments => [path, makeRequest("DELETE", body, overrides)];

export async function get<T>(
  path: string,
  overrides?: RequestInit
): Promise<T> {
  return request(getRequest(path, overrides));
}

export async function post<T>(
  path: string,
  body?: Object,
  overrides?: RequestInit
): Promise<T> {
  return request(postRequest(path, body, overrides));
}

export async function put<T>(
  path: string,
  body: Object,
  overrides?: RequestInit
): Promise<T> {
  return request(putRequest(path, body, overrides));
}

export async function delete_<T>(
  path: string,
  body?: Object,
  overrides?: RequestInit
): Promise<T> {
  return request(deleteRequest(path, body, overrides));
}
