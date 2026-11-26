import 'package:hywork/features/team/domain/team_provider_selection.dart';
import 'package:hywork/features/team/domain/team_request.dart';
import 'package:hywork/shared/models/post/post_attributes.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

/// A paid team preview. The original paid request remains unchanged when its
/// working group is edited later.
class TeamWorkspace {
  TeamWorkspace({
    required this.id,
    required this.name,
    required this.description,
    required this.owner,
    required this.request,
    required this.createdAt,
    required List<TeamProviderSelection> providers,
    List<PostAddress> locations = const [],
  }) : providers = List.unmodifiable(providers),
       locations = List.unmodifiable(locations);

  final String id, name, description;
  final PostSeller owner;
  final TeamRequest request;
  final DateTime createdAt;
  final List<TeamProviderSelection> providers;
  final List<PostAddress> locations;

  String get conversationId => 'team-$id';
  List<PostSeller> get members => List.unmodifiable(
    {
      owner.id: owner,
      for (final selection in providers)
        selection.provider.id: selection.provider,
    }.values,
  );

  TeamWorkspace copyWith({
    String? name,
    String? description,
    List<TeamProviderSelection>? providers,
  }) => TeamWorkspace(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    owner: owner,
    request: request,
    createdAt: createdAt,
    providers: providers ?? this.providers,
    locations: locations,
  );
}
