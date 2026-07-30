import 'package:hive/hive.dart';
import '../models/scoreboard_entry.dart';

class HiveStorageService {
  // Hive ডাটাবেসের বক্সের (টেবিল) নাম নির্ধারণ
  static const String boxName = 'scoreboard_entries';

  // প্রতিবার কাজ করার আগে বক্সটি ওপেন করার ইন্টারনাল মেথড
  Future<Box<ScoreboardEntry>> _openBox() async {
    return await Hive.openBox<ScoreboardEntry>(boxName);
  }

  /// লোকাল ডাটাবেসে একটি নতুন স্কোরের এন্ট্রি সেভ করা
  Future<void> saveScoreEntry(ScoreboardEntry entry) async {
    final box = await _openBox();
    // এন্ট্রির ইউনিক আইডি কি (Key) হিসেবে ব্যবহার করে অবজেক্টটি সেভ করা হচ্ছে
    await box.put(entry.id, entry);
  }

  /// লোকাল ডাটাবেস থেকে সব স্কোরের হিস্ট্রি তুলে আনা (নতুনগুলো আগে থাকবে)
  Future<List<ScoreboardEntry>> getScoreHistory() async {
    final box = await _openBox();
    final list = box.values.toList();

    // টাইমস্ট্যাম্প তুলনা করে ডিসেন্ডিং অর্ডারে (নতুন স্কোর সবার উপরে) সর্ট করা
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// ইউজারের রিকোয়েস্টে লোকাল ডাটাবেসের সব স্কোর হিস্ট্রি মুছে ফেলা
  Future<void> clearScoreHistory() async {
    final box = await _openBox();
    await box.clear();
  }
}