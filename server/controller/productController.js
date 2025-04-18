// responsible for request and response: chịu trách nhiệm cho việc nhận và trả lời phản hồi

const ProductService = require("./../services/productServices");
const Product = require("./../model/productSchema");

// Lấy danh sách sản phẩm
exports.getAllProduct = async (req, res, next) => {
  try {
    const products = await ProductService.getAllProduct();
    res.status(201).json({
      status: 201,
      success: "Lấy danh sách sản phẩm THÀNH CÔNG",
      products,
    }); // Phải gọi products ra
  } catch (error) {
    res.status(500).json({ status: 401, error: "Lỗi server", error });
  }
};

// Lấy sản phẩm theo ID
exports.getProductByID = async (req, res, next) => {
  try {
    const product = await ProductService.getProductByID(req.params.id);
    if (!product) {
      return res
        .status(404)
        .json({ status: 401, error: "Không tìm thấy Product" });
    }
    res.status(200).json({
      status: 201,
      success: "Tìm sản phẩm THÀNH CÔNG",
      data: product,
    });
  } catch (error) {
    throw error;
  }
};

// Thêm sản phẩm mới
exports.insertProduct = async (req, res, next) => {
  try {
    const { name } = req.body; // Lấy name từ request body

    // Kiểm tra trùng tên
    const existingProduct = await Product.findOne({ name });
    if (existingProduct) {
      return res
        .status(400)
        .json({ response: false, message: "Sản phẩm đã tồn tại!" });
    }

    // Tạo sản phẩm mới
    const newProduct = await ProductService.createProduct(req.body);

    res.status(201).json({
      status: 201,
      success: "PRODUCT ADDED SUCCESSFULLY",
      data: newProduct,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

// Xóa sản phẩm theo ID
exports.deleteProduct = async (req, res, next) => {
  try {
    const { id } = req.params;

    const deletedProduct = await ProductService.deleteProduct(id);

    if (!deletedProduct) {
      return res
        .status(404)
        .json({ status: 404, error: "Không tìm thấy sản phẩm" });
    }

    res.status(200).json({
      status: 200,
      success: "Xóa sản phẩm thành công",
      deletedProduct,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

// Cập nhật sản phẩm
exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const updatedData = req.body;

    const updatedProduct = await ProductService.updateProduct(id, updatedData);

    if (!updatedProduct) {
      return res
        .status(404)
        .json({ status: 404, error: "Không tìm thấy sản phẩm để cập nhật" });
    }

    res.status(200).json({
      status: 200,
      success: "Cập nhật sản phẩm THÀNH CÔNG",
      data: updatedProduct,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};
