import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/game_service.dart';
import '../theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.resumed,
    required this.onExit,
    required this.darkMode,
    required this.onToggleDark,
    required this.themeId,
    required this.onThemeChanged,
  });

  final bool resumed;
  final VoidCallback onExit;
  final bool darkMode;
  final VoidCallback onToggleDark;
  final String themeId;
  final void Function(String) onThemeChanged;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameService _service = GameService();
  final TextEditingController _playerController = TextEditingController();
  TournamentState? _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    final loaded = widget.resumed ? await _service.loadGame() : await _service.newTournament();
    final state = loaded ?? await _service.newTournament();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  Future<void> _refresh(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      setState(() => _state = _service.state);
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Please check your input.';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.save, color: Theme.of(ctx).colorScheme.primary, size: 40),
        title: const Text('Exit tournament?'),
        content: const Text('Your tournament is saved on this device and can be resumed later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.home),
            label: const Text('Exit'),
          ),
        ],
      ),
    );
    if (quit == true) {
      widget.onExit();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading || _state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Pickleball League',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async => _onWillPop(),
            tooltip: 'Back',
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
              onPressed: () => showThemePickerDialog(
                context,
                currentThemeId: widget.themeId,
                isDark: widget.darkMode,
                onThemeSelected: widget.onThemeChanged,
              ),
              tooltip: 'Theme',
            ),
            IconButton(
              icon: Icon(widget.darkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: widget.onToggleDark,
              tooltip: widget.darkMode ? 'Light mode' : 'Dark mode',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'reset') _confirmResetTournament();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Text('Reset tournament'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressHeader(theme),
                const SizedBox(height: 16),
                if (_state!.phase == TournamentPhase.setup) _buildSetup(theme),
                if (_state!.phase == TournamentPhase.league) _buildLeague(theme),
                if (_state!.phase == TournamentPhase.knockout) _buildKnockout(theme),
                if (_state!.phase == TournamentPhase.complete) _buildChampion(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme) {
    const phases = [
      TournamentPhase.setup,
      TournamentPhase.league,
      TournamentPhase.knockout,
      TournamentPhase.complete,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tournament progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: phases.map((phase) {
                final selected = phase == _state!.phase;
                return Chip(
                  avatar: Icon(
                    _phaseIcon(phase),
                    size: 18,
                    color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.primary,
                  ),
                  label: Text(phaseLabel(phase)),
                  backgroundColor: selected ? theme.colorScheme.primaryContainer : null,
                  labelStyle: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _phaseIcon(TournamentPhase phase) {
    switch (phase) {
      case TournamentPhase.setup:
        return Icons.groups;
      case TournamentPhase.league:
        return Icons.table_chart;
      case TournamentPhase.knockout:
        return Icons.account_tree;
      case TournamentPhase.complete:
        return Icons.emoji_events;
    }
  }

  Widget _buildSetup(ThemeData theme) {
    final unassigned = _state!.unassignedPlayers;
    final canStart = _state!.teams.length >= 2 && unassigned.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          theme,
          title: '1. Enter players',
          icon: Icons.person_add_alt,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playerController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Player name',
                        hintText: 'Example: Anna',
                      ),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_state!.players.isEmpty)
                const Text('Add at least four players to create two doubles teams.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _state!.players.map((player) {
                    final assigned = _state!.assignedPlayerIds.contains(player.id);
                    return InputChip(
                      avatar: Icon(assigned ? Icons.check_circle : Icons.person_outline, size: 18),
                      label: Text(player.name),
                      onDeleted: assigned ? null : () => _refresh(() => _service.removePlayer(player.id)),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme,
          title: '2. Select partners',
          icon: Icons.handshake,
          trailing: FilledButton.icon(
            onPressed: unassigned.length >= 2 ? () => _showTeamDialog(unassigned) : null,
            icon: const Icon(Icons.group_add),
            label: const Text('Create Team'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_state!.teams.isEmpty)
                const Text('No teams yet. Select two unassigned players to form each doubles team.')
              else
                ..._state!.teams.map((team) => _buildTeamTile(theme, team)),
              if (unassigned.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Unassigned: ${unassigned.map((player) => player.name).join(', ')}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: canStart ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to create the league?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  canStart
                      ? '${_state!.teams.length} teams will play a round-robin league.'
                      : 'Create at least two teams and assign every player to a partner.',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: canStart ? () => _refresh(_service.startLeague) : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start League Stage'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamTile(ThemeData theme, Team team) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: const Icon(Icons.groups),
        ),
        title: Text(team.name(_state!.players), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Doubles team'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: () => _refresh(() => _service.removeTeam(team.id)),
          tooltip: 'Remove team',
        ),
      ),
    );
  }

  Future<void> _addPlayer() async {
    final name = _playerController.text;
    await _refresh(() async {
      await _service.addPlayer(name);
      _playerController.clear();
    });
  }

  Future<void> _showTeamDialog(List<Player> unassignedPlayers) async {
    var firstId = unassignedPlayers.first.id;
    var secondId = unassignedPlayers.length > 1 ? unassignedPlayers[1].id : unassignedPlayers.first.id;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final secondOptions = unassignedPlayers.where((player) => player.id != firstId).toList();
          if (!secondOptions.any((player) => player.id == secondId)) {
            secondId = secondOptions.first.id;
          }

          return AlertDialog(
            icon: Icon(Icons.handshake, color: Theme.of(ctx).colorScheme.primary, size: 40),
            title: const Text('Create team'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: firstId,
                  decoration: const InputDecoration(labelText: 'Player 1'),
                  items: unassignedPlayers
                      .map((player) => DropdownMenuItem(value: player.id, child: Text(player.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => firstId = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: secondId,
                  decoration: const InputDecoration(labelText: 'Player 2'),
                  items: secondOptions
                      .map((player) => DropdownMenuItem(value: player.id, child: Text(player.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => secondId = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _refresh(() => _service.addTeam(firstId, secondId));
                },
                icon: const Icon(Icons.check),
                label: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeague(ThemeData theme) {
    final standings = _state!.standings();
    final qualifierCount = _state!.qualifierCount;
    final qualifierStage = stageLabel(_state!.firstKnockoutStage).toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoBanner(
          theme,
          icon: Icons.info_outline,
          title: 'League stage',
          message: 'Enter scores for every match. Top $qualifierCount teams advance to the $qualifierStage.',
        ),
        const SizedBox(height: 16),
        _buildStandings(theme, standings, qualifierCount),
        const SizedBox(height: 16),
        _buildSectionCard(
          theme,
          title: 'League matches',
          icon: Icons.sports_score,
          child: Column(
            children: _state!.leagueMatches
                .map((match) => _buildMatchTile(theme, match, onScore: () => _showScoreDialog(match, isLeague: true)))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _state!.isLeagueComplete ? () => _refresh(_service.startKnockout) : null,
          icon: const Icon(Icons.account_tree),
          label: Text('Create ${stageLabel(_state!.firstKnockoutStage)}'),
        ),
      ],
    );
  }

  Widget _buildStandings(ThemeData theme, List<TeamStanding> standings, int qualifierCount) {
    return _buildSectionCard(
      theme,
      title: 'Standings',
      icon: Icons.leaderboard,
      child: Column(
        children: [
          for (var index = 0; index < standings.length; index += 1)
            _buildStandingRow(theme, standings[index], index + 1, index < qualifierCount),
        ],
      ),
    );
  }

  Widget _buildStandingRow(ThemeData theme, TeamStanding standing, int rank, bool qualifies) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: qualifies ? theme.colorScheme.secondaryContainer.withOpacity(0.65) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualifies ? theme.colorScheme.secondary : theme.colorScheme.outline.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: qualifies ? theme.colorScheme.secondary : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: qualifies ? theme.colorScheme.onSecondary : theme.colorScheme.onSurface,
            child: Text('$rank'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              standing.team.name(_state!.players),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _statColumn('P', standing.played),
          _statColumn('W', standing.wins),
          _statColumn('L', standing.losses),
          _statColumn('+/-', standing.pointDifference),
          _statColumn('Pts', standing.leaguePoints),
        ],
      ),
    );
  }

  Widget _statColumn(String label, int value) {
    return SizedBox(
      width: 42,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKnockout(ThemeData theme) {
    final activeStage = _state!.activeKnockoutStage;
    final matchesByStage = <MatchStage, List<TournamentMatch>>{};
    for (final match in _state!.knockoutMatches) {
      matchesByStage.putIfAbsent(match.stage, () => []).add(match);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoBanner(
          theme,
          icon: Icons.account_tree,
          title: activeStage == null ? 'Advancing bracket' : stageLabel(activeStage),
          message: activeStage == null
              ? 'Winners are being prepared for the next round.'
              : 'Enter scores for ${stageLabel(activeStage).toLowerCase()} matches to advance winners.',
        ),
        const SizedBox(height: 16),
        _buildStandings(theme, _state!.standings(), _state!.qualifierCount),
        const SizedBox(height: 16),
        ...[
          MatchStage.quarterfinal,
          MatchStage.semifinal,
          MatchStage.finalMatch,
        ].where(matchesByStage.containsKey).map((stage) {
          final matches = matchesByStage[stage]!..sort((a, b) => a.order.compareTo(b.order));
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSectionCard(
              theme,
              title: stageLabel(stage),
              icon: stage == MatchStage.finalMatch ? Icons.emoji_events : Icons.sports_tennis,
              child: Column(
                children: matches.map((match) {
                  final canScore = stage == activeStage || !match.isCompleted;
                  return _buildMatchTile(
                    theme,
                    match,
                    onScore: canScore ? () => _showScoreDialog(match, isLeague: false) : null,
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChampion(ThemeData theme) {
    final champion = _state!.championTeamId == null ? null : _state!.teamName(_state!.championTeamId!);
    final finalMatches = _state!.knockoutMatches.where((match) => match.stage == MatchStage.finalMatch).toList();
    final finalMatch = finalMatches.isEmpty ? null : finalMatches.last;

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.emoji_events, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Tournament Champion',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                champion ?? 'Champion not available',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if (finalMatch != null && finalMatch.hasScore) ...[
                const SizedBox(height: 10),
                Text(
                  'Final score: ${finalMatch.scoreA} - ${finalMatch.scoreB}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _confirmResetTournament,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Start Another Tournament'),
              ),
              TextButton.icon(
                onPressed: widget.onExit,
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchTile(
    ThemeData theme,
    TournamentMatch match, {
    required VoidCallback? onScore,
  }) {
    final teamA = _state!.teamName(match.teamAId);
    final teamB = _state!.teamName(match.teamBId);
    final winner = match.winnerId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${stageLabel(match.stage)} Match ${match.order}',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 10),
            _teamScoreLine(theme, teamA, match.scoreA, winner == match.teamAId),
            const SizedBox(height: 6),
            _teamScoreLine(theme, teamB, match.scoreB, winner == match.teamBId),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: match.isCompleted
                  ? OutlinedButton.icon(
                      onPressed: onScore,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Score'),
                    )
                  : FilledButton.icon(
                      onPressed: onScore,
                      icon: const Icon(Icons.scoreboard),
                      label: const Text('Enter Score'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamScoreLine(ThemeData theme, String teamName, int? score, bool winner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: winner ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (winner) ...[
            Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(teamName, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(score?.toString() ?? '-', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showScoreDialog(TournamentMatch match, {required bool isLeague}) async {
    final teamAController = TextEditingController(text: match.scoreA?.toString() ?? '');
    final teamBController = TextEditingController(text: match.scoreB?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Score ${stageLabel(match.stage)} Match ${match.order}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _scoreField(teamAController, _state!.teamName(match.teamAId)),
              const SizedBox(height: 12),
              _scoreField(teamBController, _state!.teamName(match.teamBId)),
              const SizedBox(height: 10),
              const Text('Scores cannot be tied because a winner must advance.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final scoreA = int.parse(teamAController.text.trim());
              final scoreB = int.parse(teamBController.text.trim());
              Navigator.of(ctx).pop();
              await _refresh(() async {
                if (isLeague) {
                  await _service.saveLeagueScore(match.id, scoreA, scoreB);
                } else {
                  await _service.saveKnockoutScore(match.id, scoreA, scoreB);
                }
              });
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );

    teamAController.dispose();
    teamBController.dispose();
  }

  Widget _scoreField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final score = int.tryParse((value ?? '').trim());
        if (score == null) return 'Enter a number';
        if (score < 0) return 'Score cannot be negative';
        return null;
      },
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmResetTournament() async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error, size: 42),
        title: const Text('Reset tournament?'),
        content: const Text('This clears the current players, teams, scores, and bracket.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (reset == true) {
      await _refresh(() async {
        await _service.newTournament();
      });
    }
  }
}
