import 'package:nini/core/localization/search_strings.dart';
import 'package:nini/shared/models/post/post_seller.dart';

/// One local example card. Every image path and price is written out below.
class DemoSearchPost {
  const DemoSearchPost({
    required this.title,
    required this.seller,
    required this.imageAsset,
    required this.price,
    required this.cities,
    this.originalPrice = '',
    this.discount = '',
    this.isPreOrder = false,
  });

  final String title;
  final PostSeller seller;
  String get providerId => seller.id;
  final String imageAsset;
  final String price;
  final List<String> cities;
  final String originalPrice;
  final String discount;
  final bool isPreOrder;
}

// Explicit frontend provider identities, keyed independently of post/city/name.
const aryaSearchSeller = PostSeller(
  id: 'provider-plumbing-arya',
  name: 'Arya Plumbing',
  avatarAsset: 'assets/img1.png',
);
const abSearchSeller = PostSeller(
  id: 'provider-plumbing-ab',
  name: 'Ab Plumbing',
  avatarAsset: 'assets/img2.png',
);
const sepehrSearchSeller = PostSeller(
  id: 'provider-plumbing-sepehr',
  name: 'Sepehr Plumbing',
  avatarAsset: 'assets/img3.png',
);

// These images already exist in assets/. No images are downloaded or generated.
// These are frontend examples, not real listings from a server.
const demoSearchPosts = [
  DemoSearchPost(
    seller: aryaSearchSeller,
    title: SearchStrings.emergencyPlumbing,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    seller: abSearchSeller,
    title: SearchStrings.drainCleaning,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'مشهد'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    seller: sepehrSearchSeller,
    title: SearchStrings.blockedDrain,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'اصفهان'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    seller: aryaSearchSeller,
    title: SearchStrings.toiletRepair,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    seller: abSearchSeller,
    title: SearchStrings.toiletInstallation,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
  DemoSearchPost(
    seller: sepehrSearchSeller,
    title: SearchStrings.leakDetection,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    seller: aryaSearchSeller,
    title: SearchStrings.waterLeakRepair,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'شیراز'],
  ),
  DemoSearchPost(
    seller: abSearchSeller,
    title: SearchStrings.pipeRepair,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'اصفهان'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    seller: sepehrSearchSeller,
    title: SearchStrings.burstPipeRepair,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'شیراز'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    seller: aryaSearchSeller,
    title: SearchStrings.boilerRepair,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    seller: abSearchSeller,
    title: SearchStrings.radiatorRepair,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    seller: sepehrSearchSeller,
    title: SearchStrings.tapRepair,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
  DemoSearchPost(
    seller: aryaSearchSeller,
    title: SearchStrings.faucetRepair,
    imageAsset: 'assets/img1.png',
    price: '99000',
    cities: [SearchStrings.tehran, 'اصفهان'],
  ),
  DemoSearchPost(
    seller: abSearchSeller,
    title: SearchStrings.showerRepair,
    imageAsset: 'assets/img2.png',
    price: '57000',
    cities: [SearchStrings.tehran, 'شیراز'],
    isPreOrder: true,
  ),
  DemoSearchPost(
    seller: sepehrSearchSeller,
    title: SearchStrings.bathroomPlumbing,
    imageAsset: 'assets/img3.png',
    price: '12000',
    cities: [SearchStrings.tehran, 'تبریز'],
    originalPrice: '12500',
    discount: '4',
  ),
  DemoSearchPost(
    seller: aryaSearchSeller,
    title: SearchStrings.kitchenPlumbing,
    imageAsset: 'assets/img1.png',
    price: '91000',
    cities: [SearchStrings.tehran, 'اصفهان'],
  ),
  DemoSearchPost(
    seller: abSearchSeller,
    title: SearchStrings.waterHeaterRepair,
    imageAsset: 'assets/img2.png',
    price: '64000',
    cities: [SearchStrings.tehran, 'مشهد'],
  ),
  DemoSearchPost(
    seller: sepehrSearchSeller,
    title: SearchStrings.gasPlumbing,
    imageAsset: 'assets/img3.png',
    price: '82000',
    cities: [SearchStrings.tehran, 'تبریز'],
  ),
];
