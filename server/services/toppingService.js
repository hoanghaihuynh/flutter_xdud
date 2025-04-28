const Topping = require("./../model/toppingSchema");
// const Product = require("./../model/productSchema");

class ToppingService {
  static async insertTopping(name, price, description) {
    const topping = new Topping({
      name,
      price,
      description,
    });

    await topping.save();
    return topping;
  }

  static async updateTopping(id, name, price, description) {
    const topping = await Topping.findById(id);
    if (!topping) throw new Error("Topping not found");

    topping.name = name || topping.name;
    topping.price = price || topping.price;
    topping.description = description || topping.description;

    await topping.save();
    return topping;
  }

  static async removeTopping(id) {
    const topping = await Topping.findById(id);
    if (!topping) throw new Error("Topping not found");

    // Sử dụng deleteOne thay vì remove
    await Topping.deleteOne({ _id: id });

    return { message: "Topping deleted" };
  }

  static async getAllToppings() {
    return await Topping.find();
  }

  static async getToppingById(id) {
    return await Topping.findById(id);
  }
}
module.exports = ToppingService;
