const ToppingService = require("./../services/toppingService");

exports.insertTopping = async (req, res) => {
  const { name, price, description } = req.body;
  try {
    const topping = await ToppingService.insertTopping(
      name,
      price,
      description
    );
    res.status(201).json(topping);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateTopping = async (req, res) => {
  const { id } = req.params;
  const { name, price, description } = req.body;

  try {
    const topping = await ToppingService.updateTopping(
      id,
      name,
      price,
      description
    );
    res.json(topping);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteTopping = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await ToppingService.removeTopping(id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllToppings = async (req, res) => {
  try {
    const toppings = await ToppingService.getAllToppings();
    res.json(toppings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getToppingById = async (req, res) => {
  const { id } = req.params;

  try {
    const topping = await ToppingService.getToppingById(id);
    if (!topping) return res.status(404).json({ error: "Topping not found" });
    res.json(topping);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
