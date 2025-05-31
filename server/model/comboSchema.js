const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const ComboProductItemSchema = new Schema({
    productId: {
        type: Schema.Types.ObjectId,
        ref: "products", 
        required: true
    },
    quantityInCombo: { 
        type: Number,
        required: true,
        min: 1,
        default: 1
    },
    defaultSize: {
        type: String,
        enum: ["M", "L"], // Lấy từ cartSchema của bạn
        required: true // Mỗi sản phẩm trong combo cần có size mặc định
    },
    defaultSugarLevel: {
        type: String,
        enum: ["0 SL", "50 SL", "75 SL"], // Lấy từ cartSchema của bạn
        required: true // Mỗi sản phẩm trong combo cần có mức đường mặc định
    },
    defaultToppings: [{ // Mảng các ID của topping mặc định
        type: Schema.Types.ObjectId,
        ref: 'toppings' // Tên model Topping của bạn (ví dụ: 'Topping' hoặc 'toppings')
    }]
}, { _id: false }); // Không cần _id cho subdocument này nếu bạn không truy vấn nó trực tiếp


// --- SCHEMA CHÍNH CHO COMBO ---
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
    price: { // Giá của TOÀN BỘ combo
      type: Number,
      required: true,
      min: 0,
    },
    products: [ComboProductItemSchema], // <--- SỬA ĐỔI QUAN TRỌNG: Sử dụng schema con ở đây
    imageUrl: {
      type: String,
      trim: true,
      default: "https://via.placeholder.com/300x200",
    },
    category: { // Thêm trường này để dễ phân loại
        type: String,
        default: 'Combo',
        trim: true
    },
    isActive: { // Cho biết combo có đang được bán hay không
        type: Boolean,
        default: true
    },
  },
  { timestamps: true }
);

const ComboModel = db.model("combos", comboSchema); // Đặt tên biến là ComboModel cho rõ

module.exports = ComboModel; // Export Model

