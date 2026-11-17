abstract final class OrderInformationStrings {
  static const title = 'Order information';
  static const amountPayable = 'Amount payable';
  static const personalInformation = 'Personal Information';
  static const name = 'Name';
  static const surname = 'Surname';
  static const mobile = 'Mobile Number';
  static const city = 'City';
  static const province = 'Province';
  static const address = 'Address';
  static const postalCode = 'Postal Code';
  static const chooseAddress = 'Choose address on the map';
  static const invalidMobile = 'Enter a valid mobile number.';
  static const invalidPostalCode = 'Enter a valid postal code.';
  static const cartChanged =
      'Your Cart changed. Return to order information and review the total.';
  static const emptyCheckout = 'No items are selected for checkout.';
  static String requiredField(String label) => 'Enter ${label.toLowerCase()}.';
}
