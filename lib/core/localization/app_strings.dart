/// English development copy shared by screens, tooltips, and accessibility labels.
abstract final class AppStrings {
  static const appName = 'HYWORK';
  static const appearance = "Appearance";
  static const systemTheme = "Use device theme";
  static const lightTheme = "Light";
  static const darkTheme = "Dark";
  static const home = "Home";
  static const cart = "Cart";
  static const addToCart = "Add to Cart";
  static const cartAdded = "Added to Cart";
  static const viewCart = "View Cart";
  static const cartStorageError =
      "Storage is unavailable. Your changes have not been saved yet.";
  static const cartStockExceeded = "This quantity exceeds the available stock.";
  static const create = "Create Post";
  static const search = "Search";
  static const profile = "Profile";
  static const all = "All";
  static const webDevelopment = "Web Development";
  static const electricalWiring = "Electrical Wiring";
  static const products = "Products";
  static const photography = "Photography";
  static const addCategory = "Add category";
  static const messages = "Messages";
  static const message = 'Message';
  static const followers = 'Followers';
  static const follow = 'Follow';
  static const following = 'Following';
  static const noSellerPosts = 'No posts yet';
  static const moreOptions = "More options";
  static const morePostOptions = "More post options";
  static const back = "Back";
  static const toman = "toman";
  static const sellerProfile = "Seller profile";
  static String viewSellerProfile(String name) => 'View $name profile';
  static const sellerName = "Moji";
  static const shopAndStore = "Shop & Store";
  static const sellerBio =
      "Creative designer passionate about turning ideas\ninto visual stories.";
  static const profileImage = "Moji profile picture";
  static const posts = "Posts";
  static const sales = "Sales";
  static const customers = "Customers";
  static const headphoneTitle = "Wireless\nBluetooth headphones";
  static const mobile = "Mobile";
  static const from = "From";
  static const authorName = "PipeMaster";
  static const authorLocation = "Tehran, Iran";
  static const authorImage = "Author profile picture";
  static const like = "Like";
  static const unlike = "Unlike";
  static const bookmark = "Save post";
  static const removeBookmark = "Unsave post";
  static const comments = "Comments";
  static const share = "Share";
  static const rating = "Rating";

  static const postTitle = "Title: Fixing Leaky Faucets Like a Pro!";
  static const visualSuggestion =
      "Image suggestion: a leaking faucet and a professional plumber with tools, or before-and-after repair photos.";
  static const captionHeading = "Caption / description:";
  static const caption =
      "Tired of a constantly dripping faucet? 💧 Do not let small leaks become big problems. Our experienced plumbers provide fast, reliable and affordable faucet repairs for homes and businesses, using professional tools and techniques.";
  static const serviceBenefits =
      "✅ Fast and efficient service\n✅ Affordable pricing\n✅ Experienced, licensed plumbers";
  static const booking =
      "Book your service today and say goodbye to leaks! Call [phone number] or visit [website].";
  static const hashtagsHeading = "Hashtags / keywords:";
  static const hashtags =
      "#Plumbing #FaucetRepair #LeakRepair #EmergencyPlumber #PipeRepair #HomeMaintenance #LocalPlumber";
  static const callToActionHeading = "Call to action:";
  static const callToAction =
      "Call now to arrange your faucet repair and enjoy a leak-free home!";
  static const featuresHeading = "Specifications";
  static const features = <(String, String)>[
    ('Brand', 'Apple, Samsung, Xiaomi'),
    ('Model', 'iPhone 15 Pro'),
    ('Release year', '2024'),
    ('Condition', 'New, used'),
    ('Colour', 'Black, silver, blue'),
    ('Body material', 'Aluminium, glass, plastic'),
    ('Weight', '187 g'),
    ('Dimensions', '146.6 × 70.6 × 7.8 mm'),
  ];

