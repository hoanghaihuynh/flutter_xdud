const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const cartSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "users", required: true },
    products: [
      {
        productId: {
          type: Schema.Types.ObjectId,
          ref: "products",
          required: true,
        },
        quantity: { type: Number, required: true, min: 1, default: 1 },
        price: { type: Number, required: true },
        note: {
          toppings: [String],
          size: {
            type: String,
            enum: ["M", "L"], // Các giá trị kích thước có thể chọn
            required: true, // Bắt buộc phải chọn kích thước
          },
          sugarLevel: {
            type: String,
            enum: ["0 SL", "50 SL", "75 SL"], // Các mức độ đường có thể chọn
            required: true, // Bắt buộc phải chọn mức độ đường
            default: "",
          },
        },
      },
    ],
    totalPrice: { type: Number, required: true, default: 0 },
    // Voucher
    voucher_code: { type: String, default: null }, // Thêm trường voucher_code
    discount_amount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// Tạo Model từ Schema
const CartSchema = db.model("carts", cartSchema);

module.exports = CartSchema;
