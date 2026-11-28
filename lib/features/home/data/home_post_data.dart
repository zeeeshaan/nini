import 'package:hywork/shared/models/local_identity.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

/// Device-local owner identity when no authenticated profile seller is loaded.
/// Empty display fields — not a fabricated marketplace seller.
const localPostSeller = PostSeller(
  id: localProfileId,
  name: '',
  avatarAsset: '',
  bio: '',
);
