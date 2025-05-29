const router = require("express").Router();
const TableController = require("./../controller/tableController");

router.post("/table/insertTable", TableController.createTable);
router.get("/table/getAllTables", TableController.getAllTables);
router.get("/table/getAvailableTable", TableController.getAvailableTable);
router.get("/table/getTableById/:id", TableController.getTableById);
router.put("/table/updateTable/:id", TableController.updateTable);
router.delete("/table/deleteTable/:id", TableController.deleteTable);

module.exports = router;
