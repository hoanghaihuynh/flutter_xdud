// models/voucher.js
const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const voucherSchema = new Schema({
  code: { type: String, required: true, unique: true },
  discount_type: { type: String, enum: ["percent", "fixed"], required: true },
  discount_value: { type: Number, required: true },
  max_discount: { type: Number, default: 0 },
  start_date: { type: Date, required: true },
  expiry_date: { type: Date, required: true },
  quantity: { type: Number, required: true },
  used_count: { type: Number, default: 0 },
});

const VoucherSchema = db.model("vouchers", voucherSchema);

module.exports = VoucherSchema;
