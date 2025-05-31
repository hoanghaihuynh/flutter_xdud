const ComboService = require("./../services/comboService");

exports.createCombo = async (req, res) => {
  try {
    const combo = await ComboService.createCombo(req.body);
    res.status(201).json(combo);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getAllCombos = async (req, res) => {
  try {
    const combos = await ComboService.getAllCombo();
    res.json(combos);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getComboById = async (req, res) => {
  const { id } = req.params;

  try {
    const combo = await ComboService.getComboById(id);
    if (!combo) return res.status(404).json({ error: "Combo not found" });
    res.json(combo);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateCombo = async (req, res) => {
  const { id } = req.params;

  try {
    const updatedCombo = await ComboService.updateCombo(id, req.body);
    if (!updatedCombo)
      return res.status(404).json({ error: "Combo not found" });
    res.json(updatedCombo);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteCombo = async (req, res) => {
  const { id } = req.params;

  try {
    const deleted = await ComboService.deleteCombo(id);
    if (!deleted) return res.status(404).json({ error: "Combo not found" });
    res.json({ message: "Combo deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
