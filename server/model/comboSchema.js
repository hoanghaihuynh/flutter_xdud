const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const comboSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    products: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "products", // Tên collection bạn đã định nghĩa trong ProductModel
      },
    ],
    imageUrl: {
      type: String,
      trim: true,
      default: "https://via.placeholder.com/300x200",
    },
  },

  { timestamps: true }
);

// Tạo Model từ Schema
const ComboSchema = db.model("combos", comboSchema);

module.exports = ComboSchema;
