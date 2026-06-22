import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../form_mahasiswa.dart';
import '../models/mahasiswa.dart';

class MahasiswaPage extends StatefulWidget {
  const MahasiswaPage({
    super.key,
    this.openFormOnStart = false,
  });

  final bool openFormOnStart;

  @override
  State<MahasiswaPage> createState() => _MahasiswaPageState();
}

class _MahasiswaPageState extends State<MahasiswaPage> {
  static const String _storageKey = 'mahasiswa_data';

  final String apiUrl =
      'https://script.google.com/macros/s/AKfycbxvVZs4wAOBaGDZsIWLPMyC6TajbTYaCzide2Ctq9vCa__FZefzygSJ9ZJsBTFPy1NV/exec';

  List<Mahasiswa> mahasiswa = [];
  bool isLoading = true;
  String? loadMessage;
  bool _hasOpenedInitialForm = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await getData();

    if (!widget.openFormOnStart || _hasOpenedInitialForm || !mounted) {
      return;
    }

    _hasOpenedInitialForm = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _openForm();
    });
  }

  int get _nextId {
    if (mahasiswa.isEmpty) {
      return 1;
    }

    final lastId = mahasiswa
        .map((item) => item.id)
        .reduce((value, element) => value > element ? value : element);
    return lastId + 1;
  }

  Future<void> getData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final items = await _fetchRemoteData();
      await _saveLocalData(items);

      if (!mounted) {
        return;
      }

      setState(() {
        mahasiswa = items;
        isLoading = false;
        loadMessage = 'Data berhasil dimuat dari database.';
      });
    } catch (e) {
      final cachedData = await _loadLocalData();
      if (!mounted) {
        return;
      }

      setState(() {
        mahasiswa = cachedData;
        isLoading = false;
        loadMessage = cachedData.isEmpty
            ? 'Gagal mengakses database: $e'
            : 'Gagal sinkron ke database. Menampilkan cache lokal terakhir: $e';
      });
    }
  }

  Future<List<Mahasiswa>> _fetchRemoteData() async {
    final response = await http.get(Uri.parse(apiUrl));
    _ensureReadResponse(response);

    final items = _parseMahasiswaList(response.body);
    return items..sort((a, b) => a.id.compareTo(b.id));
  }

  List<Mahasiswa> _parseMahasiswaList(String body) {
    final decoded = jsonDecode(body);
    final rawList = switch (decoded) {
      List<dynamic> value => value,
      Map<String, dynamic> value when value['data'] is List<dynamic> =>
        value['data'] as List<dynamic>,
      Map<String, dynamic> value when value['results'] is List<dynamic> =>
        value['results'] as List<dynamic>,
      Map<String, dynamic> value when value['items'] is List<dynamic> =>
        value['items'] as List<dynamic>,
      _ => throw Exception('Format data dari database tidak dikenali.'),
    };

    return rawList
        .map((item) => Mahasiswa.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Mahasiswa>> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_storageKey);

    if (rawData == null || rawData.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(rawData) as List<dynamic>;
    return decoded
        .map((item) => Mahasiswa.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> _saveLocalData(List<Mahasiswa> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      data.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _replaceLocalData(List<Mahasiswa> items) async {
    final sortedItems = [...items]..sort((a, b) => a.id.compareTo(b.id));

    if (!mounted) {
      return;
    }

    setState(() {
      mahasiswa = sortedItems;
      isLoading = false;
      loadMessage = 'Data lokal sudah disinkronkan dengan perubahan terbaru.';
    });

    await _saveLocalData(sortedItems);
  }

  Future<void> _openForm({Mahasiswa? item}) async {
    final result = await Navigator.push<Mahasiswa>(
      context,
      MaterialPageRoute(
        builder: (context) => FormMahasiswaPage(
          initialMahasiswa: item,
          nextId: _nextId,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      if (item == null) {
        await _sendCrudRequest(
          actionType: _ActionType.create,
          mahasiswa: result,
        );
        await _replaceLocalData([...mahasiswa, result]);
      } else {
        await _sendCrudRequest(
          actionType: _ActionType.update,
          mahasiswa: result,
        );
        await _replaceLocalData(
          mahasiswa
              .map((current) => current.id == item.id ? result : current)
              .toList(),
        );
      }
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null
                ? 'Data mahasiswa berhasil ditambahkan ke database.'
                : 'Data mahasiswa berhasil diperbarui di database.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan ke database: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteMahasiswa(Mahasiswa item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text(
          'Yakin ingin menghapus ${item.nama} dari database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _sendCrudRequest(
        actionType: _ActionType.delete,
        mahasiswa: item,
      );
      await _replaceLocalData(
        mahasiswa.where((current) => current.id != item.id).toList(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data mahasiswa berhasil dihapus dari database.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus dari database: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _sendCrudRequest({
    required _ActionType actionType,
    required Mahasiswa mahasiswa,
  }) async {
    final action = switch (actionType) {
      _ActionType.create => 'create',
      _ActionType.update => 'update',
      _ActionType.delete => 'delete',
    };

    final response = await http.get(
      Uri.parse(apiUrl).replace(
        queryParameters: {
          'action': action,
          'id': mahasiswa.id.toString(),
          'nama': mahasiswa.nama,
          'prodi': mahasiswa.prodi,
        },
      ),
    );

    _ensureCrudSuccessResponse(
      response,
      '${_actionLabel(actionType)} data',
    );
  }

  String _actionLabel(_ActionType actionType) {
    return switch (actionType) {
      _ActionType.create => 'menambah',
      _ActionType.update => 'mengubah',
      _ActionType.delete => 'menghapus',
    };
  }

  void _ensureReadResponse(http.Response response) {
    final body = response.body.trim();

    if (response.statusCode != 200) {
      throw Exception(
        'Server mengembalikan status ${response.statusCode} saat membaca data.',
      );
    }

    if (_looksLikeAccessDenied(body)) {
      throw Exception(
        'Endpoint Google Apps Script masih menolak akses. Pastikan deployment web app diatur ke akses publik.',
      );
    }

    if (body.isEmpty) {
      throw Exception('Database mengembalikan respons kosong.');
    }

    try {
      jsonDecode(body);
    } catch (_) {
      throw Exception('Respons baca database bukan JSON: $body');
    }
  }

  void _ensureCrudSuccessResponse(http.Response response, String activity) {
    final body = response.body.trim();

    if (response.statusCode != 200) {
      throw Exception(
        'Server mengembalikan status ${response.statusCode} saat $activity.',
      );
    }

    if (_looksLikeAccessDenied(body)) {
      throw Exception(
        'Endpoint Google Apps Script masih menolak akses. Pastikan deployment web app diatur ke akses publik.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = null;
    }

    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'];
      final message = decoded['message']?.toString();

      if (success == true) {
        return;
      }

      if (success == false) {
        throw Exception(message ?? 'Database mengembalikan status gagal.');
      }
    }

    final normalizedBody = body.toLowerCase();

    if (normalizedBody == 'success') {
      return;
    }

    if (normalizedBody == 'gagal') {
      throw Exception('Database mengembalikan status gagal saat $activity.');
    }

    if (normalizedBody == 'parameter tidak lengkap') {
      throw Exception('Parameter yang dikirim dari aplikasi belum lengkap.');
    }

    if (normalizedBody == 'sheet tidak ditemukan') {
      throw Exception('Sheet "mahasiswa" tidak ditemukan di Google Sheets.');
    }

    throw Exception('Respons database tidak dikenali: $body');
  }

  bool _looksLikeAccessDenied(String body) {
    final lowercaseBody = body.toLowerCase();
    return lowercaseBody.contains('<!doctype html') ||
        lowercaseBody.contains('<html') ||
        lowercaseBody.contains('akses ditolak') ||
        lowercaseBody.contains('anda memerlukan akses');
  }

  Widget _buildInfoBanner() {
    if (loadMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.lightBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loadMessage!,
              style: TextStyle(
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 72,
              color: Colors.indigo.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data mahasiswa',
              style: TextStyle(
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarik ke bawah atau tekan refresh untuk sinkron ke database.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.indigo.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.lightBlue,
        ),
      );
    }

    if (mahasiswa.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => getData(showLoading: false),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: mahasiswa.length,
        itemBuilder: (context, index) {
          final item = mahasiswa[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.lightBlue.shade300,
                      child: Text(
                        item.id.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nama,
                            style: TextStyle(
                              color: Colors.indigo.shade900,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.prodi,
                            style: TextStyle(
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openForm(item: item),
                          icon: Icon(
                            Icons.edit,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          onPressed: () => _deleteMahasiswa(item),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Mahasiswa'),
        backgroundColor: Colors.lightBlue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => getData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.lightBlue.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.lightBlue.shade50,
              Colors.lightBlue.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildInfoBanner(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }
}

enum _ActionType {
  create,
  update,
  delete,
}
