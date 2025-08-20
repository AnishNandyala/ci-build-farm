import React from "react";
import RunTests from "./RunTests";

export default function App() {
  return (
    <div className="app">
      <div className="header">
        <h1>CI Build Farm Portal</h1>
        <small>Self-service test runner</small>
      </div>

      <RunTests />
    </div>
  );
}