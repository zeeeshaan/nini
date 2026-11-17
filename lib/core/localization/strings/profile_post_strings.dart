import 'package:nini/core/localization/app_string/app_string.dart';

/// English interface copy for profile tabs and post editing. Model IDs and serialized
/// enum names stay independent of the labels displayed in the UI.
abstract final class ProfilePostStrings {
  static const tabs = "Categories";
  static const back = AppStrings.back;
  static const undo = AppStrings.undo;
  static const redo = AppStrings.redo;
  static const unitNames = {
    'piece': AppStrings.unitPiece,
    'item': AppStrings.unitItem,
    'hour': AppStrings.unitHour,
    'day': AppStrings.unitDay,
    'session': AppStrings.unitSession,
    'project': AppStrings.unitProject,
    'meter': AppStrings.unitMeter,
    'centimeter': AppStrings.unitCentimeter,
    'kilogram': AppStrings.unitKilogram,
    'set': AppStrings.unitSet,
  };
  static String preparationDays(int days) =>
      '${AppStrings.persianDigits(days)} days';
  static const all = AppStrings.all;
  static const addTab = "Add category";
  static const editTab = "Edit category";
  static const deleteTab = "Delete category";
  static const tabName = "Category name";
  static const cancel = AppStrings.cancel;
  static const done = AppStrings.done;
  static const delete = AppStrings.delete;
  static const retry = AppStrings.retry;
  static const category = "Profile category";
  static const allOnly = "All only (no category)";
  static const manageTabs = "Manage categories";
  static const noTabs = "No categories yet. Add one to organise your posts.";
  static const noPosts = "No posts in this category yet.";
  static const noPublishedPosts = 'No posts have been published yet';
  static const publicProfile = 'Profile unavailable';
  static const publicIdentityMissing =
      'This post does not include an available backend username.';
  static const publicUnavailable = 'This profile is unavailable.';
  static const publicLoadFailed =
      'Could not load this profile. Please try again.';
  static const publicConnectionFailed =
      'Could not connect. Check your connection and try again.';
  static const publicTimeout =
      'The profile request timed out. Please try again.';
  static const publicSessionFailed =
      'Your session could not be verified. Please sign in again.';
  static const publicSessionChanged =
      'Your account changed. Reload this profile to continue.';
  static const publicPostsUnavailable =
      "This user's posts and services are not available here yet.";
  static const followUnavailable = 'Follow and unfollow are not available yet.';
  static const loadFailed = "Could not load categories. Try again.";
  static const saveFailed = "Could not save changes. Try again.";
  static const nameRequired = "Enter a category name.";
  static const nameTooLong = "Category names must be at most 50 characters.";
  static const duplicateName = "A category with this name already exists.";
  static const reservedName =
      "All is a permanent section. Choose another name.";
  static const editPost = "Edit post";
  static const deletePost = "Delete post";
  static const deletePostQuestion = "Delete this post?";
  static const deletePostHelp =
      "This post and its media will be permanently removed from your Posts.";
  static const deleting = "Deleting…";
  static const deleteFailed = "Could not delete the post. Try again.";
  static const addMedia = "Add media";
  static const removeMedia = "Remove media";
  static const mediaRequired = "Select at least one photo, video or file.";
  static const mediaUnavailable = "Some media is unavailable. Select it again.";
  static const saveChanges = "Save changes";
  static const saving = "Saving…";
  static const postMissing = "This post is no longer available.";
  static const media = "Media";
  static const replaceMedia = "Replace media";
  static const next = AppStrings.next;
  static const title = "Title";
  static const caption = AppStrings.postCaption;
  static const captionHint = AppStrings.writeCaption;
  static const type = AppStrings.postType;
  static const product = AppStrings.product;
  static const service = AppStrings.services;
  static const price = "Price (toman)";
  static const discount = "Discount (%)";
  static const stock = "Stock";
  static const unit = AppStrings.unit;
  static const preparation = AppStrings.preparationTime;
  static const noPreparation = "No preparation time";
  static const sameDay = "Same day";
  static const inventory = "Inventory status";
  static const inStock = AppStrings.stockAvailable;
  static const outOfStock = AppStrings.stockUnavailable;
  static const preOrder = AppStrings.preOrder;
  static const tags = "Tags (separate with commas)";
  static const address = AppStrings.address;
  static const latitude = "Latitude";
  static const longitude = "Longitude";
  static const features = AppStrings.featuresHeading;
  static const featureName = "Specification name";
  static const featureValue = AppStrings.featureValue;
  static const addFeature = AppStrings.addFeature;
  static const removeFeature = "Remove specification";
  static const schedule = "Schedule";
  static const start = "Start";
  static const end = "End";
  static const clearSchedule = AppStrings.removeSchedule;
  static const altText = AppStrings.altText;
  static const required = "Complete this field.";
  static const invalidNumber =
      "Enter a valid number greater than or equal to zero.";
  static const invalidDiscount = "Enter a number between 0 and 100.";
  static const invalidStock =
      "Enter a whole number greater than or equal to zero.";
  static const invalidLocation =
      "Enter an address and valid latitude and longitude.";
  static const invalidFeatures =
      "Enter a name and value for every specification.";
  static const invalidSchedule =
      "Choose a future start time and an end time after the start.";
  static const unsavedTitle = "Discard changes?";
  static const unsavedHelp = "Your unsaved changes will be lost.";
  static const keepEditing = "Keep editing";
  static const discard = "Discard";
  static String deleteQuestion(String name) => 'Remove the "$name" category?';
  static const deleteHelp =
      "Posts in this category will remain visible under All.";

  /// Translate only the original bundled names. Custom user names stay intact,
  /// including renamed default tabs and names written in other languages.
  static String categoryName(String id, String name) => switch ((id, name)) {
    ('web-development', 'Web Development') => AppStrings.webDevelopment,
    ('electrical-wiring', 'Electrical Wiring') => AppStrings.electricalWiring,
    ('products', 'Products') => AppStrings.products,
    ('photography', 'Photography') => AppStrings.photography,
    _ => name,
  };
}
