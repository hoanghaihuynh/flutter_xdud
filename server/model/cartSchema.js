const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const cartSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "users", required: true }, // Liên kết với user
    products: [
      {
        productId: { type: Schema.Types.ObjectId, ref: "products", required: true }, // Liên kết với sản phẩm
        quantity: { type: Number, required: true, min: 1, default: 1 }, // Số lượng sản phẩm
        price: { type: Number, required: true }, // Giá tại thời điểm thêm vào giỏ hàng
      },
    ],
    totalPrice: { type: Number, required: true, default: 0 }, // Tổng giá trị đơn hàng
  },
  { timestamps: true } // Thêm createdAt & updatedAt
);

// Tạo Model từ Schema
const CartSchema = db.model("carts", cartSchema);

module.exports = CartSchema;
