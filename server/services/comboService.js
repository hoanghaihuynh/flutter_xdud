const Combo = require("./../model/comboSchema");

class ComboService {
  static async createCombo(data) {
    const combo = new Combo(data);
    return await combo.save();
  }

  static async getAllCombo() {
    return await Combo.find().populate("products");
  }

  static async getComboById(id) {
    return await Combo.findById(id).populate("products");
  }

  static async updateCombo(id, data) {
    return await Combo.findByIdAndUpdate(id, data, { new: true });
  }

  static async deleteCombo(id) {
    return await Combo.findByIdAndDelete(id);
  }
}

module.exports = ComboService;
