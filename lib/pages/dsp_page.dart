import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../models/dsp.dart';
import 'dsp_detail_page.dart';

class DSPPage extends StatefulWidget {
  const DSPPage({super.key});

  @override
  State<DSPPage> createState() => _DSPPageState();
}

class _DSPPageState extends State<DSPPage> {
  late Future<List<DSP>> _dspsFuture;
  String _selectedTeam = 'All Teams';
  static const List<String> _preferredTeamOrder = [
    'KCM',
    'SEC',
    'TER',
    'ONP',
    'EXT - NORTH',
    'EXT - SOUTH',
    'HOUSE ACCOUNT',
    'HOUSE ACCOUNT WALK IN',
  ];

  @override
  void initState() {
    super.initState();
    _reloadDsps();
  }

  void _reloadDsps() {
    _dspsFuture = DatabaseService().fetchDSPs();
  }

  Future<void> _updateDspList() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected DSP CSV file.')),
      );
      return;
    }

    try {
      await DatabaseService().importDSPList(bytes);
      if (!mounted) return;
      setState(_reloadDsps);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DSP List updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DSP List update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSP'),
        actions: [
          TextButton.icon(
            onPressed: _updateDspList,
            icon: const Icon(Icons.upload_file),
            label: const Text('DSP List'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<DSP>>(
        future: _dspsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final dsps = snapshot.data ?? <DSP>[];

            final teams = <String>{};
            for (final dsp in dsps) {
              final team = dsp.team.trim();
              if (team.isNotEmpty) {
                teams.add(team);
              }
            }

            final orderedTeams = <String>[];
            for (final team in _preferredTeamOrder) {
              if (teams.contains(team)) {
                orderedTeams.add(team);
              }
            }
            final remainingTeams = teams.where((team) => !_preferredTeamOrder.contains(team)).toList()..sort();
            orderedTeams.addAll(remainingTeams);

            final teamOptions = ['All Teams', ...orderedTeams];

            if (!teamOptions.contains(_selectedTeam)) {
              _selectedTeam = 'All Teams';
            }

            final filteredDsps = _selectedTeam == 'All Teams'
                ? dsps
                : dsps.where((dsp) => dsp.team.trim().toUpperCase() == _selectedTeam.toUpperCase()).toList();

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final team in teamOptions)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(team),
                              selected: _selectedTeam == team,
                              onSelected: (_) {
                                setState(() {
                                  _selectedTeam = team;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDsps.length,
                    itemBuilder: (context, index) {
                      final dsp = filteredDsps[index];
                      final dspCodeText = dsp.dspCode.trim().isEmpty ? 'N/A' : dsp.dspCode.trim();
                      final dspNameText = dsp.salesRepName.trim().isEmpty ? 'N/A' : dsp.salesRepName.trim();
                      final teamText = dsp.team.trim().isEmpty ? 'No Team' : dsp.team.trim();
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text('$dspCodeText - $dspNameText'),
                          subtitle: Text('Team: $teamText\nActive: ${dsp.activeCount} / Blocked: ${dsp.blockedCount}'),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DSPDetailPage(dsp: dsp),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}