  // Creation flow, dialogs and post analytics.
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
  static const unitPiece = "Piece";
  static const unitItem = "Item";
  static const unitHour = "Hour";
  static const unitDay = "Day";
  static const unitSession = "Session";
  static const unitProject = "Project";
  static const unitMeter = "Meter";
  static const unitCentimeter = "Centimeter";
  static const unitKilogram = "Kilogram";
  static const unitSet = "Set";
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
  static const addressPinRequired =
      "Enter an address and tap the map to choose its location.";
  static const chooseMapLocation =
      "Tap the map to select an exact location. The initial map is centered on Tehran.";
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
  static const publishDetailsRequired =
      "Add media, post type, title, and caption before publishing.";
  static const invalidPrice = "Enter a valid price.";
  static const invalidDiscount = "Discount must be between 0 and 100.";
  static const invalidStock =
      "Stock must be a whole number greater than or equal to zero.";
  static const mediaUnavailable =
      "A selected photo or video is unavailable. Select it again.";
  static const storagePluginUnavailable =
      "Storage or gallery is not ready. Restart the app; rebuild if needed. Your draft is preserved.";
  static const mediaExportFailed =
      "Could not retrieve the selected media. Open it in Photos to download it, then try again. Your draft is preserved.";
  static const savedPostsLoadFailed = "Could not load saved posts.";
  static const savePostFailed =
      "Could not save the post. Your draft is preserved. Please try again.";
  static const analytics = "Post analytics";
  static const viewAnalytics = "View analytics";
  static const onThisDevice = "On this device";
  static const sampleData = "Sample data";
  static const analyticsSaveFailed =
      "Session analytics are available, but could not be saved.";
  static const totalViews = "Total views";
  static const interactions = "Interactions";
  static const clicksInteractions = "Clicks and interactions";
  static const averageTimeViewed = "Average viewing time";
  static const impressions = "Impressions";
  static const views = "Views";
  static const totalOrdersBookings = "Total orders and bookings";
  static const dailyAverage = "Daily average";
  static const sampleHours = "8 hours";
  static const thisPeriod = "This period";
  static const previousPeriod = "Previous period";
  static const likesShares = "Likes / shares";
  static const savesComments = "Saves / comments";
  static const other = "Other";
  static const oneMonth = "1 month";
  static const threeMonths = "3 months";
  static const sixMonths = "6 months";
  static const twelveMonths = "12 months";
  static const january = "January";
  static const february = "February";
  static const march = "March";
  static const april = "April";
  static const may = "May";
  static const june = "June";
  static const july = "July";
  static const august = "August";
  static const september = "September";
  static const october = "October";
  static const november = "November";
  static const december = "December";

  static const sampleProducts = [
    'Product 1',
    'Product 2',
    'Product 3',
    'Product 4',
  ];
  static const sampleDate = "06/05/2023";
  static const sampleTotal = "4,500.00 USD";
  static const sampleFirst = "2,500.00 USD";
  static const sampleSecond = "1,400.00 USD";
  static const sampleThird = "450.00 USD";
  static const sampleFourth = "400.00 USD";
  static const sampleRevenue = "20,678.89 USD";
  static const sampleChange = "−1.5%";
  static const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const sampleWeekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const hours = "hours";
  static const ordersBookings = "Order / booking";
  static String descriptionCount(int count) =>
      '${persianDigits(count)} descriptions';
  static String featureCount(int count) =>
      '${persianDigits(count)} specifications';
  static String removeFeature(String name) => 'Remove $name';
  static String mapPin(double latitude, double longitude) =>
      'Coordinates: ${persianDigits(latitude.toStringAsFixed(5))}, ${persianDigits(longitude.toStringAsFixed(5))}';
  static String scheduledFor(String date) => 'Scheduled for: $date';
  static String analyticsPeriod(String title) => '$title period';
  static String viewCount(String value) => '$value views';
  static String impressionCount(String value) => '$value impressions';
  static String interactionCount(String value) => '$value interactions';
  static String averageMinutes(String value) => 'Average $value minutes';
  static String averageSeconds(String value) => 'Average $value seconds';
  static String seconds(String value) => '$value seconds';
  static String chartHelp(bool area) =>
      '${area ? totalViews : interactions} chart. Tap or drag to view values.';

