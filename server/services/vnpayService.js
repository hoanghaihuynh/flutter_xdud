const { VNPay } = require("vnpay");
const vnpayConfig = require("./../config/vnpayConfig");

class VNPayService {
  static createPaymentUrl(orderId, amount, bankCode = null, orderInfo = "") {
    const vnpay = new VNPay({
      tmnCode: vnpayConfig.vnp_TmnCode,
      secureSecret: vnpayConfig.vnp_HashSecret,
      vnpayHost: vnpayConfig.vnp_Url,
      returnUrl: vnpayConfig.vnp_ReturnUrl,
      apiHost: vnpayConfig.vnp_Api,
    });

    const date = new Date();
    const createDate = date.toISOString().replace(/[-:]/g, "").split(".")[0];

    const params = {
      vnp_Amount: amount ,
      vnp_TxnRef: orderId,
      vnp_Command: "pay",
      vnp_CreateDate: createDate,
      vnp_CurrCode: "VND",
      vnp_IpAddr: "192.168.1.5", // IP của khách hàng, cần lấy từ request
      vnp_Locale: "vn",
      vnp_OrderInfo: orderInfo || `Thanh toan don hang ${orderId}`,
      vnp_OrderType: "other",
      vnp_ReturnUrl: vnpayConfig.vnp_ReturnUrl,
      vnp_TmnCode: vnpayConfig.vnp_TmnCode,
      vnp_Version: "2.1.0",
    };

    if (bankCode) {
      params.vnp_BankCode = bankCode;
    }

    const paymentUrl = vnpay.buildPaymentUrl(params);
    return paymentUrl;
  }

  static verifyReturn(query) {
    const vnpay = new VNPay({
      tmnCode: vnpayConfig.vnp_TmnCode,
      secureSecret: vnpayConfig.vnp_HashSecret,
    });

    return vnpay.verifyReturn(query);
  }
}

module.exports = VNPayService;
