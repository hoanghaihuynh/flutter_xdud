const router = require("express").Router();
const ProductController = require("./../controller/productController");

router.get("/products/getAll", ProductController.getAllProduct);
router.get("/products/getProductByID/:id", ProductController.getProductByID);
router.post("/products/insertProduct", ProductController.insertProduct);
router.delete("/products/deleteProduct/:id", ProductController.deleteProduct);
router.put("/products/updateProduct/:id", ProductController.updateProduct);


module.exports = router;
