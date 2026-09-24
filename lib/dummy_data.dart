/// Dummy data for HarvestHub project verification and initial setup
class HarvestHubDummyData {
  static const String projectId = 'harvesthub-80047';
  static const String appName = 'HarvestHub';
  static const String status = 'Ready for work';

  static final Map<String, dynamic> projectVerificationDoc = {
    'projectId': projectId,
    'status': status,
    'appName': appName,
    'connectedAt': DateTime.now().toIso8601String(),
    'message': 'HarvestHub Firebase connection verified successfully!',
  };

  static final List<Map<String, dynamic>> dummyCrops = [
    {
      'id': 'crop_001',
      'name': 'Organic Wheat',
      'category': 'Grains',
      'quantity': '500 kg',
      'pricePerKg': '\$2.50',
      'status': 'In Stock',
      'harvestDate': '2026-09-15',
    },
    {
      'id': 'crop_002',
      'name': 'Fresh Tomatoes',
      'category': 'Vegetables',
      'quantity': '250 kg',
      'pricePerKg': '\$1.80',
      'status': 'Harvested',
      'harvestDate': '2026-09-20',
    },
    {
      'id': 'crop_003',
      'name': 'Sweet Corn',
      'category': 'Grains',
      'quantity': '350 kg',
      'pricePerKg': '\$1.20',
      'status': 'Growing',
      'harvestDate': '2026-10-05',
    },
  ];
}
