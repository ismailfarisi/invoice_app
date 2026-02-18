import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetsService {
  static const _scopes = [
    sheets.SheetsApi.spreadsheetsScope,
    drive.DriveApi.driveFileScope,
  ];

  AuthClient? _client;
  sheets.SheetsApi? _sheetsApi;

  Future<bool> authenticate(String serviceAccountJson) async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      _client = await clientViaServiceAccount(credentials, _scopes);
      _sheetsApi = sheets.SheetsApi(_client!);
      return true;
    } catch (e) {
      print('Google Sheets Auth Error: $e');
      return false;
    }
  }

  Future<String?> createSpreadsheet(String title) async {
    if (_sheetsApi == null) return null;

    try {
      final spreadsheet = sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: title),
      );
      final response = await _sheetsApi!.spreadsheets.create(spreadsheet);
      return response.spreadsheetId;
    } catch (e) {
      print('Error creating spreadsheet: $e');
      return null;
    }
  }

  Future<bool> setupSheet(
    String spreadsheetId,
    String sheetName,
    List<String> headers,
  ) async {
    if (_sheetsApi == null) return false;

    try {
      final response = await _sheetsApi!.spreadsheets.get(spreadsheetId);
      final sheetExists =
          response.sheets?.any((s) => s.properties?.title == sheetName) ??
          false;

      if (!sheetExists) {
        final addSheetRequest = sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: sheetName),
          ),
        );
        await _sheetsApi!.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: [addSheetRequest]),
          spreadsheetId,
        );
      }

      // Add headers if sheet is empty
      final range = '$sheetName!A1:Z1';
      final headerResponse = await _sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        range,
      );
      if (headerResponse.values == null || headerResponse.values!.isEmpty) {
        await _sheetsApi!.spreadsheets.values.update(
          sheets.ValueRange(values: [headers]),
          spreadsheetId,
          range,
          valueInputOption: 'RAW',
        );
      }

      return true;
    } catch (e) {
      print('Error setting up sheet $sheetName: $e');
      return false;
    }
  }

  Future<bool> appendData(
    String spreadsheetId,
    String sheetName,
    List<List<Object?>> data,
  ) async {
    if (_sheetsApi == null) return false;

    try {
      final range = '$sheetName!A1';
      final valueRange = sheets.ValueRange(values: data);
      await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      );
      return true;
    } catch (e) {
      print('Error appending data to $sheetName: $e');
      return false;
    }
  }

  Future<bool> updateData(
    String spreadsheetId,
    String sheetName,
    List<List<Object?>> data,
  ) async {
    if (_sheetsApi == null) return false;

    try {
      // For simplicity, we overwrite the entire sheet content after headers
      // A more robust solution would be to match IDs, but since this is for backup/history,
      // we might want to just append or overwrite depending on needs.
      // The requirement says "sync automatically".

      // Let's implement a "clear and write" for now to ensure data consistency,
      // or "append" if it's meant to be a log.
      // Usually "sync" means reflecting current state.

      final range = '$sheetName!A2:Z1000'; // Clear data rows
      await _sheetsApi!.spreadsheets.values.clear(
        sheets.ClearValuesRequest(),
        spreadsheetId,
        range,
      );

      if (data.isNotEmpty) {
        await _sheetsApi!.spreadsheets.values.update(
          sheets.ValueRange(values: data),
          spreadsheetId,
          '$sheetName!A2',
          valueInputOption: 'RAW',
        );
      }
      return true;
    } catch (e) {
      print('Error updating data in $sheetName: $e');
      return false;
    }
  }

  void dispose() {
    _client?.close();
  }
}
