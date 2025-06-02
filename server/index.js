// Nơi chứa các ứng dụng của nodejs

const express = require("express");
const path = require("path");
const app = require("./app");
const port = 3000;
const db = require("./config/db");
const cors = require("cors"); // Import thư viện CORS
app.use(cors()); // Cho phép tất cả request

app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.send("HelloWorld!!??@@");
});

app.listen(port, () => {
  console.log(`Server listening to http://localhost:${port}`);
});
