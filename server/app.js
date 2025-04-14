// Chứa các router
const express = require("express");
const body_parser = require("body-parser");
const morgan = require("morgan");
const userRouter = require("./routers/userRouter");
const productRouter = require("./routers/productRouter");
const cartRouter = require("./routers/cartRouter");
const orderRouter = require("./routers/orderRouter");

const app = express();

// app.use(morgan("hello"));

app.use(body_parser.json()); // ép kiểu response trả về kết quả là dạng json

app.use("/", userRouter);
app.use("/", productRouter);
app.use("/", cartRouter);
app.use("/", orderRouter);

module.exports = app;
