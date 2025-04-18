// responsible for request and response: chịu trách nhiệm cho việc nhận và trả lời phản hồi
const User = require("./../model/userSchema");
const UserService = require("./../services/userServices");

// Lấy danh sách tất cả người dùng
exports.getAllUser = async (req, res) => {
  try {
    const users = await User.find(); // Lấy toàn bộ danh sách người dùng từ DB
    res.status(200).json({
      status: 200,
      success: "Lấy danh sách người dùng thành công",
      data: users,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

// Lấy thông tin người dùng theo ID
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params; // Lấy ID từ request params
    const user = await User.findById(id); // Tìm user theo ID

    if (!user) {
      return res
        .status(404)
        .json({ status: 404, error: "Không tìm thấy người dùng" });
    }

    res.status(200).json({
      status: 200,
      success: "Lấy thông tin người dùng thành công",
      data: user,
    });
  } catch (error) {
    res
      .status(500)
      .json({ status: 500, error: "Lỗi server", message: error.message });
  }
};

exports.register = async (req, res, next) => {
  try {
    const { email, password } = req.body; // sử dụng body-parser để phản hồi về cho frontedn

    const successResponse = await UserService.registerUser(email, password);

    res
      .status(201)
      .json({ statusCode: 201, success: "User Registered Successfully" });
  } catch (error) {
    res.status(500).json({ statusCode: 401, error: "Internal Server Error" });
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const user = await UserService.checkUser(email);

    if (!user) {
      throw new Error("User doesnt exist");
    }

    const isMatch = await user.comparePassword(password);

    if (isMatch === false) {
      throw new Error("Password Invalid");
    }

    let tokenData = { _id: user._id, _email: user.email };
    const token = await UserService.generateToken(tokenData, "secretKey", "1h");

    res.status(200).json({
      success: "User Login Successfully",
      message: "LOGIN SUCCESSFULLY",
      status: 200,
      token: token,
    });
  } catch (error) {
    res.status(400).json({ success: false, error: "LOGIN FAILED" });
  }
};
