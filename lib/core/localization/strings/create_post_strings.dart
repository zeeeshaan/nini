import 'package:nini/core/localization/app_string/app_string.dart';

/// English interface copy for the Create Post flow; stored model values stay intact.
abstract final class CreatePostStrings {
  static const cancel = "Cancel";
  static const done = "Done";
  static const add = "Add";
  static const close = "Close";
  static const next = "Next";
  static const retry = "Retry";
  static const tryAgain = "Try again";
  static const createPost = "Create Post";
  static const backToGallery = "Back to gallery";
  static const publish = "Publish";
  static const publishing = "Publishing…";
  static const postType = "Post type";
  static const selectCategory = 'Select a category';
  static const categoryRequired =
      'Select a predefined post category before publishing.';
  static const choosePredefinedCategory = 'Select predefined category';
  static const noProfileCategory = 'No profile category';
  static const profileCategoriesLoading =
      'Your profile categories are still loading. Try again.';
  static const profileCategoryUnavailable =
      'The selected profile category is unavailable. Choose an available category in Manage categories.';
  static const categoriesEmpty = 'No categories are available. Try again.';
  static const categoriesLoadFailed = 'Could not load categories. Try again.';
  static const categoriesTimeout = 'Loading categories timed out. Try again.';
  static const categoriesConnectionFailed =
      'Could not connect to load categories. Try again.';
  static const categoriesInvalid =
      'The category response could not be read. Try again.';
  static const product = "Product";
  static const services = "Services";
  static const productServiceTitle = "Product or service title";
  static const enterPostTitle = "Enter the post title";
  static const postCaption = "Caption";
  static const undo = "Undo";
  static const redo = "Redo";
  static const writeCaption = "Write a caption…";
  static const altText = "Alt text";
  static const altTextHelp =
      "Describe each attachment so screen reader users can understand its content.";
  static const noAttachments = "No attachments selected.";
  static const describeAttachment = "Describe this attachment…";
  static const price = "Price";
  static const enterPrice = "Enter the price";
  static const discount = "Discount";
  static const zeroPercent = "0%";
  static const inventoryStatus = "Inventory status";
  static const inventoryHelp = "Select the current inventory status.";
  static const warehouseStock = "Warehouse stock";
  static const enterStock = "Enter the stock quantity";
  static const stockAvailable = "In stock";
  static const stockUnavailable = "Out of stock";
  static const preOrder = "Pre-order";
  static const preparationTime = "Preparation time";
  static const unit = "Unit";
  static const scheduledPosts = "Schedule post";
  static const time = "Time";
  static const calendar = "Calendar";
  static const timeFrom = "From";
  static const timeTo = "To";
  static const removeSchedule = "Remove schedule";
  static const scheduleHelp =
      "Times use the device clock. If the end time is earlier, it ends the following day.";
  static const differentTimesRequired =
      "Start and end times must be different.";
  static const futureTimeRequired = "Choose a future start date and time.";
  static const schedulePassed =
      "The scheduled time has passed. Choose a future time.";
  static const location = "Location";
  static const address = "Address";
  static const enterFullAddress = "Enter the full address";
  static const addAddress = "Add address";
  static const enterAddressManually = "Enter address manually";
  static const city = "City";
  static const province = "Province";
  static const postalCode = "Postal code";
  static const addressFieldRequired = "This field is required.";
  static const buildingNumber = "Number";
  static const searchCities = "Search cities";
  static const searchProvinces = "Search provinces";
  static const noLocationsFound = "No locations found.";
  static const addressRequired = "Enter the full address.";
  static const findingAddress = "Finding the address for this location…";
  static const addressLookupFailed =
      "Could not find an address for this pin. Type the address manually or select another location.";
  static const addressPinRequired =
      "Your address is entered. Tap the map above to place its location pin, then tap Done.";
  static const chooseMapLocation =
      "Tap the map to fill the address automatically. You can also type or edit the address. The initial map is centered on Tehran.";
  static const mapUnavailable =
      "Map unavailable. Check your internet connection.";
  static const mapAttribution = "© OpenStreetMap contributors";
  static const feature = "Feature";
  static const featureValue = "Value";
  static const addFeature = "Add feature";
  static const saveFeature = "Save feature";
  static const featureAndValueRequired = "Enter a feature name and value.";
  static const featureExists = "This feature already exists. Tap it to edit.";
  static const firstFeatureHelp = "Add your first feature above.";
  static const featuresHeading = "Specifications";
  static const tagsKeywords = "Tags & keywords";
  static const keywords = "Keywords";
  static const separateTags = "Separate tags with commas";
  static const addTags = "Add tags";
  static const galleryAccessRequired = "Allow access to your photo library.";
  static const limitedGalleryAccess =
      "Only permitted photos and videos are shown.";
  static const selectMoreMedia = "Select more media";
  static const fullGalleryAccess = "Full access in Settings";
  static const refreshGallery = "Refresh gallery";
  static const filesPickerHelp =
      "Tap Add files to browse and select files on your device.";
  static const openSettings = "Open Settings";
  static const galleryLoadFailed = "Could not load the gallery.";
  static const yourGalleryLoadFailed = "Could not load your gallery.";
  static const filesSelectionFailed = "Could not select files.";
  static const noVideos = "No videos found.";
  static const noPhotos = "No photos found.";
  static const addFiles = "Add files";
  static const photo = "Photo";
  static const video = "Video";
  static const file = "File";
  static const genericFile = "File";
  static const selectItemRequired = "Select at least one item.";
  static const selectAttachmentRequired = "Select at least one attachment.";
  static const selectPostTypeRequired = "Select a post type.";
  static const titleRequired = "Enter a title.";
  static const captionRequired = "Enter a caption.";
  static const publishFailed = "Could not publish. Please try again.";
  static const invalidPrice = "Enter a valid price.";
  static const invalidDiscount = "Discount must be between 0 and 100.";
  static const invalidStock =
      "Stock must be a whole number greater than or equal to zero.";
  static const publishDetailsRequired =
      "Add media, post type, title, and caption before publishing.";
  static const mediaUnavailable =
      "A selected photo or video is unavailable. Select it again.";
  static const storagePluginUnavailable =
      "Storage or gallery is not ready. Restart the app; rebuild if needed. Your draft is preserved.";
  static const mediaExportFailed =
      "Could not retrieve the selected media. Open it in Photos to download it, then try again. Your draft is preserved.";
  static const savePostFailed =
      "Could not save the post. Your draft is preserved. Please try again.";

