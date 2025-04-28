const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const toppingSchema = new Schema({
  name: {
    type: String,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  description: {
    type: String,
    required: false,
  },
});

const ToppingSchema = db.model("toppings", toppingSchema);

module.exports = ToppingSchema;
