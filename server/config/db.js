const mongoose = require("mongoose");

const connection = mongoose
  .createConnection("mongodb+srv://honghihunh:VM7vWYkliImqsEiM@cluster0.tkt1sgp.mongodb.net/coffeeShop")
  .on("open", () => {
    console.log("Mongodb Connected Successfully");
  })
  .on("error", () => {
    console.log("Mongodb Connection Error");
  });

module.exports = connection;
