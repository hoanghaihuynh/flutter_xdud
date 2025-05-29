const Voucher = require("./../model/voucherSchema");

class VoucherService {
  //API getAllVoucher
  static async getAllVouchers() {
    return await Voucher.find();
  }

  // Api getVoucherById
  static async getVoucherById(id) {
    return await Voucher.findById(id);
  }

  // API getVoucherByCode
  static async getVoucherByCode(code) {
    return await Voucher.findOne({ code });
  }

  // API thêm voucher
  static async createVoucher(data) {
    const voucher = new Voucher(data);
    await voucher.save();
    return voucher;
  }

  // Api xóa voucher
  static async deleteVoucher(id) {
    const voucher = await Voucher.findById(id);
    if (!voucher) throw new Error("Voucher not found");

    await Voucher.deleteOne({ _id: id });
    return { message: "Voucher DELETED SUCCESSFULLY" };
  }

  // Api sửa voucher
  static async updateVoucher(id, data) {
    const voucher = await Voucher.findById(id);
    if (!voucher) throw new Error("Voucher not found");

    // Cập nhật từng trường nếu có trong dữ liệu đầu vào
    voucher.code = data.code || voucher.code;
    voucher.discount_type = data.discount_type || voucher.discount_type;
    voucher.discount_value = data.discount_value || voucher.discount_value;
    voucher.max_discount = data.max_discount ?? voucher.max_discount;
    voucher.expiry_date = data.expiry_date || voucher.expiry_date;
    voucher.usage_limit = data.usage_limit ?? voucher.usage_limit;

    await voucher.save();
    return voucher;
  }
}
module.exports = VoucherService;
