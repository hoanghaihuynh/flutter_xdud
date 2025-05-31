const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const CartItemSchema = new Schema(
  {
    itemType: {
      type: String,
      required: true,
      enum: ["PRODUCT", "COMBO"], // Loại mục hàng
    },
    productId: {
      type: Schema.Types.ObjectId,
      ref: "products", 
    },
    comboId: {
      type: Schema.Types.ObjectId,
      ref: "combos", 
      // required: function() { return this.itemType === 'COMBO'; }
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    imageUrl: {
      type: String,
      trim: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
      default: 1,
    },
    price: {
      type: Number,
      required: true,
    },
    
    note: {
      toppings: {
        type: [String], // Mảng tên topping
        default: [],
      },
      size: {
        type: String,
        enum: ["M", "L", ""], // Thêm "" để cho phép không có giá trị nếu là combo
        default: "",
        // required: function() { return this.itemType === 'PRODUCT'; }
      },
      sugarLevel: {
        type: String,
        enum: ["0 SL", "50 SL", "75 SL", ""], 
        default: "",
        // required: function() { return this.itemType === 'PRODUCT'; }
      },
    },
    
  },
  { _id: true }
); // Mỗi mục trong giỏ hàng sẽ có _id riêng

const cartSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "users", required: true },
    items: [CartItemSchema], // <--- SỬA ĐỔI QUAN TRỌNG: Đổi 'products' thành 'items' và dùng schema con
    totalPrice: { type: Number, required: true, default: 0 }, // Tổng tiền TRƯỚC khi áp dụng voucher
    voucher_code: { type: String, default: null },
    discount_amount: { type: Number, default: 0 },
  },
  {
    timestamps: true,
  }
);

// Tạo Model từ Schema
const CartSchema = db.model("carts", cartSchema);

module.exports = CartSchema;
