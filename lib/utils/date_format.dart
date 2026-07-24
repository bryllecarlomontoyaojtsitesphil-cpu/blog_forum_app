import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

String formatPostDate(DateTime date) {
  final localDate = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(localDate);

  if (diff.inHours < 24) {
    return timeago.format(localDate);
  }

  return DateFormat("MMMM d 'at' h:mm a").format(localDate);
}