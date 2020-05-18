import { useEffect, useState } from "react";

import { FetchArguments, Progress, request } from "./app/client"

interface QueryResponse<T, E extends string> {
  data?: T;
  error?: {[K in E]: string[]};
  status: Progress;
}

export function useQuery<T, E extends string>(req?: FetchArguments): QueryResponse<T, E> {
  const [data, setData] = useState<T>();
  const [error, setError] = useState<QueryResponse<T, E>['error']>();
  const [status, setStatus] = useState(Progress.Idle);

  useEffect(() => {
    let canceled = false;
    if (req) {
      setStatus(Progress.Loading);
      request(req)
        .then(data => data.json())
        .then((data: T) => {
          if (!canceled) {
            setData(data);
            setStatus(Progress.Loaded);
          }
        })
        .catch((err) => {
          if (!canceled) {
            setError(err);
            setStatus(Progress.Error);
          }
        });
    }
    return () => {
      canceled = true;
    }
  }, [req])

  return {
    data,
    error,
    status
  }
}
