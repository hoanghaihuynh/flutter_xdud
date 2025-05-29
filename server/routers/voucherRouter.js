const router = require("express").Router();
const VoucherController = require("./../controller/voucherController");

router.post("/voucher/createVoucher", VoucherController.createVoucher);
router.put("/voucher/updateVoucher/:id", VoucherController.updateVoucher);
router.delete("/voucher/deleteVoucher/:id", VoucherController.deleteVoucher);
router.get("/voucher/getAllVoucher", VoucherController.getAllVouchers);
router.get("/voucher/getVoucherById/:id", VoucherController.getVoucherById);
router.get(
  "/voucher/getVoucherByCode/:code",
  VoucherController.getVoucherByCode
);

module.exports = router;
