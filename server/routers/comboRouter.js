const router = require("express").Router();
const ComboController = require("./../controller/comboController");
const { uploadComboImage } = require("./../middleware/imageUpload");

router.post(
  "/combo/insertCombo",
  uploadComboImage,
  ComboController.createCombo
);
router.get("/combo/getAllCombo", ComboController.getAllCombos);
router.get("/combo/getComboById/:id", ComboController.getComboById);
router.put(
  "/combo/updateCombo/:id",
  uploadComboImage,
  ComboController.updateCombo
);
router.delete("/combo/deleteCombo/:id", ComboController.deleteCombo);

module.exports = router;
