class User {
  final String uid;              // ইউজারের ইউনিক আইডি (Firebase UID)
  final String? displayName;     // ইউজারের নাম
  final String email;            // ইউজারের ইমেইল
  final String? bio;             // ইউজারের বায়ো বা স্ট্যাটাস
  final String? avatarUrl;       // প্রোফাইল পিকচারের লিংক
  final String? rank;            // গ্লোবাল র‍্যাঙ্ক (যেমন: Gold, Silver বা 1st, 2nd)
  final int score;               // ইউজারের টোটাল স্কোর
  final DateTime? createdAt;     // অ্যাকাউন্ট খোলার সময়

  User({
    required this.uid,
    this.displayName,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.rank,
    this.score = 0,
    this.createdAt,
  });

  // ফায়ারস্টোর বা লোকাল ম্যাপ ডাটা থেকে Dart অবজেক্ট তৈরি করার জন্য
  factory User.fromMap(Map<String, dynamic> data, [String? documentId]) {
    return User(
      uid: documentId ?? data['uid'] ?? data['id'] ?? '',
      displayName: data['displayName'],
      email: data['email'] ?? '',
      bio: data['bio'],
      avatarUrl: data['avatarUrl'],
      rank: data['rank'],
      score: data['score'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is String
          ? DateTime.tryParse(data['createdAt'])
          : data['createdAt'].runtimeType.toString() == 'Timestamp'
          ? (data['createdAt'] as dynamic).toDate()
          : null)
          : null,
    );
  }

  // Dart অবজেক্টকে ফায়ারস্টোর বা লোকাল ডাটাবেসে সেভ করার জন্য ম্যাপে রূপান্তর
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'rank': rank,
      'score': score,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ইউজারের কোনো ডাটা আপডেট হলে (যেমন: স্কোর বৃদ্ধি) নতুন অবজেক্ট তৈরির জন্য
  User copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? bio,
    String? avatarUrl,
    String? rank,
    int? score,
    DateTime? createdAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}