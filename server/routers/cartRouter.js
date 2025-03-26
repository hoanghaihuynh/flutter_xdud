const router = require("express").Router();
const CartController = require("./../controller/cartController");

router.get("/cart/getAllCart", CartController.getAllCart);
router.get("/cart/getCartByUserId/:userId", CartController.getCartByUserId);
router.post("/cart/insertCart", CartController.insertCart);
router.delete("/cart/removeProduct", CartController.removeProductFromCart);
router.put("/cart/updateCartQuantity", CartController.updateCartQuantity);

module.exports = router;
