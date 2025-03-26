// responsible for data logic: chịu trách nhiệm cho data logic như tạo, xóa, sửa user
const ProductModel = require("./../model/productSchema");

class ProductService {
  // Lấy danh sách sản phẩm
  static async getAllProduct() {
    try {
      return await ProductModel.find();
    } catch (error) {
      throw error;
    }
  }

  // Lấy sản phẩm theo ID
  static async getProductByID(id) {
    try {
      return await ProductModel.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Thêm sản phẩm mới
  static async createProduct(productData) {
    try {
      const newProduct = new ProductModel(productData);
      return await newProduct.save();
    } catch (error) {
      throw error;
    }
  }
}

module.exports = ProductService;
