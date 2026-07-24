/// Central place for configuration constants.
///
/// IMPORTANT: For a real submission, don't hardcode secrets in source
/// control long-term — but for this assessment, the Supabase "anon" /
/// "publishable" key is safe to ship in a client app; it only works
/// within the RLS policies you define (see supabase_schema.sql).
class AppConstants {
  static const String supabaseUrl = 'https://ybeiqtmqxszhtwmvoosn.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_N8sKm4olrkXYtlvI6kO06w_rFn87Kj5';

  // Storage buckets (create these in Supabase Storage, both set to "Public")
  static const String postImagesBucket = 'post-images';
  static const String commentImagesBucket = 'comment-images';

  // Tables
  static const String postsTable = 'posts';
  static const String commentsTable = 'comments';

  // Pagination
  static const int postsPageSize = 10;
}
