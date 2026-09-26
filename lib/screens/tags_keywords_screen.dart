import 'package:flutter/material.dart';
import '../widgets/pill_picker.dart';

/// Multi-select tags and keywords. Pops the selected tags as a
/// `List<String>`.
class TagsKeywordsScreen extends StatelessWidget {
  const TagsKeywordsScreen({super.key, this.initial = const []});

  final List<String> initial;

  static const suggestions = [
    'خدمات اسپا و سلامت',
    'پزشک',
    'طراحی گرافیک',
    'طراحی لوگو و برندینگ',
    'توسعه وب',
    'فیلم‌برداری و تولید ویدیو',
    'آرایشگر مردانه',
    'عکاسی',
    'تدریس خصوصی',
    'مشاوره کسب‌وکار',
    'ترجمه',
    'تعمیرات',
  ];

  @override
  Widget build(BuildContext context) {
    return PillPickerScreen(
      title: 'برچسب‌ها و کلیدواژه‌ها',
      options: suggestions,
      initial: initial,
      multi: true,
    );
  }
}
