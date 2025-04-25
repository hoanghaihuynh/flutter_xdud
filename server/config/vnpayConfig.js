const vnpayConfig = {
  vnp_TmnCode: "WHMK8AUE",
  vnp_HashSecret: "KFRHXSK95O0CE4VWLCIMDAG1D5G70I8Y",
  vnp_Url: "https://sandbox.vnpayment.vn",
  vnp_ReturnUrl: "https://1dd0-1-53-200-207.ngrok-free.app/order/vnpay_return", // URL return sau khi thanh toán
  vnp_Api: "https://sandbox.vnpayment.vn/merchant_webapi/api/transaction",
};

module.exports = vnpayConfig;
