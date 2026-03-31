class TaskCommentModel {
  final int id;
  final int taskId;
  final int userId;
  final String contenido;
  final String createdAt;
  final Map<String, dynamic>? user;

  TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.contenido,
    required this.createdAt,
    this.user,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      id: json['id'],
      taskId: json['taskId'],
      userId: json['userId'],
      contenido: json['contenido'],
      createdAt: json['createdAt'],
      user: json['user'],
    );
  }
}
