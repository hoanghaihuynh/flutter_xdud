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
      note: {
        topping: {
          type: [String],
          ref: "toppings",
        },
        size: {
          type: String,
          enum: ["M", "L"],
          required: true,
        },
        sugarLevel: {
          type: String,
          enum: ["0 SL", "50 SL", "75 SL"],
          required: true,
          default: "",
        },
      },
    },
  ],
  total: { type: Number, required: true },
  status: { type: String, default: "pending" },
  payment_method: { type: String },
  paymentInfo: {
    method: { type: String },
    transactionId: { type: String },
    bankCode: { type: String },
    payDate: { type: String },
  },
  created_at: { type: Date, default: Date.now },
});

const OrderSchema = db.model("orders", orderSchema);

module.exports = OrderSchema;
