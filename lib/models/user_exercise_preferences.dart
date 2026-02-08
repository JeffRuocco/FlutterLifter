import 'package:flutter_lifter/models/exercise_models.dart';
import 'package:flutter_lifter/utils/utils.dart';

/// Stores user-specific preferences/overrides for an exercise.
/// Used to customize default exercises without modifying the immutable originals.
///
/// Supports user notes and photos with cloud sync preparation:
/// - [userNotes]: Rich personal notes
/// - [localPhotoPaths]: Paths to locally stored photos
/// - [cloudPhotoUrls]: URLs of photos synced to cloud storage
/// - [pendingPhotoUploads]: Local paths awaiting cloud upload
class UserExercisePreferences {
  final String id;

  /// The ID of the exercise these preferences apply to
  final String exerciseId;

  /// User's preferred number of sets (overrides exercise.defaultSets)
  final int? preferredSets;

  /// User's preferred number of reps (overrides exercise.defaultReps)
  final int? preferredReps;

  /// User's preferred weight (overrides exercise.defaultWeight)
  final double? preferredWeight;

  /// User's preferred rest time in seconds (overrides exercise.defaultRestTimeSeconds)
  final int? preferredRestTimeSeconds;

  /// User's detailed personal notes for this exercise (form cues, tips, etc.)
  final String? userNotes;

  /// Paths to locally stored photos for this exercise
  final List<String> localPhotoPaths;

  /// URLs of photos synced to cloud storage (Firebase Storage, etc.)
  final List<String> cloudPhotoUrls;

  /// Local paths of photos pending upload to cloud
  /// Used for offline-first sync when cloud storage is implemented
  final List<String> pendingPhotoUploads;

  /// When these preferences were created
  final DateTime createdAt;

  /// When these preferences were last updated
  final DateTime updatedAt;

  UserExercisePreferences({
    required this.id,
    required this.exerciseId,
    this.preferredSets,
    this.preferredReps,
    this.preferredWeight,
    this.preferredRestTimeSeconds,
    this.userNotes,
    List<String>? localPhotoPaths,
    List<String>? cloudPhotoUrls,
    List<String>? pendingPhotoUploads,
    required this.createdAt,
    required this.updatedAt,
  }) : localPhotoPaths = localPhotoPaths ?? const [],
       cloudPhotoUrls = cloudPhotoUrls ?? const [],
       pendingPhotoUploads = pendingPhotoUploads ?? const [];

