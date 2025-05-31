const router = require("express").Router();
const ComboController = require("./../controller/comboController");

router.post("/combo/insertCombo", ComboController.createCombo);
router.get("/combo/getAllCombo", ComboController.getAllCombos);
router.get("/combo/getComboById/:id", ComboController.getComboById);
router.put("/combo/updateCombo/:id", ComboController.updateCombo);
router.delete("/combo/deleteCombo/:id", ComboController.deleteCombo);

module.exports = router;
