/// Supported storefront currencies (codes only).
const kSupportedCurrencyCodes = ['AED', 'USD', 'PKR'];

const kDefaultCurrencyCode = 'AED';

String normalizeCurrencyCode(String code) {
  final u = code.toUpperCase().trim();
  return kSupportedCurrencyCodes.contains(u) ? u : kDefaultCurrencyCode;
}

String currencyOptionLabel(String code) {
  switch (normalizeCurrencyCode(code)) {
    case 'AED':
      return 'AED · UAE Dirham';
    case 'USD':
      return 'USD · US Dollar';
    case 'PKR':
      return 'PKR · Pakistani Rupee';
    default:
      return code;
  }
}
