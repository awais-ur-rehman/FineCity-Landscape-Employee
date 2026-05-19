import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../models/care_task_model.dart';

/// Remote data source for care tasks.
abstract class TaskRemoteDataSource {
  /// Fetches today's tasks for the current user.
  Future<List<CareTaskModel>> getTodayTasks();

  /// Fetches a single task by ID.
  Future<CareTaskModel> getTaskById(String id);

  /// Marks a task as completed. Pass [photoPaths] to upload photos.
  Future<CareTaskModel> completeTask(
    String id, {
    String? notes,
    List<String>? photoPaths,
  });

  /// Fetches tasks for a specific date.
  Future<List<CareTaskModel>> getTasksForDate(DateTime date);

  /// Fetches recent completed tasks for a schedule.
  Future<List<CareTaskModel>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  });
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient _apiClient;

  const TaskRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CareTaskModel>> getTodayTasks() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _apiClient.dio.get(
        ApiEndpoints.careTasks,
        queryParameters: {'date': today, 'limit': 100},
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch tasks',
          statusCode: response.statusCode,
        );
      }
      final tasks = response.data['data']['tasks'] as List<dynamic>? ??
          response.data['data'] as List<dynamic>;
      return tasks
          .map((t) => CareTaskModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch tasks',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CareTaskModel> getTaskById(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.careTasks}/$id',
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Task not found',
          statusCode: response.statusCode,
        );
      }
      return CareTaskModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch task',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CareTaskModel> completeTask(
    String id, {
    String? notes,
    List<String>? photoPaths,
  }) async {
    try {
      final hasPhotos = photoPaths != null && photoPaths.isNotEmpty;

      dynamic requestData;
      Options? options;

      if (hasPhotos) {
        // Multipart — include photos as files
        final formData = FormData();
        formData.fields.add(
          MapEntry('completedAt', DateTime.now().toIso8601String()),
        );
        if (notes != null && notes.isNotEmpty) {
          formData.fields.add(MapEntry('notes', notes));
        }
        for (final path in photoPaths) {
          final file = File(path);
          final filename = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'photos',
              await MultipartFile.fromFile(file.path, filename: filename),
            ),
          );
        }
        requestData = formData;
      } else {
        // Plain JSON
        final data = <String, dynamic>{
          'completedAt': DateTime.now().toIso8601String(),
        };
        if (notes != null && notes.isNotEmpty) data['notes'] = notes;
        requestData = data;
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.completeTask(id),
        data: requestData,
        options: options,
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to complete task',
          statusCode: response.statusCode,
        );
      }
      return CareTaskModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to complete task',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CareTaskModel>> getTasksForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _apiClient.dio.get(
        ApiEndpoints.careTasks,
        queryParameters: {'date': dateStr, 'limit': 100},
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch tasks',
          statusCode: response.statusCode,
        );
      }
      final tasks = response.data['data']['tasks'] as List<dynamic>? ??
          response.data['data'] as List<dynamic>;
      return tasks
          .map((t) => CareTaskModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch tasks',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CareTaskModel>> getRecentCompletions(
    String scheduleId, {
    int limit = 5,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.careTasks,
        queryParameters: {
          'scheduleId': scheduleId,
          'status': 'completed',
          'limit': limit,
        },
      );
      if (response.data['success'] != true) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch completions',
          statusCode: response.statusCode,
        );
      }
      final tasks = response.data['data']['tasks'] as List<dynamic>? ??
          response.data['data'] as List<dynamic>;
      return tasks
          .map((t) => CareTaskModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data?['message'] ?? 'Failed to fetch completions',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
