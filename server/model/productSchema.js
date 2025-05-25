const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const productSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    description: {
      type: String,
      trim: true,
    },
    category: {
      type: String,
      required: true,
      trim: true,
    },
    stock: {
      type: Number,
      required: true,
      min: 0,
    },
    imageUrl: {
      type: String,
      required: true,
      trim: true,
      default: "https://via.placeholder.com/150", // Đường dẫn ảnh mặc định
    },
    toppings: [
      {
        type: Schema.Types.ObjectId,
        ref: "toppings", // Ánh xạ đến model topping
      },
    ],
    size: {
      type: [String], // Mảng các giá trị kích thước có thể chọn
      enum: ["M", "L"], // Các giá trị kích thước có thể chọn
      default: ["M"], // Giá trị mặc định cho kích thước
    },
    sugarLevel: {
      type: [String], // Mảng các mức độ đường có thể chọn
      enum: ["0 SL", "50 SL", "75 SL"], // Các mức độ đường có thể chọn
      default: [""], // Mức độ đường mặc định là 100% (không cần lưu trữ)
    },
  },
  { timestamps: true }
);

// Tạo Model từ Schema
const ProductModel = db.model("products", productSchema);

module.exports = ProductModel;
