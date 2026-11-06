import 'package:nini/core/localization/search_strings.dart';

/// One local example card. Every image path and price is written out below.
class DemoSearchPost {
  const DemoSearchPost({
    required this.title,
    required this.providerId,
    required this.imageAsset,
    required this.price,
    required this.cities,
    this.originalPrice = '',
    this.discount = '',
    this.isPreOrder = false,
  });

  final String title;
  final String providerId;
  final String imageAsset;
  final String price;
  final List<String> cities;
  final String originalPrice;
  final String discount;
  final bool isPreOrder;
}

// These images already exist in assets/. No images are downloaded or generated.
// These are frontend examples, not real listings from a server.
const demoSearchPosts = [
  DemoSearchPost(
    providerId: 'provider-plumbing-arya',
    title: SearchStrings.emergencyPlumbing,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-ab',
    title: SearchStrings.drainCleaning,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'مشهد'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-sepehr',
    title: SearchStrings.blockedDrain,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'اصفهان'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-arya',
    title: SearchStrings.toiletRepair,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-ab',
    title: SearchStrings.toiletInstallation,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-sepehr',
    title: SearchStrings.leakDetection,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-arya',
    title: SearchStrings.waterLeakRepair,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-ab',
    title: SearchStrings.pipeRepair,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'اصفهان'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-sepehr',
    title: SearchStrings.burstPipeRepair,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'شیراز'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-arya',
    title: SearchStrings.boilerRepair,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-ab',
    title: SearchStrings.radiatorRepair,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-sepehr',
    title: SearchStrings.tapRepair,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-arya',
    title: SearchStrings.faucetRepair,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'اصفهان'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-ab',
    title: SearchStrings.showerRepair,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'شیراز'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-sepehr',
    title: SearchStrings.bathroomPlumbing,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'تبریز'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-arya',
    title: SearchStrings.kitchenPlumbing,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'اصفهان'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-ab',
    title: SearchStrings.waterHeaterRepair,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    providerId: 'provider-plumbing-sepehr',
    title: SearchStrings.gasPlumbing,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
];
