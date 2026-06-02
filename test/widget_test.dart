import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pickleball_league/app.dart';
import 'package:pickleball_league/models/game_state.dart';
import 'package:pickleball_league/services/game_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('home screen shows pickleball tournament actions', (tester) async {
    await tester.pumpWidget(const PickleballApp());
    await tester.pumpAndSettle();

    expect(find.text('Pickleball'), findsOneWidget);
    expect(find.text('League Tournament'), findsOneWidget);
    expect(find.text('New Tournament'), findsOneWidget);
  });

  test('creates league, seeds semi finals, and crowns champion', () async {
    final service = GameService();
    await service.clearSaved();
    await service.newTournament();

    final players = <Player>[];
    for (var i = 1; i <= 12; i += 1) {
      players.add(await service.addPlayer('Player $i'));
    }
    for (var i = 0; i < players.length; i += 2) {
      await service.addTeam(players[i].id, players[i + 1].id);
    }

    await service.startLeague();
    expect(service.state!.phase, TournamentPhase.league);
    expect(service.state!.leagueMatches.length, 15);
    expect(service.state!.firstKnockoutStage, MatchStage.semifinal);

    for (final match in service.state!.leagueMatches) {
      final teamAIndex = service.state!.teams.indexWhere((team) => team.id == match.teamAId);
      final teamBIndex = service.state!.teams.indexWhere((team) => team.id == match.teamBId);
      final teamAWins = teamAIndex < teamBIndex;
      await service.saveLeagueScore(match.id, teamAWins ? 11 : 6, teamAWins ? 6 : 11);
    }

    await service.startKnockout();
    expect(service.state!.phase, TournamentPhase.knockout);
    expect(service.state!.knockoutMatches.length, 2);
    expect(service.state!.knockoutMatches.every((match) => match.stage == MatchStage.semifinal), isTrue);

    final semis = service.state!.knockoutMatches.toList();
    for (final match in semis) {
      await service.saveKnockoutScore(match.id, 11, 7);
    }
    expect(service.state!.phase, TournamentPhase.knockout);
    expect(service.state!.knockoutMatches.where((match) => match.stage == MatchStage.finalMatch), hasLength(1));

    final finalMatch = service.state!.knockoutMatches.singleWhere((match) => match.stage == MatchStage.finalMatch);
    await service.saveKnockoutScore(finalMatch.id, 11, 9);

    expect(service.state!.phase, TournamentPhase.complete);
    expect(service.state!.championTeamId, finalMatch.teamAId);
  });
}
