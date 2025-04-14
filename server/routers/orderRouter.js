const router = require("express").Router();
const OrderController = require("./../controller/orderController");

router.post("/order/insertOrder", OrderController.insertOrder);
router.get("/order/getAllOrder", OrderController.getAllOrder);

module.exports = router;
