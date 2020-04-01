export async function client<T>(
  path: string,
  overrides: RequestInit = {}
): Promise<T> {
  const options = {
    method: "GET",
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
