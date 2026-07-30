import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app_route.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/edit_profile_dialogue.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/score_card_widget.dart';

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileHeaderDelegate({
    required this.expandedHeight,
    required this.minHeight,
    required this.profile,
    required this.isUploadingImage,
    required this.onEditImage,
    required this.onEditProfile,
    required this.onLogout,
    required this.onUnsubscribe,
  });

  final double expandedHeight;
  final double minHeight;
  final User? profile;
  final bool isUploadingImage;
  final VoidCallback onEditImage;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final VoidCallback onUnsubscribe;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final double safeAreaTop = MediaQuery.of(context).padding.top;
    final double maxExtent = this.maxExtent;

    final double progress = (shrinkOffset / (maxExtent - minHeight)).clamp(0.0, 1.0);
    const double maxAvatarRadius = 46.0;
    const double minAvatarRadius = 18.0;
    final double currentAvatarRadius =
        maxAvatarRadius - ((maxAvatarRadius - minAvatarRadius) * progress);
    final double currentAvatarSize = currentAvatarRadius * 2;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double avatarLeftExpanded = (screenWidth - currentAvatarSize) / 2;
    const double avatarLeftCollapsed = 16.0;
    final double currentAvatarLeft =
        avatarLeftExpanded - ((avatarLeftExpanded - avatarLeftCollapsed) * progress);
    final double avatarTopExpanded = maxExtent - currentAvatarRadius;
    final double avatarTopCollapsed = safeAreaTop + (kToolbarHeight - currentAvatarSize) / 2;
    final double currentAvatarTop =
        avatarTopExpanded + ((avatarTopCollapsed - avatarTopExpanded) * progress);
    const double titleLeftExpanded = 16.0;
    final double titleLeftCollapsed = 16.0 + (minAvatarRadius * 2) + 12.0;
    final double currentTitleLeft =
        titleLeftExpanded + ((titleLeftCollapsed - titleLeftExpanded) * progress);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: Container(color: const Color(0xFF6B58E9))),

        Positioned(
          top: safeAreaTop,
          left: 0,
          right: 0,
          height: kToolbarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (profile != null)
                Semantics(
                  label: 'Edit Profile',
                  child: IconButton(
                    tooltip: 'Edit Profile',
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onEditProfile();
                    },
                  ),
                ),
              Semantics(
                label: 'Unsubscribe',
                child: IconButton(
                  tooltip: 'Unsubscribe',
                  icon: const Icon(Icons.unsubscribe_outlined, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // শুধু ডায়ালগ-ভিত্তিক unsubscribe ফ্লো কল করি —
                    // সেটি নিজেই সফল হলে landing-এ নেভিগেট করবে।
                    onUnsubscribe();
                  },
                ),
              ),
              Semantics(
                label: 'Logout',
                child: IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onLogout();
                  },
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: safeAreaTop + (kToolbarHeight - 24) / 2,
          left: currentTitleLeft,
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        Positioned(
          top: currentAvatarTop,
          left: currentAvatarLeft,
          child: GestureDetector(
            onTap: progress < 0.5 ? onEditImage : null,
            child: SizedBox(
              width: currentAvatarSize,
              height: currentAvatarSize,
              child: ProfileImageWidget(
                currentImageUrl: profile?.avatarUrl,
                isLoading: isUploadingImage,
                onEditTap: progress < 0.5 ? onEditImage : null,
                radius: currentAvatarRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        minHeight != oldDelegate.minHeight ||
        profile != oldDelegate.profile ||
        isUploadingImage != oldDelegate.isUploadingImage;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ProfileProvider>();
      provider.loadCurrentUserProfile();
      provider.loadPersonalResults();

      // NOTE: a live SubscriptionProvider.checkSubscriptionStatus() call
      // used to fire here on every mount. Because ProfilePage is one of
      // HomePage's IndexedStack children, it mounts the instant HomePage
      // does — including immediately after a successful OTP verify, before
      // the BDApps backend has necessarily finished propagating that same
      // registration to its own "check" endpoint. A transient false/failed
      // response there was overwriting the just-confirmed subscribed state
      // and (via the router's refreshListenable) force-redirecting the user
      // straight back to /landing right after they subscribed. Live
      // re-verification of subscription status should be triggered
      // deliberately (e.g. pull-to-refresh, or on app resume with a grace
      // period since the last confirmed subscribe) rather than on every
      // Profile tab build.
    });
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ProfileProvider>().updateProfileImage(source);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                _updateProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(bottomSheetContext).pop();
                _updateProfileImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnsubscribe() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final authProvider = context.read<AuthProvider>();
    // যেকোনো একটি প্রোভাইডারে নম্বর থাকলেই চলবে — কারণ দুটো আলাদা
    // ক্লাসে ডুপ্লিকেট করে রাখা আছে এবং একটিতে থাকলে অন্যটিতে নাও থাকতে পারে।
    final mobile = subscriptionProvider.phoneNumber.isNotEmpty
        ? subscriptionProvider.phoneNumber
        : (authProvider.mobileNumber ?? '');
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ফোন নম্বর পাওয়া যায়নি, আগে সাবস্ক্রাইব করুন।')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsubscribe?'),
        content: Text(
          'আপনি $mobile নম্বরটি আনসাবস্ক্রাইব করতে চলেছেন।\n'
              'পরে আবার সাবস্ক্রাইব করা যাবে, তবে কুইজ অ্যাক্সেস বন্ধ হয়ে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // SubscriptionProvider is the one that actually holds the phone number
    // used throughout the app's real flow (sendOtp/verifyOtp both go through
    // it), and its unsubscribe() makes the real BDApps unsubscribe.php call.
    // AuthProvider._mobileNumber is only ever set inside
    // AuthProvider.requestOtp(), which nothing in this app calls — so
    // authProvider.unsubscribe() always failed silently without ever
    // hitting the server, while still leaving us to blindly wipe local
    // state below. Call the correct provider instead, and only touch
    // state / navigate when it actually succeeds.
    final ok = await subscriptionProvider.unsubscribe(phoneNumber: mobile);
    if (!mounted) return;

    // Keep AuthProvider's flag in sync too, in case anything else reads it.
    if (ok) {
      authProvider.markUnsubscribed();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'সফলভাবে Unsubscribe হয়েছে।'
              : (subscriptionProvider.errorMessage.isNotEmpty
                  ? subscriptionProvider.errorMessage
                  : 'Unsubscribe ব্যর্থ হয়েছে।'),
        ),
      ),
    );

    if (ok && mounted) {
      // একটা ফ্রেম পরে নেভিগেট করি যাতে SnackBar ও notifyListeners
      // থেকে আসা widget rebuilds-এর সাথে রেস না করে।
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AppRoute.landing);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.userProfile;
    final topSafeArea = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF6B58E9),
      body: Container(
        color: Colors.white,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileHeaderDelegate(
                expandedHeight: 200,
                minHeight: topSafeArea + kToolbarHeight,
                profile: profile,
                isUploadingImage: profileProvider.isUploadingImage,
                onEditImage: _showImageSourceDialog,
                onEditProfile: () {
                  if (profile != null) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) =>
                          EditProfileDialog(currentProfile: profile),
                    );
                  }
                },
                onUnsubscribe: _confirmUnsubscribe,
                onLogout: () {
                  context.read<AuthProvider>().logout();
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 24,
                    right: 24,
                    bottom: 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        profile?.displayName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          profile.bio!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B58E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              Icons.star_border,
                              'POINTS',
                              profile?.score.toString() ?? '0',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(
                              Icons.public,
                              'WORLD RANK',
                              profile?.rank ?? '-',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildStatItem(
                              Icons.local_police_outlined,
                              'LOCAL RANK',
                              '#56',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Text(
                            'Badge',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Stats',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            children: const [
                              Text(
                                'Details',
                                style: TextStyle(
                                  color: Color(0xFF6B58E9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Color(0xFF6B58E9),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent matches',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Selector<ProfileProvider, String>(
                              selector: (_, provider) =>
                              provider.selectedProfileFilter,
                              builder: (context, value, child) {
                                return PopupMenuButton<String>(
                                  initialValue: value,
                                  onSelected: (newValue) {
                                    context
                                        .read<ProfileProvider>()
                                        .selectedProfileFilter = newValue;
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'Daily',
                                      child: Text('Daily'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Monthly',
                                      child: Text('Monthly'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Yearly',
                                      child: Text('Yearly'),
                                    ),
                                    PopupMenuItem(
                                      value: 'All',
                                      child: Text('All'),
                                    ),
                                  ],
                                  child: Row(
                                    children: [
                                      Text(
                                        value,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingPersonalHistory) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final history = provider.personalHistory;

                if (history.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No recent matches found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              context
                                  .read<ProfileProvider>()
                                  .loadPersonalResults();
                            },
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final score = history[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          color: Colors.white,
                          child: ScoreCardWidget(entry: score),
                        );
                      },
                      childCount: history.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Semantics(
        label: 'AI Chat',
        child: FloatingActionButton(
          heroTag: 'profile_ai_chat_fab',
          tooltip: 'AI Chat',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(AppRoute.ai);
          },
          child: const Icon(Icons.bolt, color: Color(0xFF6B58E9)),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}