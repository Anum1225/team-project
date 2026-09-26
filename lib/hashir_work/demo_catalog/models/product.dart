class Product {
  const Product(
    this.id,
    this.name,
    this.category,
    this.price,
    this.unit,
    this.stock,
    this.farmerId,
    this.symbol,
    this.color,
    this.description, {
    this.organic = false,
  });
  final String id, name, category, unit, farmerId, symbol, description;
  final int price, stock, color;
  final bool organic;
}
