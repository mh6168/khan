class CustomerProfileInfo {
  const CustomerProfileInfo({
    this.name,
    this.email,
    this.phone,
    this.profileLoadFailed = false,
  });

  final String? name;
  final String? email;
  final String? phone;
  final bool profileLoadFailed;
}
