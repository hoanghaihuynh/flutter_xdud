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

// Lấy sp theo ID
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
      success: "Thêm sản phẩm THÀNH CÔNG",
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

    // Kiểm tra sản phẩm có tồn tại không
    const product = await Product.findById(id);
    if (!product) {
      return res
        .status(404)
        .json({ status: 404, error: "Không tìm thấy sản phẩm" });
    }

    // Xóa sản phẩm
    await Product.findByIdAndDelete(id);

    res.status(200).json({
      status: 200,
      success: "Xóa sản phẩm thành công",
      deletedProduct: product,
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
    const { id } = req.params; // Lấy id từ request params
    const updatedData = req.body; // Dữ liệu cần cập nhật

    const updatedProduct = await Product.findByIdAndUpdate(id, updatedData, {
      new: true,
    });

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
