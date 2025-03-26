const router = require("express").Router();
const UserController = require("./../controller/userController");

router.get("/users/getAll", UserController.getAllUser);
router.get("/users/getUserById/:id", UserController.getUserById);
router.post("/registration", UserController.register);
router.post("/login", UserController.login);
// Log out

module.exports = router;
