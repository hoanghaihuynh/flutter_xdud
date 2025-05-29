const VoucherService = require("./../services/voucherService");

exports.createVoucher = async (req, res) => {
  try {
    const voucher = await VoucherService.createVoucher(req.body);
    res.status(201).json(voucher);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateVoucher = async (req, res) => {
  const { id } = req.params;
  try {
    const voucher = await VoucherService.updateVoucher(id, req.body);
    res.json(voucher);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteVoucher = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await VoucherService.deleteVoucher(id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllVouchers = async (req, res) => {
  try {
    const vouchers = await VoucherService.getAllVouchers();
    res.json(vouchers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getVoucherById = async (req, res) => {
  const { id } = req.params;
  try {
    const voucher = await VoucherService.getVoucherById(id);
    if (!voucher) return res.status(404).json({ error: "Voucher not found" });
    res.json(voucher);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getVoucherByCode = async (req, res) => {
  const { code } = req.params;
  try {
    const voucher = await VoucherService.getVoucherByCode(code);
    if (!voucher) return res.status(404).json({ error: "Voucher not found" });
    res.json(voucher);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