  /// Old locally saved posts can still contain the original English category.
  static String postCategory(String category) => switch (category) {
    'Product' || 'محصول' => product,
    'Services' || 'خدمات' => services,
    _ => category,
  };

  // Bundled demo contacts and messages, also used by the call preview headers.
  static const chatSupportName = "Support";
  static const demoObidName = "Obid Amati";
  static const demoSarahName = "Sarah Ahmed";
  static const demoAlexName = "Alex Morgan";
  static const demoDavidName = "David Wilson";
  static const demoNinaName = "Nina Parker";
  static const demoJamesName = "James Carter";
  static const demoSupportPreview = "How can we help you today?";
  static const demoThanksPreview = "Thanks for your message.";
  static const demoDetailsPreview = "I will send you the details.";
  static const demoAvailabilityPreview = "Is this product still available?";
  static const demoPricePreview = "Can we discuss the price?";
  static const demoSoundsGoodPreview = "Sounds good, thank you!";
  static const demoSoonPreview = "I will reply soon.";
  static const demoMoreInfoPreview = "Please send more information.";
  static const demoAskAvailability = "Hello! Is this item still available?";
  static const demoConfirmAvailability = "Hello! Yes, it is available.";
  static const demoAskDetails = "Could you share more details?";
  static const demoShareDetails = "Of course! I will send all the details.";
  static const demoThankYou = "That would be great. Thank you!";

  static String chatFileSize(int bytes) => bytes >= 1048576
      ? '${persianDigits((bytes / 1048576).toStringAsFixed(1))} MB'
      : '${persianDigits((bytes / 1024).ceil())} KB';

  /// Display-only file labels; extensions and original filenames stay intact.
  static String fileTypeLabel(String extension) =>
      switch (extension.toUpperCase()) {
        'PDF' || 'DOC' || 'DOCX' || 'TXT' || 'RTF' || 'ODT' => document,
        'JPG' ||
        'JPEG' ||
        'PNG' ||
        'GIF' ||
        'HEIC' ||
        'HEIF' ||
        'WEBP' ||
        'BMP' ||
        'SVG' => photo,
        'MP4' || 'MKV' || 'MOV' || 'AVI' || 'WEBM' || 'M4V' => video,
        'M4A' || 'AAC' || 'MP3' || 'WAV' || 'OGG' || 'FLAC' => 'Audio',
        'ZIP' || 'RAR' || '7Z' || 'TAR' || 'GZ' => 'Archive',
        'XLS' || 'XLSX' || 'CSV' || 'ODS' => 'Spreadsheet',
        'PPT' || 'PPTX' || 'ODP' => 'Presentation',
        _ => genericFile,
      };

