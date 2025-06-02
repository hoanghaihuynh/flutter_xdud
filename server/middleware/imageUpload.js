// middlewares/imageUpload.js
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// __dirname sẽ là đường dẫn đến thư mục 'middlewares' hiện tại
// '..' sẽ đi lên một cấp (ra thư mục gốc của dự án, nơi chứa 'public' và 'middlewares')
const comboUploadPath = path.join(
  __dirname,
  "..",
  "public",
  "uploads",
  "combos"
);

// Kiểm tra và tạo thư mục nếu chưa tồn tại
if (!fs.existsSync(comboUploadPath)) {
  try {
    fs.mkdirSync(comboUploadPath, { recursive: true });
    console.log(`Thư mục đã được tạo: ${comboUploadPath}`);
  } catch (err) {
    console.error(`Lỗi khi tạo thư mục ${comboUploadPath}:`, err);
    // Cân nhắc việc throw lỗi ở đây hoặc xử lý khác nếu việc tạo thư mục là bắt buộc
  }
} else {
  console.log(`Thư mục đã tồn tại: ${comboUploadPath}`);
}

// Cấu hình lưu trữ cho ảnh combo
const comboStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, comboUploadPath);
  },
  filename: function (req, file, cb) {
    cb(
      null,
      file.fieldname + "-" + Date.now() + path.extname(file.originalname)
    );
  },
});

// Bộ lọc file (chỉ cho phép upload ảnh)
const imageFileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Chỉ cho phép upload file ảnh (jpg, jpeg, png, gif)!"), false);
  }
};

const uploadComboImage = multer({
  storage: comboStorage,
  fileFilter: imageFileFilter,
  limits: {
    fileSize: 1024 * 1024 * 5, // Giới hạn kích thước file 5MB
  },
}).single("comboImage");

module.exports = {
  uploadComboImage,
};
