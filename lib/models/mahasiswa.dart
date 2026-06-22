class Mahasiswa {
  const Mahasiswa({
    required this.id,
    required this.nama,
    required this.prodi,
  });

  final int id;
  final String nama;
  final String prodi;

  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      prodi: json['prodi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'prodi': prodi,
    };
  }

  Mahasiswa copyWith({
    int? id,
    String? nama,
    String? prodi,
  }) {
    return Mahasiswa(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      prodi: prodi ?? this.prodi,
    );
  }
}
