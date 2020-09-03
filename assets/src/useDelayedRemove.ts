import { useEffect, useState } from "react";

export function useDelayedRemove<T>(nextItems: T[], delay = 2000) {
  const [items, setItems] = useState<T[]>(nextItems);

  useEffect(() => {
    const timeouts = nextItems.map((item, index) => {
      return [
        setTimeout(() => {
          setItems((items) => items.filter((i) => i !== item));
        }, (index + 1) * delay),
        item,
      ] as const;
    });
    setItems((oldItems) => oldItems.concat(nextItems));
    return () => {
      timeouts
        .filter(([_, item]) => items.includes(item))
        .forEach(([timeout]) => {
          clearTimeout(timeout);
        });
    };
  }, [delay, nextItems]);

  return items;
}
