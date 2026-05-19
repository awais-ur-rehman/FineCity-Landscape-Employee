import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/repositories/task_repository.dart';
import 'task_detail_state.dart';

/// Cubit managing the task detail screen.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskRepository _taskRepository;
  final ImagePicker _imagePicker = ImagePicker();

  TaskDetailCubit(this._taskRepository) : super(const TaskDetailInitial());

  /// Load task details and recent completions.
  Future<void> loadTask(String taskId) async {
    emit(const TaskDetailLoading());

    final taskResult = await _taskRepository.getTaskById(taskId);

    await taskResult.fold(
      (failure) async => emit(TaskDetailError(failure.message)),
      (task) async {
        final completionsResult =
            await _taskRepository.getRecentCompletions(task.scheduleId);
        final completions = completionsResult.fold(
          (_) => <dynamic>[],
          (list) => list,
        );
        emit(TaskDetailLoaded(
          task: task,
          recentCompletions: List.from(completions),
        ));
      },
    );
  }

  /// Pick photos from camera or gallery (max 3 total).
  Future<void> pickPhotos({required bool fromCamera}) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;

    final remaining = 3 - current.selectedPhotoPaths.length;
    if (remaining <= 0) return;

    try {
      if (fromCamera) {
        final photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (photo == null) return;
        emit(current.copyWith(
          selectedPhotoPaths: [...current.selectedPhotoPaths, photo.path],
        ));
      } else {
        final photos = await _imagePicker.pickMultiImage(imageQuality: 80);
        if (photos.isEmpty) return;
        final paths = photos.take(remaining).map((x) => x.path).toList();
        emit(current.copyWith(
          selectedPhotoPaths: [...current.selectedPhotoPaths, ...paths],
        ));
      }
    } catch (_) {
      // Permission denied or other error — silently ignore
    }
  }

  /// Remove a selected photo by index.
  void removePhoto(int index) {
    final current = state;
    if (current is! TaskDetailLoaded) return;
    final updated = List<String>.from(current.selectedPhotoPaths)
      ..removeAt(index);
    emit(current.copyWith(selectedPhotoPaths: updated));
  }

  /// Mark the task as completed with optional notes and photos.
  Future<void> markComplete(String taskId, {String? notes}) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;

    emit(current.copyWith(isCompleting: true));

    final result = await _taskRepository.completeTask(
      taskId,
      notes: notes,
      photoPaths: current.selectedPhotoPaths.isEmpty
          ? null
          : current.selectedPhotoPaths,
    );

    result.fold(
      (failure) {
        emit(current.copyWith(isCompleting: false));
        emit(TaskDetailError(failure.message));
        emit(current.copyWith(isCompleting: false));
      },
      (completedTask) {
        emit(TaskDetailCompleted(completedTask));
      },
    );
  }
}
