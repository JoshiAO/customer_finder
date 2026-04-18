import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/database_service.dart';
import '../services/import_notifier.dart';
import '../models/counts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<CustomerCounts> _countsFuture;
  late Future<int> _editedCountFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _countsFuture = DatabaseService().getCounts();
    _editedCountFuture = DatabaseService().getEditedCount();
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<String?> _saveZipToDownloads(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: fileName.replaceAll('.zip', ''),
        bytes: bytes,
        ext: 'zip',
        mimeType: MimeType.zip,
      );
      return 'Downloads';
    }

    try {
      Directory? targetDir;

      if (Platform.isAndroid) {
        final androidDownloads = Directory('/storage/emulated/0/Download');
        if (await androidDownloads.exists()) {
          targetDir = androidDownloads;
        }
      } else {
        targetDir = await getDownloadsDirectory();
      }

      if (targetDir != null) {
        final file = File('${targetDir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      }
    } catch (_) {
      // fall through to FileSaver fallback
    }

    await FileSaver.instance.saveFile(
      name: fileName.replaceAll('.zip', ''),
      bytes: bytes,
      ext: 'zip',
      mimeType: MimeType.zip,
    );
    return null;
  }

  Future<_CmlSelection?> _pickCmlFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result == null) return null;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Unable to read file bytes from selected file.');
    }

    return _CmlSelection(
      bytes: bytes,
      isXlsx: file.extension?.toLowerCase() == 'xlsx',
    );
  }

  Future<Uint8List> _buildEditedCustomersZip({void Function(double)? onProgress}) async {
    final customers = await DatabaseService().getEditedCustomers();
    final archive = Archive();

    final xlsxBytes = await DatabaseService().exportEditedCustomersXlsx(
      onProgress: (pVal) => onProgress?.call(pVal * 0.4),
    );
    archive.addFile(ArchiveFile('edited_customers.xlsx', xlsxBytes.length, xlsxBytes));

    if (kIsWeb || customers.isEmpty) {
      onProgress?.call(1.0);
      return Uint8List.fromList(ZipEncoder().encode(archive) ?? <int>[]);
    }

    final appDir = await getApplicationDocumentsDirectory();
    final capturesRoot = Directory(p.join(appDir.path, 'captured_images'));

    for (var i = 0; i < customers.length; i++) {
      final customer = customers[i];
      final folderName = DatabaseService.customerImageFolderName(customer);
      final customerDir = Directory(p.join(capturesRoot.path, folderName));

      if (await customerDir.exists()) {
        final imageFiles = customerDir
            .listSync()
            .whereType<File>()
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        for (final imageFile in imageFiles) {
          final bytes = await imageFile.readAsBytes();
          final zipPath = '$folderName/${p.basename(imageFile.path)}';
          archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
        }
      }

      onProgress?.call(0.4 + ((i + 1) / customers.length) * 0.6);
    }

    return Uint8List.fromList(ZipEncoder().encode(archive) ?? <int>[]);
  }

  Future<void> _importCML() async {
    final counts = await DatabaseService().getCounts();
    if (!mounted) return;
    if (counts.overall > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please clear data first before importing a new CML file.'),
        ),
      );
      return;
    }

    final notifier = context.read<ImportNotifier>();
    final selected = await _pickCmlFile();
    if (selected == null) return;

    final opId = notifier.start(label: 'Importing CML', type: 'import');

    try {
      await DatabaseService().importCML(
        selected.bytes,
        isXlsx: selected.isXlsx,
        onProgress: (p) => notifier.update(opId, p),
      );
      setState(() => _loadData());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import successful. Existing records were replaced by the new CML data.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      notifier.finish(opId);
    }
  }

  Future<void> _updateCML() async {
    final notifier = context.read<ImportNotifier>();
    final selected = await _pickCmlFile();
    if (selected == null) return;

    final opId = notifier.start(label: 'Updating CML', type: 'update');

    try {
      final added = await DatabaseService().updateCML(
        selected.bytes,
        isXlsx: selected.isXlsx,
        onProgress: (p) => notifier.update(opId, p),
      );

      setState(() => _loadData());
      if (mounted) {
        final msg = added == 0
            ? 'Local database and the new CML file have the same customer records.'
            : 'Update successful. Added $added new customer(s).';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      notifier.finish(opId);
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Data'),
          content: const Text(
            'This will remove all customer and DSP records from local storage. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final notifier = context.read<ImportNotifier>();
    final opId = notifier.start(label: 'Clearing local data', type: 'clear');

    try {
      await DatabaseService().clearAllData(
        onProgress: (p) => notifier.update(opId, p),
      );
      if (!mounted) return;
      setState(() => _loadData());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data cleared.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clear data failed: $e')),
      );
    } finally {
      notifier.finish(opId);
    }
  }

  Future<void> _exportEdited() async {
    final notifier = context.read<ImportNotifier>();
    final opId = notifier.start(label: 'Exporting edited customers archive', type: 'export');

    try {
      final zipBytes = await _buildEditedCustomersZip(
        onProgress: (p) => notifier.update(opId, p),
      );
      final fileName = 'edited_customers_archive_${_timestamp()}.zip';
      final savedPath = await _saveZipToDownloads(zipBytes, fileName);
      final cleared = await DatabaseService().clearEditedCustomersFlags();
      if (!mounted) return;

      setState(() => _loadData());
      final message = savedPath == null
          ? 'Exported ZIP archive. Check your Downloads folder. Cleared $cleared edited record(s).'
          : 'Exported ZIP to: $savedPath. Cleared $cleared edited record(s).';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      notifier.finish(opId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Finder'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.secondaryContainer,
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -24,
            right: -24,
            bottom: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/images/Cluster 1-6.png',
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCCFFFFFF),
                      Color(0xB3FFFFFF),
                      Color(0x99FFFFFF),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: FutureBuilder<CustomerCounts>(
              future: _countsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final counts = snapshot.data!;
                  const actionButtonsWidth = 258.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: scheme.primaryContainer),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Overall - ${counts.overall}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Active - ${counts.active}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Inactive - ${counts.inactive}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<int>(
                          future: _editedCountFuture,
                          builder: (context, editedSnapshot) {
                            if (editedSnapshot.hasData) {
                              return Text(
                                'Edited Customers - ${editedSnapshot.data}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: actionButtonsWidth,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton(
                                  onPressed: _importCML,
                                  child: const Text('Import CML'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _clearData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: scheme.errorContainer,
                                    foregroundColor: scheme.onErrorContainer,
                                  ),
                                  child: const Icon(Icons.delete_outline),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: actionButtonsWidth,
                          child: ElevatedButton(
                            onPressed: _updateCML,
                            child: const Text('Update CML'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: actionButtonsWidth,
                          child: ElevatedButton(
                            onPressed: _exportEdited,
                            child: const Text('Export Edited Customers'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.10,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Created by Joshua A. Ocampo',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CmlSelection {
  const _CmlSelection({required this.bytes, required this.isXlsx});

  final Uint8List bytes;
  final bool isXlsx;
}