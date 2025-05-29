const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const tableSchema = new Schema(
  {
    table_number: {
      type: String,
      required: [true],
      trim: true,
      unique: true,
    },
    capacity: {
      type: Number,
      required: [true],
      min: [1], //Sức chứa ít nhất là 1
    },
    status: {
      type: String,
      required: true,
      enum: ["available", "occupied"],
      default: "available",
    },
    description: {
      type: String,
      required: false,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Tạo Model từ Schema
const TableSchema = db.model("tables", tableSchema);

module.exports = TableSchema;