  /// Creates a new preference with auto-generated ID and timestamps
  factory UserExercisePreferences.create({
    required String exerciseId,
    int? preferredSets,
    int? preferredReps,
    double? preferredWeight,
    int? preferredRestTimeSeconds,
    String? userNotes,
    List<String>? localPhotoPaths,
    List<String>? cloudPhotoUrls,
    List<String>? pendingPhotoUploads,
  }) {
    final now = DateTime.now();
    return UserExercisePreferences(
      id: Utils.generateId(),
      exerciseId: exerciseId,
      preferredSets: preferredSets,
      preferredReps: preferredReps,
      preferredWeight: preferredWeight,
      preferredRestTimeSeconds: preferredRestTimeSeconds,
      userNotes: userNotes,
      localPhotoPaths: localPhotoPaths,
      cloudPhotoUrls: cloudPhotoUrls,
      pendingPhotoUploads: pendingPhotoUploads,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns whether any preferences are set
  bool get hasPreferences =>
      preferredSets != null ||
      preferredReps != null ||
      preferredWeight != null ||
      preferredRestTimeSeconds != null ||
      userNotes != null ||
      localPhotoPaths.isNotEmpty ||
      cloudPhotoUrls.isNotEmpty;

  /// Returns whether user has added any photos
  bool get hasPhotos => localPhotoPaths.isNotEmpty || cloudPhotoUrls.isNotEmpty;

  /// Returns total count of all photos (local + cloud)
  int get totalPhotoCount => localPhotoPaths.length + cloudPhotoUrls.length;

  /// Returns whether there are photos pending upload
  bool get hasPendingUploads => pendingPhotoUploads.isNotEmpty;

  /// Applies these preferences to an exercise, returning a new Exercise with overridden defaults
  Exercise applyToExercise(Exercise exercise) {
    if (exercise.id != exerciseId) {
      throw ArgumentError(
        'Preferences exerciseId ($exerciseId) does not match exercise.id (${exercise.id})',
      );
    }

    return exercise.copyWith(
      defaultSets: preferredSets ?? exercise.defaultSets,
      defaultReps: preferredReps ?? exercise.defaultReps,
      defaultWeight: preferredWeight ?? exercise.defaultWeight,
      defaultRestTimeSeconds:
          preferredRestTimeSeconds ?? exercise.defaultRestTimeSeconds,
    );
  }

  /// Creates a copy with updated values.
  ///
  /// This is a pure data operation - timestamps are preserved unless explicitly
  /// changed. If you want to mark this as an update, pass `updatedAt: DateTime.now()`.
  ///
  /// For list fields (localPhotoPaths, cloudPhotoUrls, pendingPhotoUploads),
  /// pass null to keep existing values, or pass an empty list to clear them.
  UserExercisePreferences copyWith({
    String? id,
    String? exerciseId,
    int? preferredSets,
    int? preferredReps,
    double? preferredWeight,
    int? preferredRestTimeSeconds,
    String? userNotes,
    List<String>? localPhotoPaths,
    List<String>? cloudPhotoUrls,
    List<String>? pendingPhotoUploads,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserExercisePreferences(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      preferredSets: preferredSets ?? this.preferredSets,
      preferredReps: preferredReps ?? this.preferredReps,
      preferredWeight: preferredWeight ?? this.preferredWeight,
      preferredRestTimeSeconds:
          preferredRestTimeSeconds ?? this.preferredRestTimeSeconds,
      userNotes: userNotes ?? this.userNotes,
      localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
      cloudPhotoUrls: cloudPhotoUrls ?? this.cloudPhotoUrls,
      pendingPhotoUploads: pendingPhotoUploads ?? this.pendingPhotoUploads,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a copy with the userNotes field updated (convenience method)
  UserExercisePreferences withUserNotes(String? newNotes) {
    return copyWith(userNotes: newNotes, updatedAt: DateTime.now());
  }

  /// Creates a copy with a photo added to localPhotoPaths
  UserExercisePreferences withAddedPhoto(String photoPath) {
    return copyWith(
      localPhotoPaths: [...localPhotoPaths, photoPath],
      pendingPhotoUploads: [...pendingPhotoUploads, photoPath],
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy with a photo removed from localPhotoPaths
  UserExercisePreferences withRemovedPhoto(String photoPath) {
    return copyWith(
      localPhotoPaths: localPhotoPaths.where((p) => p != photoPath).toList(),
      pendingPhotoUploads: pendingPhotoUploads
          .where((p) => p != photoPath)
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy with a cloud photo URL removed
  UserExercisePreferences withRemovedCloudPhoto(String photoUrl) {
    return copyWith(
      cloudPhotoUrls: cloudPhotoUrls.where((u) => u != photoUrl).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates UserExercisePreferences from JSON
  factory UserExercisePreferences.fromJson(Map<String, dynamic> json) {
    return UserExercisePreferences(
      id: json['id'],
      exerciseId: json['exerciseId'],
      preferredSets: json['preferredSets'],
      preferredReps: json['preferredReps'],
      preferredWeight: json['preferredWeight']?.toDouble(),
      preferredRestTimeSeconds: json['preferredRestTimeSeconds'],
      userNotes: json['userNotes'],
      localPhotoPaths:
          (json['localPhotoPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      cloudPhotoUrls:
          (json['cloudPhotoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pendingPhotoUploads:
          (json['pendingPhotoUploads'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Converts UserExercisePreferences to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'preferredSets': preferredSets,
      'preferredReps': preferredReps,
      'preferredWeight': preferredWeight,
      'preferredRestTimeSeconds': preferredRestTimeSeconds,
      'userNotes': userNotes,
      'localPhotoPaths': localPhotoPaths,
      'cloudPhotoUrls': cloudPhotoUrls,
      'pendingPhotoUploads': pendingPhotoUploads,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserExercisePreferences &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserExercisePreferences{id: $id, exerciseId: $exerciseId, '
        'preferredSets: $preferredSets, preferredReps: $preferredReps, '
        'preferredWeight: $preferredWeight}';
  }
}
