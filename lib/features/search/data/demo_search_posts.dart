import 'package:nini/core/localization/search_strings.dart';

/// One local example card. Every image path and price is written out below.
class DemoSearchPost {
  const DemoSearchPost({
    required this.title,
    required this.imageAsset,
    required this.price,
    required this.cities,
    this.originalPrice = '',
    this.discount = '',
    this.isPreOrder = false,
  });

  final String title;
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
    title: SearchStrings.emergencyPlumbing,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    title: SearchStrings.drainCleaning,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'مشهد'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    title: SearchStrings.blockedDrain,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'اصفهان'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    title: SearchStrings.toiletRepair,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    title: SearchStrings.toiletInstallation,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
  DemoSearchPost(
    title: SearchStrings.leakDetection,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    title: SearchStrings.waterLeakRepair,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    title: SearchStrings.pipeRepair,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'اصفهان'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    title: SearchStrings.burstPipeRepair,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'شیراز'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    title: SearchStrings.boilerRepair,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    title: SearchStrings.radiatorRepair,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    title: SearchStrings.tapRepair,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
  DemoSearchPost(
    title: SearchStrings.faucetRepair,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'اصفهان'],
  ),
  DemoSearchPost(
    title: SearchStrings.showerRepair,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'شیراز'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    title: SearchStrings.bathroomPlumbing,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'تبریز'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    title: SearchStrings.kitchenPlumbing,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'اصفهان'],
  ),
  DemoSearchPost(
    title: SearchStrings.waterHeaterRepair,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    title: SearchStrings.gasPlumbing,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
];
