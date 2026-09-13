class ApiConfig {
  const ApiConfig._();

  static const _mobileBaseUrl =
      'https://breeding-brute-antirust.ngrok-free.dev/AgroVida/Mobile';

  static final loginUrl = Uri.parse('$_mobileBaseUrl/MobileLogin.php');
  static final parcelasUrl = Uri.parse('$_mobileBaseUrl/MobileParcelas.php');
}
