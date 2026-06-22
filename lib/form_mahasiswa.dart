import 'package:flutter/material.dart';

import 'models/mahasiswa.dart';

class FormMahasiswaPage extends StatefulWidget {
  const FormMahasiswaPage({
    super.key,
    this.initialMahasiswa,
    required this.nextId,
  });

  final Mahasiswa? initialMahasiswa;
  final int nextId;

  bool get isEdit => initialMahasiswa != null;

  @override
  State<FormMahasiswaPage> createState() => _FormMahasiswaPageState();
}

class _FormMahasiswaPageState extends State<FormMahasiswaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _prodiController;

  int get _mahasiswaId => widget.initialMahasiswa?.id ?? widget.nextId;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.initialMahasiswa?.nama ?? '',
    );
    _prodiController = TextEditingController(
      text: widget.initialMahasiswa?.prodi ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      Mahasiswa(
        id: _mahasiswaId,
        nama: _namaController.text.trim(),
        prodi: _prodiController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.lightBlue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ID Mahasiswa: $_mahasiswaId',
                      style: TextStyle(
                        color: Colors.indigo.shade900,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Mahasiswa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama mahasiswa wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _prodiController,
                    decoration: InputDecoration(
                      labelText: 'Program Studi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.menu_book_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Program studi wajib diisi.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: Text(widget.isEdit ? 'Simpan Perubahan' : 'Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
