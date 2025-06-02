const ComboService = require("./../services/comboService");

exports.createCombo = async (req, res) => {
  try {
    const comboData = req.body; // Dữ liệu text từ form

    // Nếu có file được upload bởi multer, thông tin file sẽ ở req.file
    if (req.file) {
      comboData.imageUrl = `/uploads/combos/${req.file.filename}`;
    } else if (!comboData.imageUrl) {
      // Nếu không upload file mới và cũng không có imageUrl cũ (ví dụ, khi tạo mới mà không upload)
      // bạn có thể muốn đặt một ảnh mặc định hoặc báo lỗi nếu ảnh là bắt buộc
      // comboData.imageUrl = '/uploads/combos/default-placeholder.png'; // Ví dụ
    }
    // Nếu client gửi imageUrl dưới dạng text (URL cũ hoặc không đổi), và không upload file mới,
    // thì comboData.imageUrl đã có sẵn giá trị đó từ req.body

    const combo = await ComboService.createCombo(comboData);
    res.status(201).json(combo);
  } catch (error) {
    console.error("Error in createCombo controller:", error);
    // Nếu lỗi từ multer (ví dụ file quá lớn, sai loại file), nó có thể cần xử lý riêng
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ error: "File ảnh quá lớn (tối đa 5MB)." });
    }
    if (
      error.message &&
      error.message.includes("Chỉ cho phép upload file ảnh")
    ) {
      return res.status(400).json({ error: error.message });
    }
    res.status(400).json({ error: error.message || "Lỗi khi tạo combo." });
  }
};

exports.getAllCombos = async (req, res) => {
  try {
    const combos = await ComboService.getAllCombo();
    res.json(combos);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getComboById = async (req, res) => {
  const { id } = req.params;

  try {
    const combo = await ComboService.getComboById(id);
    if (!combo) return res.status(404).json({ error: "Combo not found" });
    res.json(combo);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateCombo = async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  try {
    // Nếu có file mới được upload cho việc cập nhật
    if (req.file) {
      updateData.imageUrl = `/uploads/combos/${req.file.filename}`;
      // TODO: Cân nhắc xóa file ảnh cũ của combo này trên server nếu bạn muốn
      // Điều này cần query combo cũ, lấy imageUrl cũ, rồi dùng fs.unlink
    }
    // Nếu không có req.file, updateData.imageUrl từ req.body sẽ được giữ nguyên (nếu client gửi)
    // Hoặc nếu client không gửi imageUrl trong body và không upload file mới,
    // thì trường imageUrl của combo sẽ không được cập nhật bởi service (trừ khi service có logic riêng).

    const updatedCombo = await ComboService.updateCombo(id, updateData);
    if (!updatedCombo)
      return res.status(404).json({ error: "Combo not found" });
    res.json(updatedCombo);
  } catch (error) {
    console.error("Error in updateCombo controller:", error);
    if (error.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ error: "File ảnh quá lớn (tối đa 5MB)." });
    }
    if (
      error.message &&
      error.message.includes("Chỉ cho phép upload file ảnh")
    ) {
      return res.status(400).json({ error: error.message });
    }
    res.status(400).json({ error: error.message || "Lỗi khi cập nhật combo." });
  }
};

exports.deleteCombo = async (req, res) => {
  const { id } = req.params;

  try {
    const deleted = await ComboService.deleteCombo(id);
    if (!deleted) return res.status(404).json({ error: "Combo not found" });
    res.json({ message: "Combo deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
