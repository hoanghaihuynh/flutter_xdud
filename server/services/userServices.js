// responsible for data logic: chịu trách nhiệm cho data logic như tạo, xóa, sửa user

const UserModel = require("./../model/userSchema");
const jwt = require("jsonwebtoken");

class UserService {
  static async registerUser(email, password, role = "user") {
    try {
      const createUser = new UserModel({
        email,
        password,
        role,
      });
      return await createUser.save();
    } catch (error) {
      throw error;
    }
  }

  static async checkUser(email) {
    try {
      return await UserModel.findOne({ email });
    } catch (error) {
      throw error;
    }
  }

  static async generateToken(token, secretKey, jwt_expire) {
    return jwt.sign(token, secretKey, { expiresIn: jwt_expire });
  }
}

module.exports = UserService;