  // Chat controls and messages.
  static const chat = "Chats";
  static const chatOptions = "Chat options";
  static const showAllChats = "Show all chats";
  static const unreadChats = "Unread chats";
  static const markAllRead = "Mark all as read";
  static const noUnreadChats = "No unread chats";
  static const noChatsFound = "No chats found";
  static const noMessages = "No messages yet";
  static const startChatting = "Send a message to start chatting";
  static const messageHint = "Message";
  static const sendMessage = "Send message";
  static const emoji = "Emoji";
  static const keyboard = "Keyboard";
  static const noRecentEmoji = "No recent emoji";
  static const attachments = "Attachments";
  static const document = "Document";
  static const camera = "Camera";
  static const gallery = "Gallery";
  static const cameraAccessDenied =
      "Allow camera access in your device settings.";
  static const cameraCaptureFailed = "Could not take the photo. Try again.";
  static const sendLocation = "Send location";
  static const openLocation = "Open in Maps";
  static const locationOpenFailed = "Could not open Maps. Try again.";
  static String sendSelectedAttachments(int count) =>
      'Send (${persianDigits(count)})';
  static const attachFile = "Attach file";
  static const photosVideos = "Photos and videos";
  static const voiceMessage = "Voice message";
  static const recordVoice = "Record voice message";
  static const stopRecording = "Stop recording";
  static const recording = "Recording";
  static const recordingPreview = "Recording preview";
  static const microphoneDenied =
      "Allow microphone access in your device settings to record a voice message.";
  static const recordingFailed =
      "Could not record your voice message. Try again.";
  static const recordingTooShort =
      "The voice message is too short. Record for a little longer.";
  static const mediaSendFailed = "Could not send the attachment. Try again.";
  static const audioPlaybackFailed = "Could not play the audio. Try again.";
  static const fileOpenFailed =
      "Could not open this file. Check that a suitable app is installed.";
  static const playVoice = "Play voice message";
  static const pauseVoice = "Pause voice message";
  static const sendingAttachment = "Preparing attachment…";
  static const selectMessages = "Select messages";
  static const deleteMessages = "Delete messages";
  static const deleteSelectedMessages = "Delete selected messages";
  static const selectMessagesHelp = "Tap messages to select them";
  static const selectAllMessages = "Select all messages";
  static const delete = "Delete";
  static const clearConversation = "Clear conversation";
  static const clearConversationQuestion =
      "Clear all messages in this conversation?";
  static const localDeleteHelp =
      "Messages will only be removed from this device.";
  static const blockPerson = "Block user";
  static const unblockPerson = "Unblock user";
  static const blockQuestion = "Block this user?";
  static const blockHelp =
      "You cannot send messages or attachments until you unblock this user.";
  static const personBlocked = "You have blocked this user.";
  static const blocked = "Blocked";
  static const copiedMessage = "Message copied";
  static const copyMessage = "Copy message";
  static const audioCall = "Audio call";
  static const videoCall = "Video call";
  // Call screen previews; no media is captured or transmitted.
  static const callPreview = "Call preview";
  static const incomingCall = "Incoming call…";
  static const outgoingCall = "Calling…";
  static const callConnecting = "Connecting…";
  static const callEnded = "Call ended";
  static const callFailed = "Could not connect the call";
  static const callControlFailed =
      "Could not change the call setting. Try again.";
  static const answerCall = "Answer";
  static const declineCall = "Decline";
  static const endCall = "End call";
  static const returnToChat = "Back to chat";
  static const muteCall = "Mute microphone";
  static const unmuteCall = "Unmute microphone";
  static const speakerOn = "Turn speaker on";
  static const speakerOff = "Turn speaker off";
  static const turnCameraOff = "Turn camera off";
  static const turnCameraOn = "Turn camera on";
  static const switchCamera = "Switch camera";
  static const frontCamera = "Front camera";
  static const rearCamera = "Rear camera";
  static const cameraOff = "Camera is off";
  static const you = "You";
  static const showCallOptions = "Show call options";
  static const hideCallOptions = "Hide call options";
  static String selectedMessages(int count) =>
      '${persianDigits(count)} messages selected';
  static String deleteMessageQuestion(int count) =>
      'Delete ${persianDigits(count)} messages?';
  static String unreadMessageCount(int count) =>
      '${persianDigits(count)} unread messages';
  static String chatTime(Duration value) => persianDigits(
    '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}',
  );

  static String inStock(int count) => '${persianDigits(count)} in stock';

  /// English display digits for development; keep the existing helper API.
  static String persianDigits(Object value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var result = value.toString();
    for (var digit = 0; digit < 10; digit++) {
      result = result
          .replaceAll(persian[digit], '$digit')
          .replaceAll(arabic[digit], '$digit');
    }
    return result
        .replaceAll('٬', ',')
        .replaceAll('٫', '.')
        .replaceAll('٪', '%');
  }
}