  static String descriptionCount(int count) => '$count descriptions';
  static String featureCount(int count) => '$count features';
  static String removeFeature(String name) => 'Remove $name';
  static String mapPin(double latitude, double longitude) =>
      'Coordinates: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  static String fileTypeLabel(String extension) =>
      switch (extension.toUpperCase()) {
        'PDF' || 'DOC' || 'DOCX' || 'TXT' || 'RTF' || 'ODT' => 'Document',
        'JPG' ||
        'JPEG' ||
        'PNG' ||
        'GIF' ||
        'HEIC' ||
        'HEIF' ||
        'WEBP' ||
        'BMP' ||
        'SVG' => 'Photo',
        'MP4' || 'MKV' || 'MOV' || 'AVI' || 'WEBM' || 'M4V' => 'Video',
        'M4A' || 'AAC' || 'MP3' || 'WAV' || 'OGG' || 'FLAC' => 'Audio',
        'ZIP' || 'RAR' || '7Z' || 'TAR' || 'GZ' => 'Archive',
        'XLS' || 'XLSX' || 'CSV' || 'ODS' => 'Spreadsheet',
        'PPT' || 'PPTX' || 'ODP' => 'Slides',
        _ => 'File',
      };

  static String optionLabel(Enum value) => switch (value.name) {
    'none' => 'No preparation',
    'sameDay' => 'Same day',
    'oneDay' => '1 day',
    'twoDays' => '2 days',
    'threeDays' => '3 days',
    'fiveDays' => '5 days',
    'sevenDays' => '7 days',
    'tenDays' => '10 days',
    'fourteenDays' => '14 days',
    'thirtyDays' => '30 days',
    'inStock' => stockAvailable,
    'outOfStock' => stockUnavailable,
    'preOrder' => preOrder,
    'piece' => 'Piece',
    'item' => 'Item',
    'hour' => 'Hour',
    'day' => 'Day',
    'session' => 'Session',
    'project' => 'Project',
    'meter' => 'Meter',
    'centimeter' => 'Centimeter',
    'kilogram' => 'Kilogram',
    'set' => 'Set',
    _ => value.name,
  };

  static String errorMessage(String message) => switch (message) {
    AppStrings.galleryLoadFailed => galleryLoadFailed,
    AppStrings.yourGalleryLoadFailed => yourGalleryLoadFailed,
    AppStrings.filesSelectionFailed => filesSelectionFailed,
    AppStrings.invalidPrice => invalidPrice,
    AppStrings.invalidDiscount => invalidDiscount,
    AppStrings.invalidStock => invalidStock,
    AppStrings.publishDetailsRequired => publishDetailsRequired,
    AppStrings.mediaUnavailable => mediaUnavailable,
    AppStrings.storagePluginUnavailable => storagePluginUnavailable,
    AppStrings.mediaExportFailed => mediaExportFailed,
    AppStrings.savePostFailed => savePostFailed,
    AppStrings.publishFailed => publishFailed,
    AppStrings.schedulePassed => schedulePassed,
    _ => message,
  };
}
