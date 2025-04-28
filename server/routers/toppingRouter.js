const router = require("express").Router();
const ToppingController = require("./../controller/toppingController");

router.post("/topping/insertTopping", ToppingController.insertTopping);
router.put("/topping/updateTopping/:id", ToppingController.updateTopping);
router.delete("/topping/deleteTopping/:id", ToppingController.deleteTopping);
router.get("/topping/getAllToppings", ToppingController.getAllToppings);
router.get("/topping/getToppingById/:id", ToppingController.getToppingById);

module.exports = router;
