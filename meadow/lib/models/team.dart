class Team {
  final String id;
  final String name;
  final List<String> memberIds; // user ids

  Team({
    required this.id,
    required this.name,
    required this.memberIds,
  });
}
