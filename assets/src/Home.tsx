import React from "react";
import { useCallback } from "react";
import { useDispatch } from "react-redux";
import { useHistory } from "react-router-dom";
import { useState } from "react";

import { setUsername } from "./features/user/userSlice";

import styles from "./Home.module.css";

function Home() {
  const [name, setName] = useState("");
  const dispatch = useDispatch();
  const history = useHistory();

  const onNameChange = useCallback(e => {
    setName(e.currentTarget.value);
  }, [setName]);

  const onJoin = useCallback(() => {
    dispatch(setUsername(name));
    history.push("/lobby");
  }, [dispatch, history, name]);

  return (
    <div className={styles.fullscreen}>
      <input
        type="text"
        placeholder="Choose a name"
        onChange={onNameChange}
        value={name}
      />
      <button onClick={onJoin}>Join</button>
    </div>
  )
}

export default Home;
