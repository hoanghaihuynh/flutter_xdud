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
          type: mongoose.Schema.Types.ObjectId, // Liên kết tới model Topping
          ref: "toppings", // Tên model Topping
          required: false, // Không bắt buộc, nhưng nếu có thì sẽ là một ID hợp lệ
        },
        size: {
          type: String,
          enum: ["M", "L"], // Các giá trị kích thước có thể chọn
          required: true, // Bắt buộc phải chọn kích thước
        },
        sugarLevel: {
          type: String,
          enum: ["0 SG", "50 SG", "75 SG"], // Các mức độ đường có thể chọn
          required: true, // Bắt buộc phải chọn mức độ đường
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
