enum TournamentPhase {
  setup,
  league,
  knockout,
  complete,
}

enum MatchStage {
  league,
  quarterfinal,
  semifinal,
  finalMatch,
}

String phaseLabel(TournamentPhase phase) {
  switch (phase) {
    case TournamentPhase.setup:
      return 'Setup';
    case TournamentPhase.league:
      return 'League';
    case TournamentPhase.knockout:
      return 'Knockout';
    case TournamentPhase.complete:
      return 'Complete';
  }
}

String stageLabel(MatchStage stage) {
  switch (stage) {
    case MatchStage.league:
      return 'League';
    case MatchStage.quarterfinal:
      return 'Quarter Finals';
    case MatchStage.semifinal:
      return 'Semi Finals';
    case MatchStage.finalMatch:
      return 'Final';
  }
}

String _phaseToJson(TournamentPhase phase) => phase.name;

TournamentPhase _phaseFromJson(String? value) {
  return TournamentPhase.values.firstWhere(
    (phase) => phase.name == value,
    orElse: () => TournamentPhase.setup,
  );
}

String _stageToJson(MatchStage stage) => stage.name;

MatchStage _stageFromJson(String? value) {
  return MatchStage.values.firstWhere(
    (stage) => stage.name == value,
    orElse: () => MatchStage.league,
  );
}

