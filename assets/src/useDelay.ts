import isEqual from "lodash/isEqual";
import { useEffect } from "react";
import { useState } from "react";

export default function useDelay<T>(
  value: T | undefined,
  shouldDelay: (previous: T | undefined, next: T | undefined) => boolean,
  mapper?: (value: T) => T,
  delay = 2000
): T | undefined {
  const [previous, setPrevious] = useState<T | undefined>(undefined);
  const [current, setCurrent] = useState<T | undefined>(value);
  const [timer, setTimer] = useState<number | undefined>(undefined);

  useEffect(() => {
    let cancelled = false;
    if (!isEqual(current, value)) {
      setPrevious(current);
      setCurrent(value);
      if (timer && !cancelled) {
        clearTimeout(timer);
        setTimer(undefined);
      }
    }
    return () => {
      cancelled = true;
    };
  }, [current, previous, timer, value]);

  if (shouldDelay(previous, current)) {
    if (!timer) {
      setTimer(() => {
        const updated = current;
        return window.setTimeout(() => {
          setPrevious(updated);
          setTimer(undefined);
        }, delay);
      });
    }
    return mapper && previous ? mapper(previous) : previous;
  }
  return current;
}
