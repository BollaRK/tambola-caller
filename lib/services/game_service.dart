import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

const _keyTournamentState = 'pickleball_tournament_state';

/// Owns tournament mutations and persists the current bracket locally.
class GameService {
  static final GameService _instance = GameService._();
  factory GameService() => _instance;
  GameService._();

  TournamentState? _state;
  TournamentState? get state => _state;

  Future<TournamentState> newTournament() async {
    _state = TournamentState.empty();
    await _persist();
    return _state!;
  }

  Future<TournamentState?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyTournamentState);
    if (stored == null || stored.isEmpty) {
      _state = null;
      return null;
    }

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      _state = TournamentState.fromJson(decoded);
      return _state;
    } catch (_) {
      _state = null;
      return null;
    }
  }

  Future<Player> addPlayer(String rawName) async {
    final current = _requireSetupState();
    final name = rawName.trim();
    if (name.isEmpty) {
      throw ArgumentError('Player name is required.');
    }
    final duplicate = current.players.any(
      (player) => player.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw ArgumentError('Player already exists.');
    }

    final player = Player(id: _nextId('player'), name: name);
    _state = current.copyWith(players: [...current.players, player]);
    await _persist();
    return player;
  }

  Future<void> removePlayer(String playerId) async {
    final current = _requireSetupState();
    _state = current.copyWith(
      players: current.players.where((player) => player.id != playerId).toList(),
      teams: current.teams.where((team) => !team.containsPlayer(playerId)).toList(),
    );
    await _persist();
  }

  Future<Team> addTeam(String playerOneId, String playerTwoId) async {
    final current = _requireSetupState();
    if (playerOneId == playerTwoId) {
      throw ArgumentError('Choose two different players.');
    }
    final playerIds = current.players.map((player) => player.id).toSet();
    if (!playerIds.contains(playerOneId) || !playerIds.contains(playerTwoId)) {
      throw ArgumentError('Both players must exist.');
    }
    final assigned = current.assignedPlayerIds.toSet();
    if (assigned.contains(playerOneId) || assigned.contains(playerTwoId)) {
      throw ArgumentError('One of these players already has a partner.');
    }

    final team = Team(
      id: _nextId('team'),
      playerOneId: playerOneId,
      playerTwoId: playerTwoId,
    );
    _state = current.copyWith(teams: [...current.teams, team]);
    await _persist();
    return team;
  }

  Future<void> removeTeam(String teamId) async {
    final current = _requireSetupState();
    _state = current.copyWith(
      teams: current.teams.where((team) => team.id != teamId).toList(),
    );
    await _persist();
  }

  Future<void> startLeague() async {
    final current = _requireSetupState();
    if (current.teams.length < 2) {
      throw StateError('Create at least two teams.');
    }
    if (current.unassignedPlayers.isNotEmpty) {
      throw StateError('Assign partners for every player before starting the league.');
    }

    final matches = <TournamentMatch>[];
    var order = 1;
    for (var i = 0; i < current.teams.length; i += 1) {
      for (var j = i + 1; j < current.teams.length; j += 1) {
        matches.add(
          TournamentMatch(
            id: 'league_${order}_${current.teams[i].id}_${current.teams[j].id}',
            stage: MatchStage.league,
            teamAId: current.teams[i].id,
            teamBId: current.teams[j].id,
            order: order,
          ),
        );
        order += 1;
      }
    }

    _state = current.copyWith(
      phase: TournamentPhase.league,
      leagueMatches: matches,
      knockoutMatches: [],
      clearChampion: true,
    );
    await _persist();
  }

  Future<void> saveLeagueScore(String matchId, int scoreA, int scoreB) async {
    _validateScore(scoreA, scoreB);
    final current = _state;
    if (current == null || current.phase != TournamentPhase.league) {
      throw StateError('League is not active.');
    }

    _state = current.copyWith(
      leagueMatches: current.leagueMatches.map((match) {
        if (match.id != matchId) return match;
        return match.withScore(scoreA, scoreB);
      }).toList(),
    );
    await _persist();
  }

  Future<void> startKnockout() async {
    final current = _state;
    if (current == null || current.phase != TournamentPhase.league) {
      throw StateError('League is not active.');
    }
    if (!current.isLeagueComplete) {
      throw StateError('Enter every league score first.');
    }

    final qualifiers = current.standings()
        .take(current.qualifierCount)
        .map((standing) => standing.team)
        .toList();
    final firstStage = current.firstKnockoutStage;
    final matches = _buildSeededMatches(qualifiers, firstStage);
    _state = current.copyWith(
      phase: TournamentPhase.knockout,
      knockoutMatches: matches,
      clearChampion: true,
    );
    await _persist();
  }

  Future<void> saveKnockoutScore(String matchId, int scoreA, int scoreB) async {
    _validateScore(scoreA, scoreB);
    final current = _state;
    if (current == null || current.phase != TournamentPhase.knockout) {
      throw StateError('Knockout stage is not active.');
    }

    var updatedMatches = current.knockoutMatches.map((match) {
      if (match.id != matchId) return match;
      return match.withScore(scoreA, scoreB);
    }).toList();
    var nextState = current.copyWith(knockoutMatches: updatedMatches);

    final activeStage = nextState.activeKnockoutStage;
    final scoredMatch = updatedMatches.firstWhere((match) => match.id == matchId);
    final stageMatches = updatedMatches.where((match) => match.stage == scoredMatch.stage).toList();
    final stageComplete = stageMatches.isNotEmpty && stageMatches.every((match) => match.isCompleted);

    if (stageComplete && activeStage == null) {
      if (scoredMatch.stage == MatchStage.finalMatch) {
        final finalMatch = stageMatches.first;
        nextState = nextState.copyWith(
          phase: TournamentPhase.complete,
          championTeamId: finalMatch.winnerId,
        );
      } else {
        final winners = stageMatches
            .map((match) => nextState.teamById(match.winnerId ?? ''))
            .whereType<Team>()
            .toList();
        final nextStage = _nextStageAfter(scoredMatch.stage);
        updatedMatches = [
          ...updatedMatches,
          ..._buildSeededMatches(winners, nextStage),
        ];
        nextState = nextState.copyWith(knockoutMatches: updatedMatches);
      }
    }

    _state = nextState;
    await _persist();
  }

  Future<void> clearSaved() async {
    _state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTournamentState);
  }

  bool get hasSavedGame => _state != null && _state!.phase != TournamentPhase.complete;

  TournamentState _requireSetupState() {
    final current = _state;
    if (current == null) {
      throw StateError('No tournament has been started.');
    }
    if (current.phase != TournamentPhase.setup) {
      throw StateError('Tournament setup is already complete.');
    }
    return current;
  }

  String _nextId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final count = (_state?.players.length ?? 0) +
        (_state?.teams.length ?? 0) +
        (_state?.leagueMatches.length ?? 0) +
        (_state?.knockoutMatches.length ?? 0);
    return '${prefix}_${now}_$count';
  }

  void _validateScore(int scoreA, int scoreB) {
    if (scoreA < 0 || scoreB < 0) {
      throw ArgumentError('Scores cannot be negative.');
    }
    if (scoreA == scoreB) {
      throw ArgumentError('Pickleball matches need a winner. Scores cannot be tied.');
    }
  }

  List<TournamentMatch> _buildSeededMatches(List<Team> seededTeams, MatchStage stage) {
    final matches = <TournamentMatch>[];
    var order = 1;
    for (var i = 0; i < seededTeams.length ~/ 2; i += 1) {
      final teamA = seededTeams[i];
      final teamB = seededTeams[seededTeams.length - 1 - i];
      matches.add(
        TournamentMatch(
          id: '${stage.name}_${order}_${teamA.id}_${teamB.id}',
          stage: stage,
          teamAId: teamA.id,
          teamBId: teamB.id,
          order: order,
        ),
      );
      order += 1;
    }
    return matches;
  }

  MatchStage _nextStageAfter(MatchStage stage) {
    switch (stage) {
      case MatchStage.quarterfinal:
        return MatchStage.semifinal;
      case MatchStage.semifinal:
        return MatchStage.finalMatch;
      case MatchStage.league:
      case MatchStage.finalMatch:
        throw StateError('No knockout stage follows ${stageLabel(stage)}.');
    }
  }

  Future<void> _persist() async {
    final current = _state;
    if (current == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTournamentState, jsonEncode(current.toJson()));
  }
}
