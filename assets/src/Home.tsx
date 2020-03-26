import React from "react";
import { useCallback } from "react";
import { useState } from "react";

import styles from "./Home.module.css";

function Home() {
  const [name, setName] = useState("");

  const onNameChange = useCallback(e => {
    setName(e.currentTarget.value);
  }, [setName]);

  return (
    <div className={styles.fullscreen}>
      <input
        type="text"
        placeholder="Choose a name"
        onChange={onNameChange}
        value={name}
      />
    </div>
  )
}

export default Home;
