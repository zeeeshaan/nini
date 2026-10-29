import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/features/create_post/domain/validation/post_draft_validator.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_textfield/app_text_field.dart';

void main() {
  test(
    'Legacy metadata round-trips losslessly while exposing typed details',
    () {
      final metadata = <String, dynamic>{
        'caption': 'Original caption متن',
        'captionDelta': [
          {
            'insert': 'Original caption متن\n',
            'attributes': {'bold': true},
          },
        ],
        'tags': ['Handmade', 'دست‌ساز'],
        'address': {
          'address': 'Saved address',
          'latitude': 35,
          'longitude': 51.25,
        },
        'schedule': {
          'startsAt': '2027-02-04T10:00:00+05:00',
          'endsAt': '2027-02-04T11:00:00+05:00',
        },
        'features': [
          {'name': 'Material', 'value': 'Steel'},
        ],
        'warehouseStock': '۱۲',
        'discount': '۲۰',
        'unit': 'hour',
        'altTexts': {'asset:one': 'Image description'},
        'unknownFutureField': {
          'keep': [1, 'value'],
        },
      };
      final json = <String, dynamic>{
        'id': 'existing',
        'title': 'Original title',
        'imageAsset': '',
        'category': 'Product',
        'stockCount': 12,
        'price': '123',
        'originalPrice': '150',
        'media': [],
        'metadata': metadata,
        'publishedAt': '2026-10-29T07:00:00.000Z',
      };
      final post = PostItem.fromJson(json);
      expect(post.details.address!.latitude, 35);
      expect(post.details.address!.address, 'Saved address');
      expect(
        post.details.schedule!.startsAt.toUtc(),
        DateTime.utc(2027, 2, 4, 5),
      );
      expect(post.details.tags, ['Handmade', 'دست‌ساز']);
      expect(post.details.features.single.name, 'Material');
      expect(post.details.altTexts['asset:one'], 'Image description');
      expect(post.caption, metadata['caption']);
      expect(post.features, [('Material', 'Steel')]);
      expect(post.toJson(), json);
      expect(post.metadata, metadata);
    },
  );

  test(
    'Const metadata callers and typed callers preserve the same accessors',
    () {
      const legacy = PostItem(
        id: 'legacy',
        imageAsset: '',
        title: '',
        category: '',
        stockCount: 0,
        price: '',
        originalPrice: '',
        metadata: {'caption': 'Existing caption'},
      );
      const typed = PostItem(
        id: 'typed',
        imageAsset: '',
        title: '',
        category: '',
        stockCount: 0,
        price: '',
        originalPrice: '',
        details: PostDetails(caption: 'Existing caption'),
      );
      expect(legacy.caption, typed.caption);
      expect(legacy.details.address, isNull);
      expect(legacy.features, isEmpty);
      expect(legacy.metadata, {'caption': 'Existing caption'});
      expect(PostItem.fromJson(typed.toJson()).caption, typed.caption);
    },
  );

  test(
    'Publishing validation keeps error precedence and schedule boundaries',
    () {
      final now = DateTime(2026, 10, 29, 12);
      PostDraftIssue? validate(PostDraft draft, {bool attachments = true}) =>
          PostDraftValidator.forPublishing(
            draft,
            hasAttachments: attachments,
            now: now,
          );
      const empty = PostDraft();
      expect(
        validate(empty, attachments: false),
        PostDraftIssue.missingAttachment,
      );
      expect(validate(empty), PostDraftIssue.missingPostType);
      final typed = empty.copyWith(postType: CreatePostType.product);
      expect(validate(typed), PostDraftIssue.missingTitle);
      final titled = typed.copyWith(title: 'A title');
      expect(validate(titled), PostDraftIssue.missingCaption);
      final complete = titled.copyWith(caption: 'Caption');
      expect(validate(complete), isNull);
      final scheduled = complete.copyWith(
        schedule: PostSchedule(
          startsAt: now,
          endsAt: now.add(const Duration(hours: 1)),
        ),
      );
      expect(validate(scheduled), PostDraftIssue.scheduleInPast);
      expect(
        validate(
          complete.copyWith(
            schedule: PostSchedule(
              startsAt: now.add(const Duration(seconds: 1)),
              endsAt: now.add(const Duration(hours: 1)),
            ),
          ),
        ),
        isNull,
      );
    },
  );

  testWidgets('Text field keeps its RTL default and supports explicit LTR', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppTextField(),
              AppTextField(textDirection: TextDirection.ltr),
            ],
          ),
        ),
      ),
    );
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    // TextFormField forwards direction to its inner TextField.
    expect(fields, hasLength(2));
    final inputs = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(inputs.first.textDirection, TextDirection.rtl);
    expect(inputs.last.textDirection, TextDirection.ltr);
  });
}
