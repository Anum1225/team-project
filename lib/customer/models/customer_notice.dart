class CustomerNotice {
  CustomerNotice(this.title, this.message, {this.read = false});
  final String title, message;
  bool read;
}
