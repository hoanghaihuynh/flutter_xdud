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
      required: true, // Nếu ảnh bắt buộc
      trim: true,
      default: "https://via.placeholder.com/150", // Ảnh mặc định nếu không có
    },
  },
  { timestamps: true }
);

// Tạo Model từ Schema
const ProductModel = db.model("products", productSchema);

module.exports = ProductModel;
