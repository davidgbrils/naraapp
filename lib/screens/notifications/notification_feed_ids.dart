class NotificationFeedIds {
  static String reminderId({
    required int notificationId,
    required String title,
    required String scheduleKey,
    required String note,
  }) {
    return 'reminder:$notificationId:$title:$scheduleKey:$note';
  }

  static String debtId({
    required int debtId,
    required String status,
    required String dueDate,
  }) {
    return 'debt:$debtId:$status:$dueDate';
  }

  static String expenseId({
    required Object createdAt,
    required String title,
  }) {
    return 'expense:$createdAt:$title';
  }

  static String incomeId({
    required Object createdAt,
    required String title,
  }) {
    return 'income:$createdAt:$title';
  }
}

