import 'package:flutter/widgets.dart';

import 'profile_post_strings.dart';

/// Category copy shared by Create Post and Profile.
class CategoryStrings {
  const CategoryStrings(this.english);
  factory CategoryStrings.of(BuildContext context) =>
      CategoryStrings(Localizations.localeOf(context).languageCode == 'en');
  final bool english;

  String name(String id, String name) =>
      english ? name : ProfilePostStrings.categoryName(id, name);
  String deleteQuestion(String name) => english
      ? 'دسته‌بندی «$name» حذف شود؟'
      : ProfilePostStrings.deleteQuestion(name);
  String text(String message) => !english
      ? message
      : switch (message) {
          ProfilePostStrings.tabs => "دسته‌بندی‌ها",
          ProfilePostStrings.addTab => "افزودن دسته‌بندی",
          ProfilePostStrings.editTab => "ویرایش دسته‌بندی",
          ProfilePostStrings.deleteTab => "حذف دسته‌بندی",
          ProfilePostStrings.tabName => "نام دسته‌بندی",
          ProfilePostStrings.cancel => "انصراف",
          ProfilePostStrings.done => "تأیید",
          ProfilePostStrings.delete => "حذف",
          ProfilePostStrings.saving => "در حال ذخیره…",
          ProfilePostStrings.retry => "تلاش دوباره",
          ProfilePostStrings.noTabs => "هنوز دسته‌بندی‌ای ندارید. برای مرتب کردن پست‌ها، یک دسته‌بندی اضافه کنید.",
          ProfilePostStrings.loadFailed =>
            "بارگذاری دسته‌بندی‌ها انجام نشد. دوباره تلاش کنید.",
          ProfilePostStrings.saveFailed =>
            "ذخیره تغییرات انجام نشد. دوباره تلاش کنید.",
          ProfilePostStrings.nameRequired => "نام دسته‌بندی را وارد کنید.",
          ProfilePostStrings.nameTooLong =>
            "نام دسته‌بندی باید حداکثر ۵۰ نویسه داشته باشد.",
          ProfilePostStrings.duplicateName =>
            "دسته‌بندی‌ای با این نام وجود دارد.",
          ProfilePostStrings.reservedName =>
            "«همه» یک بخش دائمی است. نام دیگری انتخاب کنید.",
          ProfilePostStrings.deleteHelp => "پست‌های این دسته‌بندی حفظ می‌شوند و در بخش «همه» قابل مشاهده خواهند بود.",
          _ => message,
        };
}
