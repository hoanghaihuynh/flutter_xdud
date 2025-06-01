const mongoose = require("mongoose");
const db = require("./../config/db");

const { Schema } = mongoose;

const OrderProductDetailSchema = new Schema(
  {
    product_id: {
      // ID của sản phẩm đơn lẻ
      type: mongoose.Schema.Types.ObjectId,
      ref: "products",
      // required: true, // Sẽ không required ở đây nữa, mà tùy theo itemType
    },
    combo_id: {
      // ID của combo
      type: mongoose.Schema.Types.ObjectId,
      ref: "combos", // Tham chiếu đến collection combos của bạn
      // required: true, // Tương tự, không required ở đây
    },
    itemType: {
      // Để phân biệt là PRODUCT hay COMBO
      type: String,
      required: true,
      enum: ["PRODUCT", "COMBO"],
    },
    name: { type: String, required: true }, // Tên sản phẩm hoặc combo tại thời điểm đặt hàng
    imageUrl: { type: String }, // imageUrl sản phẩm hoặc combo
    quantity: { type: Number, required: true },
    price: { type: Number, required: true }, // Giá của 1 đơn vị sản phẩm HOẶC 1 gói combo tại thời điểm đặt hàng
    // Ghi chú cho sản phẩm đơn lẻ
    note: {
      toppings: [
        {
          // Thay đổi: Lưu tên topping như bạn đang làm ở service, hoặc đối tượng topping đầy đủ
          name: String,
          price: Number, // Lưu lại giá topping tại thời điểm đặt hàng
        },
      ],
      size: {
        type: String,
        enum: ["M", "L", ""], // Thêm rỗng cho combo nếu không áp dụng
        // required: true, // Bỏ required, vì combo có thể không có size tổng
      },
      sugarLevel: {
        type: String,
        enum: ["0 SL", "50 SL", "75 SL", ""], // Thêm rỗng cho combo
        // required: true, // Bỏ required
        default: "",
      },
      // Thêm một trường để lưu chi tiết các sản phẩm con nếu itemType là COMBO (snapshot)
      comboProductsSnapshot: [
        {
          productId: String, // Hoặc ObjectId nếu bạn muốn ref
          name: String,
          quantityInCombo: Number,
          defaultSize: String,
          defaultSugarLevel: String,
          // defaultToppings: [String] // Tên các topping mặc định của sản phẩm trong combo
        },
      ],
    },
    toppingPrice: { type: Number, default: 0 }, // Tổng giá topping cho MỘT đơn vị sản phẩm (nếu là product)
  },
  { _id: false }
); // Không cần _id cho subdocument này nếu không truy vấn trực tiếp

const orderSchema = new Schema({
  user_id: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: "users",
  },
  items: [OrderProductDetailSchema], // << THAY ĐỔI: đổi tên từ 'products' sang 'items' và dùng schema con mới
  total: { type: Number, required: true }, // Tổng tiền cuối cùng của đơn hàng sau khi đã trừ voucher
  subtotal: { type: Number, required: true }, // Tổng tiền của các items trước khi áp dụng voucher
  discount_amount: { type: Number, default: 0 }, // Số tiền được giảm từ voucher
  voucher_code: { type: String, default: null },
  status: { type: String, default: "pending" }, // pending, paid, processing, shipped, delivered, cancelled, payment_failed
  payment_method: { type: String, required: true },
  paymentInfo: {
    // Thông tin nếu thanh toán online thành công
    method: { type: String },
    transactionId: { type: String },
    bankCode: { type: String },
    payDate: { type: String },
  },
  created_at: { type: Date, default: Date.now },
  table_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "tables",
    default: null,
  },
  table_number: {
    type: String,
    default: null,
    trim: true,
  },
});
const OrderSchema = db.model("orders", orderSchema);

module.exports = OrderSchema;
