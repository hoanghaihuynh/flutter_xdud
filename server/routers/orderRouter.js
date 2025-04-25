const router = require("express").Router();
const OrderController = require("./../controller/orderController");

router.post("/order/insertOrder", OrderController.insertOrder);
router.get("/order/getAllOrder", OrderController.getAllOrder);
router.put("/order/updateOrder", OrderController.updateOrder);
router.get("/order/vnpay_return", OrderController.vnpayReturn);

module.exports = router;
