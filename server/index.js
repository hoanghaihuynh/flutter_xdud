// Nơi chứa các ứng dụng của nodejs

const app = require("./app");
const port = 3000;
const db = require("./config/db");
const cors = require("cors"); // Import thư viện CORS
app.use(cors()); // Cho phép tất cả request

app.get("/", (req, res) => {
  res.send("HelloWorld!!??@@");
});

app.listen(port, () => {
  console.log(`Server listening to http://localhost:${port}`);
});