class Player {
  const Player({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Player copyWith({String? id, String? name}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  static Player fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class Team {
  const Team({
    required this.id,
    required this.playerOneId,
    required this.playerTwoId,
  });

  final String id;
  final String playerOneId;
  final String playerTwoId;

  String name(List<Player> players) {
    final playerOne = playerName(players, playerOneId);
    final playerTwo = playerName(players, playerTwoId);
    return '$playerOne / $playerTwo';
  }

  bool containsPlayer(String playerId) {
    return playerOneId == playerId || playerTwoId == playerId;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerOneId': playerOneId,
        'playerTwoId': playerTwoId,
      };

  static Team fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      playerOneId: json['playerOneId'] as String,
      playerTwoId: json['playerTwoId'] as String,
    );
  }
}

class TournamentMatch {
  const TournamentMatch({
    required this.id,
    required this.stage,
    required this.teamAId,
    required this.teamBId,
    required this.order,
    this.scoreA,
    this.scoreB,
  });

  final String id;
  final MatchStage stage;
  final String teamAId;
  final String teamBId;
  final int order;
  final int? scoreA;
  final int? scoreB;

  bool get hasScore => scoreA != null && scoreB != null;
  bool get isCompleted => hasScore && scoreA != scoreB;

  String? get winnerId {
    if (!isCompleted) return null;
    return scoreA! > scoreB! ? teamAId : teamBId;
  }

  String? get loserId {
    if (!isCompleted) return null;
    return scoreA! > scoreB! ? teamBId : teamAId;
  }

  TournamentMatch copyWith({
    String? id,
    MatchStage? stage,
    String? teamAId,
    String? teamBId,
    int? order,
    int? scoreA,
    int? scoreB,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      order: order ?? this.order,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
    );
  }

  TournamentMatch withScore(int scoreA, int scoreB) {
    return copyWith(scoreA: scoreA, scoreB: scoreB);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stage': _stageToJson(stage),
        'teamAId': teamAId,
        'teamBId': teamBId,
        'order': order,
        'scoreA': scoreA,
        'scoreB': scoreB,
      };

  static TournamentMatch fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      stage: _stageFromJson(json['stage'] as String?),
      teamAId: json['teamAId'] as String,
      teamBId: json['teamBId'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      scoreA: (json['scoreA'] as num?)?.toInt(),
      scoreB: (json['scoreB'] as num?)?.toInt(),
    );
  }
}

class TeamStanding {
  const TeamStanding({
    required this.team,
    required this.played,
    required this.wins,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  final Team team;
  final int played;
  final int wins;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;

  int get pointDifference => pointsFor - pointsAgainst;
  int get leaguePoints => wins * 2;
}

class TournamentState {
  const TournamentState({
    required this.phase,
    required this.players,
    required this.teams,
    required this.leagueMatches,
    required this.knockoutMatches,
    this.championTeamId,
  });

  factory TournamentState.empty() {
    return const TournamentState(
      phase: TournamentPhase.setup,
      players: [],
      teams: [],
      leagueMatches: [],
      knockoutMatches: [],
    );
  }

  final TournamentPhase phase;
  final List<Player> players;
  final List<Team> teams;
  final List<TournamentMatch> leagueMatches;
  final List<TournamentMatch> knockoutMatches;
  final String? championTeamId;

  bool get isLeagueComplete {
    return leagueMatches.isNotEmpty &&
        leagueMatches.every((match) => match.isCompleted);
  }

  int get qualifierCount {
    if (teams.length < 2) return 0;
    if (teams.length <= 4) return 2;
    if (teams.length <= 8) return 4;
    return 8;
  }

  MatchStage get firstKnockoutStage {
    switch (qualifierCount) {
      case 8:
        return MatchStage.quarterfinal;
      case 4:
        return MatchStage.semifinal;
      default:
        return MatchStage.finalMatch;
    }
  }

  MatchStage? get activeKnockoutStage {
    const stages = [
      MatchStage.quarterfinal,
      MatchStage.semifinal,
      MatchStage.finalMatch,
    ];

    for (final stage in stages) {
      final matches =
          knockoutMatches.where((match) => match.stage == stage).toList();
      if (matches.isNotEmpty && matches.any((match) => !match.isCompleted)) {
        return stage;
      }
    }
    return null;
  }

  TournamentState copyWith({
    TournamentPhase? phase,
    List<Player>? players,
    List<Team>? teams,
    List<TournamentMatch>? leagueMatches,
    List<TournamentMatch>? knockoutMatches,
    String? championTeamId,
    bool clearChampion = false,
  }) {
    return TournamentState(
      phase: phase ?? this.phase,
      players: players ?? this.players,
      teams: teams ?? this.teams,
      leagueMatches: leagueMatches ?? this.leagueMatches,
      knockoutMatches: knockoutMatches ?? this.knockoutMatches,
      championTeamId:
          clearChampion ? null : championTeamId ?? this.championTeamId,
    );
  }

  List<String> get assignedPlayerIds {
    return teams
        .expand((team) => [team.playerOneId, team.playerTwoId])
        .toList();
  }

  List<Player> get unassignedPlayers {
    final assigned = assignedPlayerIds.toSet();
    return players.where((player) => !assigned.contains(player.id)).toList();
  }

  Team? teamById(String id) {
    for (final team in teams) {
      if (team.id == id) return team;
    }
    return null;
  }

  String teamName(String id) {
    return teamById(id)?.name(players) ?? 'Unknown team';
  }

  List<TeamStanding> standings() {
    final stats = <String, _MutableStanding>{};
    for (final team in teams) {
      stats[team.id] = _MutableStanding(team);
    }

    for (final match in leagueMatches.where((match) => match.isCompleted)) {
      final teamA = stats[match.teamAId];
      final teamB = stats[match.teamBId];
      if (teamA == null || teamB == null) continue;

      teamA.played += 1;
      teamB.played += 1;
      teamA.pointsFor += match.scoreA!;
      teamA.pointsAgainst += match.scoreB!;
      teamB.pointsFor += match.scoreB!;
      teamB.pointsAgainst += match.scoreA!;

      if (match.scoreA! > match.scoreB!) {
        teamA.wins += 1;
        teamB.losses += 1;
      } else {
        teamB.wins += 1;
        teamA.losses += 1;
      }
    }

    final ordered = stats.values.map((value) => value.toStanding()).toList();
    ordered.sort((a, b) {
      final byLeaguePoints = b.leaguePoints.compareTo(a.leaguePoints);
      if (byLeaguePoints != 0) return byLeaguePoints;
      final byWins = b.wins.compareTo(a.wins);
      if (byWins != 0) return byWins;
      final byDifference = b.pointDifference.compareTo(a.pointDifference);
      if (byDifference != 0) return byDifference;
      final byScored = b.pointsFor.compareTo(a.pointsFor);
      if (byScored != 0) return byScored;
      return a.team.name(players).compareTo(b.team.name(players));
    });
    return ordered;
  }

  Map<String, dynamic> toJson() => {
        'phase': _phaseToJson(phase),
        'players': players.map((player) => player.toJson()).toList(),
        'teams': teams.map((team) => team.toJson()).toList(),
        'leagueMatches': leagueMatches.map((match) => match.toJson()).toList(),
        'knockoutMatches':
            knockoutMatches.map((match) => match.toJson()).toList(),
        'championTeamId': championTeamId,
      };

  static TournamentState? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return TournamentState(
        phase: _phaseFromJson(json['phase'] as String?),
        players: (json['players'] as List? ?? [])
            .map((value) =>
                Player.fromJson(Map<String, dynamic>.from(value as Map)))
            .toList(),
        teams: (json['teams'] as List? ?? [])
            .map((value) =>
                Team.fromJson(Map<String, dynamic>.from(value as Map)))
            .toList(),
        leagueMatches: (json['leagueMatches'] as List? ?? [])
            .map((value) => TournamentMatch.fromJson(
                Map<String, dynamic>.from(value as Map)))
            .toList(),
        knockoutMatches: (json['knockoutMatches'] as List? ?? [])
            .map((value) => TournamentMatch.fromJson(
                Map<String, dynamic>.from(value as Map)))
            .toList(),
        championTeamId: json['championTeamId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

String playerName(List<Player> players, String playerId) {
  for (final player in players) {
    if (player.id == playerId) return player.name;
  }
  return 'Unknown player';
}

class _MutableStanding {
  _MutableStanding(this.team);

  final Team team;
  int played = 0;
  int wins = 0;
  int losses = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;

  TeamStanding toStanding() {
    return TeamStanding(
      team: team,
      played: played,
      wins: wins,
      losses: losses,
      pointsFor: pointsFor,
      pointsAgainst: pointsAgainst,
    );
  }
}
