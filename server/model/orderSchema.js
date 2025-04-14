const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const orderSchema = new Schema({
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: "users",
  },
  products: [
    {
      product_id: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "products",
      },
      quantity: { type: Number, required: true },
      price: { type: Number, required: true },
    },
  ],
  total: { type: Number, required: true },
  status: { type: String, default: "pending" },
  created_at: { type: Date, default: Date.now },
});

const OrderSchema = db.model("orders", orderSchema);

module.exports = OrderSchema;
