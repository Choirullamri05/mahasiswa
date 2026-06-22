var SHEET_NAME = 'mahasiswa';

// Isi jika script Anda standalone, biarkan kosong jika script ini bound ke spreadsheet.
var SPREADSHEET_ID = '';

function doGet(e) {
  return handleRequest_(e);
}

function doPost(e) {
  return handleRequest_(e);
}

function handleRequest_(e) {
  try {
    var params = getParams_(e);
    var sheet = getSheet_();

    if (!sheet) {
      return jsonOutput_(false, 'Sheet "mahasiswa" tidak ditemukan.');
    }

    var action = String(params.action || '').toLowerCase();

    if (action === 'create') {
      return createMahasiswa_(sheet, params);
    }

    if (action === 'update') {
      return updateMahasiswa_(sheet, params);
    }

    if (action === 'delete') {
      return deleteMahasiswa_(sheet, params);
    }

    return readMahasiswa_(sheet);
  } catch (error) {
    return jsonOutput_(false, error.message || String(error));
  }
}

function getParams_(e) {
  var params = {};

  if (e && e.parameter) {
    for (var key in e.parameter) {
      params[key] = e.parameter[key];
    }
  }

  if (e && e.postData && e.postData.contents) {
    try {
      var parsed = JSON.parse(e.postData.contents);
      if (parsed && typeof parsed === 'object') {
        for (var jsonKey in parsed) {
          params[jsonKey] = parsed[jsonKey];
        }
      }
    } catch (_) {
      // Abaikan jika body bukan JSON.
    }
  }

  return params;
}

function getSheet_() {
  var spreadsheet = null;

  if (SPREADSHEET_ID) {
    spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
  } else {
    spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  }

  if (!spreadsheet) {
    throw new Error(
      'Spreadsheet tidak ditemukan. Isi SPREADSHEET_ID atau bind script ke spreadsheet.'
    );
  }

  return spreadsheet.getSheetByName(SHEET_NAME);
}

function createMahasiswa_(sheet, params) {
  if (!params.id || !params.nama || !params.prodi) {
    return jsonOutput_(false, 'Parameter tidak lengkap.');
  }

  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(params.id)) {
      return jsonOutput_(false, 'ID mahasiswa sudah ada.');
    }
  }

  sheet.appendRow([
    params.id,
    params.nama,
    params.prodi,
  ]);

  return jsonOutput_(true, 'Data berhasil ditambahkan.');
}

function updateMahasiswa_(sheet, params) {
  if (!params.id || !params.nama || !params.prodi) {
    return jsonOutput_(false, 'Parameter tidak lengkap.');
  }

  var data = sheet.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(params.id)) {
      sheet.getRange(i + 1, 2).setValue(params.nama);
      sheet.getRange(i + 1, 3).setValue(params.prodi);

      return jsonOutput_(true, 'Data berhasil diperbarui.');
    }
  }

  return jsonOutput_(false, 'Data dengan ID tersebut tidak ditemukan.');
}

function deleteMahasiswa_(sheet, params) {
  if (!params.id) {
    return jsonOutput_(false, 'Parameter id wajib diisi.');
  }

  var data = sheet.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(params.id)) {
      sheet.deleteRow(i + 1);

      return jsonOutput_(true, 'Data berhasil dihapus.');
    }
  }

  return jsonOutput_(false, 'Data dengan ID tersebut tidak ditemukan.');
}

function readMahasiswa_(sheet) {
  var values = sheet.getDataRange().getValues();

  if (values.length === 0) {
    return ContentService
      .createTextOutput(JSON.stringify({
        success: true,
        data: [],
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  var headers = values[0];
  var result = [];

  for (var i = 1; i < values.length; i++) {
    var row = {};

    for (var j = 0; j < headers.length; j++) {
      row[headers[j]] = values[i][j];
    }

    result.push(row);
  }

  return ContentService
    .createTextOutput(JSON.stringify({
      success: true,
      data: result,
    }))
    .setMimeType(ContentService.MimeType.JSON);
}

function jsonOutput_(success, message) {
  return ContentService
    .createTextOutput(JSON.stringify({
      success: success,
      message: message,
    }))
    .setMimeType(ContentService.MimeType.JSON);
}
