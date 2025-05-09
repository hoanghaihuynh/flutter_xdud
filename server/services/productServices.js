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
      return await ProductModel.findById(id).populate("toppings", "name");
      // "toppings" là tên field trong schema
      // "name" là field bạn muốn lấy từ topping (chỉ trả về name)
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

  // Xóa sản phẩm theo ID
  static async deleteProduct(id) {
    try {
      const product = await ProductModel.findById(id);
      if (!product) return null;

      await ProductModel.findByIdAndDelete(id);
      return product;
    } catch (error) {
      throw error;
    }
  }

  // Cập nhật sản phẩm
  static async updateProduct(id, updatedData) {
    try {
      const updatedProduct = await ProductModel.findByIdAndUpdate(
        id,
        updatedData,
        {
          new: true,
        }
      );

      return updatedProduct;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = ProductService;
