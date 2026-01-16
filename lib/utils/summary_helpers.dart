import '../models/asset.dart';

Map<AssetCategory, int> countAssetsByCategory(List<Asset> assets) {
  final Map<AssetCategory, int> counts = {};
  for (final asset in assets) {
    counts[asset.category] = (counts[asset.category] ?? 0) + 1;
  }
  return counts;
}