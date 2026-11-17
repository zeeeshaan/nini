/// Labels and feedback for the profile editor.
abstract final class ProfileEditStrings {
  static const title = "Profile settings";
  static const name = "Name";
  static const lastName = "Last name";
  static const businessType = 'Shop / business type';
  static const nationality = "Nationality";
  static const city = 'City';
  static const username = "Username";
  static const email = "Email";
  static const birth = "Date of birth";
  static const clearBirthDate = 'Clear date';
  static const gender = "Gender";
  static const bio = "Bio";
  static const choosePhoto = "Choose profile photo";
  static const cropPhoto = 'Crop profile photo';
  static const photoError = 'Could not prepare your profile photo. Try again.';
  static const saved = 'Profile updated';
  static const saveFailed = 'Could not save your profile. Please try again.';
  static const loadFailed = 'Could not load your profile. Please try again.';
  static const photoUploadUnavailable =
      'The photo upload endpoint is unavailable (404). Your profile was not changed. Your edits and photo preview are still in the form.';
  static const photoUploadFailed =
      'The server did not confirm uploading your photo. Your profile was not changed. Try again.';
  static const invalidPhoto = 'Choose a JPG, PNG or WebP profile photo.';
  static const photoTooLarge = 'The profile photo must be no larger than 5 MB.';
  static const photoUploadLimited =
      'Too many photo uploads. Wait a few minutes and try again.';
  static const saveTextOnlyTitle = 'Save text changes only?';
  static const saveTextOnlyMessage =
      'The photo upload endpoint is unavailable. You can save your text changes separately and keep the selected photo preview here. The photo will not be uploaded.';
  static const saveTextOnly = 'Save text only';
  static const textSavedPhotoPending =
      'Profile text is saved. The selected photo has not been uploaded; its preview is still here.';
  static String fieldsNotConfirmed(
    Iterable<String> fields, {
    Iterable<String> confirmed = const [],
    bool verificationFailed = false,
  }) =>
      '${verificationFailed ? 'The update was acknowledged, but read-back verification failed. ' : ''}'
      '${confirmed.isEmpty ? '' : 'Confirmed by the server: ${confirmed.join(', ')}. '}'
      'The server did not confirm saving: ${fields.join(', ')}. Your unconfirmed edits are still in the form.';
  static String validationFields(Iterable<String> fields) =>
      'The server rejected: ${fields.join(', ')}. Check these values. Your edits are still in the form.';
  static String? fieldLabel(String field) => switch (field) {
    'name' || 'firstName' || 'lastName' => name,
    'username' => username,
    'email' => email,
    'nationality' => nationality,
    'businessType' => businessType,
    'bio' => bio,
    'city' => city,
    'birthDate' => birth,
    'gender' => gender,
    'avatarUrl' => 'Profile photo',
    _ => null,
  };
  static const invalidName = 'Your full name must be at most 80 characters.';
  static const invalidUsername =
      'Use 3–30 lowercase letters, numbers, underscores or dots for your username. An existing username cannot be cleared.';
  static const invalidBio = 'Your bio must be at most 500 characters.';
  static const invalidCity = 'Your city must be at most 80 characters.';
  static const invalidBusinessType =
      'Business type must contain 2–60 characters, or be left empty.';
  static const invalidGender =
      'Enter male, female or other, or leave gender empty.';
  static const usernameTaken = 'This username is already taken.';
  static const invalidFields =
      'The server rejected the profile update. Check the entered values and try again. Your edits are still in the form.';
  static const sessionExpired =
      'Your session has expired. Please sign in again.';
  static const connectionFailed =
      'Could not reach the server. Check your connection and try again.';
  static const timeout = 'The profile request timed out. Please try again.';
}
