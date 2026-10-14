// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ranked';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment or bullying';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonMisinformation => 'Misinformation';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportTitlePost => 'Report post';

  @override
  String get reportTitleStory => 'Report story';

  @override
  String get reportTitleComment => 'Report comment';

  @override
  String get reportTitleUser => 'Report profile';

  @override
  String get reportSuccessPost => 'Thanks! You won\'t see this post anymore.';

  @override
  String get reportSuccessStory => 'Thanks! You won\'t see this story anymore.';

  @override
  String get reportSuccessComment =>
      'Thanks! You won\'t see this comment anymore.';

  @override
  String get reportSuccessUser => 'Thanks! We\'ll look into it.';

  @override
  String get reportAlreadyPost => 'You already reported this post.';

  @override
  String get reportAlreadyStory => 'You already reported this story.';

  @override
  String get reportAlreadyComment => 'You already reported this comment.';

  @override
  String get reportAlreadyUser => 'You already reported this profile.';

  @override
  String get reportDetailsHint => 'What happened? (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportFailed => 'Report failed. Please try again later.';

  @override
  String get commentDeleteTitle => 'Delete comment?';

  @override
  String get commentDeleteMessage => 'The comment will be removed permanently.';

  @override
  String get commentDeleteConfirm => 'Delete';

  @override
  String get commentDeleteFailed =>
      'Couldn\'t delete the comment. Please try again later.';

  @override
  String get profileMenuReport => 'Report';

  @override
  String get profileMenuModeration => 'Moderation';

  @override
  String profileBlocked(String name) {
    return '$name has been blocked.';
  }

  @override
  String get profileBlockFailed => 'Blocking failed. Please try again.';

  @override
  String get postDeleteFailed =>
      'Couldn\'t delete the post. Please try again later.';

  @override
  String get messengerGroupCreateFailed => 'Failed to create the group.';

  @override
  String get messengerJoinFailed => 'Couldn\'t join. Is the code still valid?';

  @override
  String get messengerJoinGroupTitle => 'Join group';

  @override
  String get messengerJoinGroupSubtitle => 'Join with an invite code';

  @override
  String get messengerInviteCodeHint => 'Invite code';

  @override
  String get messengerCancel => 'Cancel';

  @override
  String get messengerJoin => 'Join';

  @override
  String get messengerNewConversation => 'New conversation';

  @override
  String get messengerStartChat => 'Start chat';

  @override
  String get messengerStartChatSubtitle => 'Search for a user by name';

  @override
  String get messengerCreateGroup => 'Create group';

  @override
  String get messengerCreateGroupSubtitle => 'Set up a new group';

  @override
  String get messengerContactsTitle => 'Contacts';

  @override
  String get messengerRequests => 'Requests';

  @override
  String get messengerGroupChat => 'Group chat';

  @override
  String get messengerDirectMessage => 'Direct message';

  @override
  String get messengerEmptyTitle => 'No conversations';

  @override
  String get messengerEmptyHint =>
      'Tap the pencil icon\nto start a chat or a group.';

  @override
  String get messengerSearchUsernameHint => 'Search username';

  @override
  String get messengerMinChars => 'Enter at least 2 characters';

  @override
  String get messengerSomethingWrong => 'Something went wrong.';

  @override
  String get messengerNoUsersFound => 'No users found';

  @override
  String get chatRequestsWantsToWrite => 'Wants to message you';

  @override
  String get chatRequestsEmptyTitle => 'All caught up';

  @override
  String get chatRequestsEmptyHint => 'No open chat requests.';

  @override
  String get chatEncrypted => 'End-to-end encrypted';

  @override
  String get chatPostUnavailable => 'Post unavailable';

  @override
  String get chatUnknownUser => 'Unknown';

  @override
  String get chatGroupInvite => 'Group invite';

  @override
  String chatInviteCode(int code) {
    return 'Code $code';
  }

  @override
  String get chatJoined => 'Joined';

  @override
  String get chatMessageHint => 'Message…';

  @override
  String get chatAcceptToReply => 'Accept the request to be able to reply.';

  @override
  String get chatDecline => 'Decline';

  @override
  String get chatAccept => 'Accept';

  @override
  String get chatDeclineDialogTitle => 'Decline request?';

  @override
  String chatDeclineDialogBody(String username) {
    return 'The chat will be removed from your list. Unless you block them, $username can send you a new request.';
  }

  @override
  String get chatDeclineAndBlock => 'Decline & block';

  @override
  String get chatDeclined => 'Request declined.';

  @override
  String chatDeclinedAndBlocked(String name) {
    return 'Request declined and $name blocked.';
  }

  @override
  String get chatDeclinedBlockFailed =>
      'Request declined, but blocking failed.';

  @override
  String get chatEmptyTitle => 'Say hi! 👋';

  @override
  String get chatEmptyHint =>
      'No messages yet.\nSend the first one and break the ice.';

  @override
  String chatInfoBlockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get chatInfoBlockMessage =>
      'You won\'t be able to message each other anymore. You can unblock them later.';

  @override
  String get chatInfoBlock => 'Block';

  @override
  String get chatInfoOpenProfile => 'Open profile';

  @override
  String chatInfoLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get chatInfoLeaveMessage =>
      'You won\'t receive new messages from this group anymore. You can rejoin anytime with an invite.';

  @override
  String get chatInfoLeave => 'Leave';

  @override
  String get chatInfoMembers => 'Members';

  @override
  String get chatInfoInvite => 'Invite';

  @override
  String get chatInfoLeaveGroup => 'Leave group';

  @override
  String get chatInfoMembersLoadFailed => 'Couldn\'t load members.';

  @override
  String get chatInfoYou => 'You';

  @override
  String get chatInfoInviteCodeNote =>
      'Only valid for a limited time. Anyone who enters the code joins the group.';

  @override
  String get chatInfoShareInChat => 'Share in chat';

  @override
  String get chatInfoCopyCode => 'Copy code';

  @override
  String get onboardingWelcomeTitle => 'Welcome to\nthe Pulse';

  @override
  String get onboardingWelcomeSubtitle =>
      'The world\'s first editorial social feed where your energy matters.';

  @override
  String get onboardingWelcomePostTitle => 'Post your life';

  @override
  String get onboardingWelcomePostSub =>
      'Share your daily Pulse. Authentic and raw.';

  @override
  String get onboardingWelcomeRankTitle => 'Get Ranked';

  @override
  String get onboardingWelcomeRankSub =>
      'The community evaluates your creativity.';

  @override
  String get onboardingWelcomeEarnTitle => 'Earn and customize';

  @override
  String get onboardingWelcomeEarnSub =>
      'Rank others to earn coins. Unlock exclusive avatar items and \"Freundebuch\" skins';

  @override
  String get onboardingVibeTitle => 'What\'s Your Vibe?';

  @override
  String get onboardingVibeSubtitle =>
      'Pick up to 2 Pulse Factors that define your daily rhythm — or none at all. Share only what you want to share.';

  @override
  String get onboardingAboutMeTitle => 'The Digital Pulse';

  @override
  String get onboardingAboutMeSubtitle =>
      'Let others feel your energy. This is your curated scrapbook entry.';

  @override
  String get onboardingAboutMeStoryLabel => 'YOUR STORY';

  @override
  String get onboardingAboutMeBioHint =>
      'Share your story, your goals, or what makes you unique...';

  @override
  String get onboardingAgeTitle => 'One Last Check';

  @override
  String get onboardingAgeSubtitle =>
      'How old are you? We only check this once — your age is never stored.';

  @override
  String get onboardingAgeWarning =>
      'Ranked is 16+. We\'d love to see you again in a few years!';

  @override
  String get onboardingCredentialsTitle => 'Join the';

  @override
  String get onboardingCredentialsSubtitle =>
      'Last step — pick your login and your profile goes live.';

  @override
  String get onboardingCredentialsEmailHint => 'Email Address';

  @override
  String get onboardingCredentialsUsernameHint => 'username';

  @override
  String get onboardingCredentialsPasswordHint => 'Password';

  @override
  String get onboardingCredentialsLegal =>
      'By signing up, you agree to our Community Guidelines';

  @override
  String get onboardingNextButton => 'Next';

  @override
  String get onboardingCreateButton => 'Create Account';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingLoadingSetup => 'Setting up your account';

  @override
  String get onboardingLoadingCreating => 'Creating your account...';

  @override
  String get onboardingLoadingSigning => 'Signing you in...';

  @override
  String get onboardingLoadingSecuring => 'Securing your chats...';

  @override
  String get onboardingLoadingUploading => 'Uploading your photo...';

  @override
  String get onboardingLoadingAlmost => 'Almost there...';

  @override
  String get onboardingImageProcessError =>
      'Your profile picture could not be processed — you can update it in your profile later.';

  @override
  String get onboardingLoginFailedAuto =>
      'Your account was created, but automatic login failed. Please sign in on the login screen.';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginSubtitle => 'The pulse is waiting for you.';

  @override
  String get loginEmailLabel => 'Email Address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Login to Feed';

  @override
  String get loginDivider => 'OR CONTINUE WITH';

  @override
  String get loginGoogle => 'Google';

  @override
  String get loginApple => 'Apple';

  @override
  String get loginNoAccount => 'New to Ranked?';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get loginInvalidCredentials => 'Invalid email or password';

  @override
  String get loginAborted => 'Login cancelled.';

  @override
  String get loginServerError =>
      'Connection to server failed. Please try again.';

  @override
  String get postCommentSectionTitle => 'Comments';

  @override
  String get postCommentsLoadError => 'Failed to load comments';

  @override
  String get postBeFirstToPulse => 'Be the first to pulse!';

  @override
  String get postCommentHint => 'Write a comment...';

  @override
  String get postEditButton => 'Edit Post';

  @override
  String get postDeleteButton => 'Delete Post';

  @override
  String get postReportButton => 'Report Post';

  @override
  String get shareMessengerNotReady =>
      'Messenger not ready — please wait a moment and try again.';

  @override
  String get shareSheetTitle => 'Share';

  @override
  String get shareNoChats => 'No chats to share with yet.';

  @override
  String get shareCopyLink => 'Copy link';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String shareSentTo(String username) {
    return 'Sent to $username!';
  }

  @override
  String get feedLocationSaveError => 'Failed to save location';

  @override
  String get feedForYou => 'For You';

  @override
  String get feedLocal => 'Local';

  @override
  String get feedNoLocationTitle => 'No location set';

  @override
  String get feedNoPostsTitle => 'Nothing here yet';

  @override
  String get feedChooseLocationHint =>
      'Choose your location to see posts in your area.';

  @override
  String get feedNoPostsHint =>
      'Nothing has been posted at your location yet — be the first!';

  @override
  String get feedChooseLocation => 'Choose location';

  @override
  String get storyRowYourPulse => 'Your Pulse';

  @override
  String get createPostTitle => 'Create Post';

  @override
  String get locationPickerTitle => 'Choose location';

  @override
  String get locationSearchHint => 'Search city…';

  @override
  String get locationSearchStartHint => 'Type to search your city';

  @override
  String get locationNotFound => 'No location found — try a different spelling';

  @override
  String get rankingOptinTitle => 'JOIN THE\nRANKING';

  @override
  String get rankingOptinDescription =>
      'Enable ranking and let the community rate you daily — Productivity, Creativity & Engagement.';

  @override
  String get rankingOptinButton => 'ACTIVATE';

  @override
  String get rankingStatsHeader => 'YOUR STATS';

  @override
  String get rankingPointsToday => 'POINTS TODAY';

  @override
  String get rankingStreakLabel => 'YOUR STREAK';

  @override
  String get rankingEvaluatingLabel => 'YOU\'RE RATING';

  @override
  String get rankingYourBadge => 'YOU';

  @override
  String get rankingNoPointsHeadline => 'No points yet today';

  @override
  String get rankingNoPointsSubline => 'Post to get rated';

  @override
  String get rankingLeadingHeadline => 'You\'re leading today!';

  @override
  String get rankingLeadingSubline => 'Defend your position';

  @override
  String rankingMyRank(int rank) {
    return 'Rank #$rank';
  }

  @override
  String get rankingEmptyLeaderboard => 'No rankings yet today';

  @override
  String get rankingAlreadyRankedButton => 'ALREADY RATED TODAY';

  @override
  String get rankingGetPartnerButton => 'GET YOUR RANKED PARTNER';

  @override
  String get rankingNoParticipants =>
      'No participants available to rate right now.';

  @override
  String get rankingSwipeLike => 'LIKE';

  @override
  String get rankingSwipeNope => 'NOPE';

  @override
  String get rankingResultLabel => 'POINTS AWARDED';

  @override
  String get rankingResultDone => 'DONE';

  @override
  String get rankingAlreadyVotedHeadline => 'ALREADY\nVOTED';

  @override
  String get rankingErrorHeadline => 'ERROR';

  @override
  String get rankingAlreadyVotedMessage =>
      'You\'ve already voted today.\nYou can vote again tomorrow!';

  @override
  String get rankingErrorMessage =>
      'Something went wrong. Please try again later.';

  @override
  String get rankingBackButton => 'BACK';

  @override
  String get profileNoActivity =>
      'No activity yet – once someone rates you, it will show up here.';

  @override
  String get profileActivityRated => 'You were rated';

  @override
  String get profileActivityDefault => 'New activity';

  @override
  String profileActivityRatedSubtitle(int points) {
    return 'Received +$points points from the community';
  }

  @override
  String get profileLeagueMaxReached => 'Highest league reached';

  @override
  String profileLeagueProgress(int xp, String next) {
    return 'Still $xp XP until $next';
  }

  @override
  String get profileFollow => 'Follow';

  @override
  String get profileFollowing => 'Following';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeSubtitle => 'Dark appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System language';

  @override
  String get settingsLanguageSystemHint => 'Follows your phone\'s language';

  @override
  String get settingsSectionProfile => 'PROFILE';

  @override
  String get settingsLocation => 'Location';

  @override
  String get settingsLocationLoading => 'Loading…';

  @override
  String get settingsLocationNotSet => 'No location set';

  @override
  String get settingsRemoveLocation => 'Remove location';

  @override
  String get settingsLocationFailed => 'Failed to save location.';

  @override
  String get settingsClearLocationTitle => 'Remove location?';

  @override
  String get settingsClearLocationMessage =>
      'Without a location, you won\'t be able to use the local feed until you select a location again.';

  @override
  String get settingsClearLocationButton => 'Remove';

  @override
  String get settingsClearLocationError =>
      'Failed to remove. Please try again.';

  @override
  String get settingsSectionPrivacy => 'PRIVACY';

  @override
  String get settingsBlockedAccounts => 'Blocked accounts';

  @override
  String get settingsBlockedAccountsSubtitle => 'View and remove blocks';

  @override
  String get blockedTitle => 'Blocked accounts';

  @override
  String get blockedEmpty => 'You haven\'t blocked anyone.';

  @override
  String get blockedLoadFailed => 'Couldn\'t load the list.';

  @override
  String get blockedRetry => 'Try again';

  @override
  String blockedSince(String date) {
    return 'Blocked on $date';
  }

  @override
  String get blockedUnblock => 'Unblock';

  @override
  String blockedUnblockTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String blockedUnblockMessage(String name) {
    return '$name will be able to message you and see your content again.';
  }

  @override
  String blockedUnblocked(String name) {
    return '$name is no longer blocked.';
  }

  @override
  String get blockedUnblockFailed => 'Couldn\'t unblock. Please try again.';

  @override
  String get settingsSectionLegal => 'LEGAL';

  @override
  String get settingsPrivacy => 'Privacy (GDPR)';

  @override
  String get settingsPrivacySubtitle => 'How we handle your data';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsLogoutTitle => 'Log out?';

  @override
  String get settingsLogoutMessage =>
      'You will be logged out from this device.';

  @override
  String get settingsDeleteAccountTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountMessage =>
      'Your account, all posts, votes and comments will be permanently deleted. This cannot be undone.';

  @override
  String get settingsDeleteAccountButton => 'Delete permanently';

  @override
  String get settingsDeleteFailed => 'Deletion failed. Please try again later.';

  @override
  String get settingsCancelButton => 'Cancel';

  @override
  String get settingsDsgvoTitle => 'Privacy';

  @override
  String get searchClearHistoryTitle => 'Clear search history?';

  @override
  String get searchClearHistoryMessage =>
      'This will remove all recent searches from this device.';

  @override
  String get searchCancelButton => 'Cancel';

  @override
  String get searchClearButton => 'Clear';

  @override
  String get searchPlaceholder => 'Search users';

  @override
  String get searchNoUsersFound => 'No users found';

  @override
  String get searchMinCharacters => 'Type at least 2 characters';

  @override
  String get searchHistoryRecent => 'Recent';

  @override
  String get searchHistoryEmpty => 'No recent searches';

  @override
  String get searchHistoryEmptyMessage =>
      'Start exploring – your last searches\nwill show up here.';

  @override
  String get keyRestoreTitle => 'Restore chats';

  @override
  String get keyRestoreMessage =>
      'Your chats were backed up with a different password. Enter your previous password to restore them.';

  @override
  String get keyRestorePasswordLabel => 'Previous password';

  @override
  String get keyRestoreWrongPassword => 'Password doesn\'t match. Try again.';

  @override
  String get keyRestoreButton => 'Restore';

  @override
  String get keyRestoreCancelButton => 'Cancel';

  @override
  String get keyRestoreForgotPassword => 'Forgot password? Reset chats';

  @override
  String get keyRestoreResetTitle => 'Reset chats?';

  @override
  String get keyRestoreResetMessage =>
      'This cannot be undone. Please read what happens:';

  @override
  String get keyRestoreResetConsequence1 =>
      'Your previous messages will no longer be readable on any device.';

  @override
  String get keyRestoreResetConsequence2 =>
      'Other signed-in devices will be logged out.';

  @override
  String get keyRestoreResetConsequence3 => 'New chats will work normally.';

  @override
  String get keyRestoreResetButton => 'Reset chats';

  @override
  String get appDraftRestoreTitle => 'Restore draft?';

  @override
  String get appDraftRestoreMessage => 'You have an unfinished post.';

  @override
  String get appDraftDiscardButton => 'Discard';

  @override
  String get appDraftRestoreButton => 'Restore';

  @override
  String get storyDeleteFailedSnackbar => 'Failed to delete story';

  @override
  String get storyYourStory => 'Your story';

  @override
  String get storyDeleteTitle => 'Delete story';

  @override
  String get storyDeleteCancel => 'Cancel';

  @override
  String get storyProcessingError => 'Image could not be processed';

  @override
  String get storyUploadError => 'Upload failed';

  @override
  String get storyCreateTitle => 'New story';

  @override
  String get storyShareMoment => 'Share your moment';

  @override
  String get storyCreateDescription =>
      'Create a story for your followers in seconds.';

  @override
  String get storyVisibleTime => 'Visible for 24H';

  @override
  String get storySourceGallery => 'Gallery';

  @override
  String get storySourceGallerySubtitle => 'Choose image';

  @override
  String get storySourceCamera => 'Camera';

  @override
  String get storySourceCameraSubtitle => 'Take photo';

  @override
  String get storyUploadingButton => 'Sharing...';

  @override
  String get storyShareButton => 'Share story';

  @override
  String get suspendedTitle => 'Account suspended';

  @override
  String suspendedUntil(String date) {
    return 'Your account is suspended until $date.';
  }

  @override
  String get suspendedPermanent =>
      'Your account has been permanently suspended.';

  @override
  String get suspendedReasonLabel => 'REASON';

  @override
  String get suspendedHint => 'After that, you can log in as usual again.';

  @override
  String get suspendedBack => 'Back to login';

  @override
  String get settingsSectionModeration => 'MODERATION';

  @override
  String get settingsModeration => 'Moderation';

  @override
  String get settingsModerationSubtitle => 'Review reports';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationTabReports => 'Reports';

  @override
  String get moderationTabAudit => 'Audit log';

  @override
  String get moderationFilterPending => 'Open';

  @override
  String get moderationFilterDismissed => 'Dismissed';

  @override
  String get moderationFilterActionTaken => 'Action taken';

  @override
  String get moderationEmptyPending => 'No open reports. All clear!';

  @override
  String get moderationEmptyDismissed => 'No dismissed reports yet.';

  @override
  String get moderationEmptyActionTaken => 'No resolved reports yet.';

  @override
  String get moderationLoadFailed => 'Couldn\'t load the reports.';

  @override
  String get moderationRetry => 'Try again';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String moderationLastReported(String date) {
    return 'last $date';
  }

  @override
  String get moderationBanned => 'Banned';

  @override
  String get moderationBannedPermanent => 'Permanently banned';

  @override
  String get moderationContentDeleted =>
      'Deleted by the user – snapshot from the report';

  @override
  String get moderationNoPreview => 'No preview available';

  @override
  String moderationShowDetails(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count notes',
      one: 'Show 1 note',
    );
    return '$_temp0';
  }

  @override
  String get moderationHideDetails => 'Hide notes';

  @override
  String get moderationDismiss => 'No violation';

  @override
  String get moderationTakeAction => 'Take action';

  @override
  String get moderationActionSheetTitle => 'What do you want to do?';

  @override
  String get moderationActionRemoveHint =>
      'Hidden for everyone. The reports count as handled.';

  @override
  String get moderationActionRemovePictureHint =>
      'Name and bio stay. The reports stay open.';

  @override
  String get moderationActionBanHint =>
      'They\'re logged out and can\'t log in until the ban ends. The reports stay open.';

  @override
  String get moderationActionMarkDoneHint =>
      'E.g. if it\'s already been handled another way. The card moves to “Action taken”.';

  @override
  String get moderationActionRestricted =>
      'Same or higher role than you. You can only mark the reports as done.';

  @override
  String get moderationMarkDone => 'Just mark as done';

  @override
  String get moderationResolveFailed =>
      'Couldn\'t save that. Please try again.';

  @override
  String get moderationRemoveTitlePost => 'Remove post';

  @override
  String get moderationRemoveTitleComment => 'Remove comment';

  @override
  String get moderationRemoveTitleStory => 'Remove story';

  @override
  String get moderationRemoveTitleProfilePicture => 'Remove profile picture';

  @override
  String get moderationRemoveReasonLabel => 'Reason';

  @override
  String get moderationRemoveDetailsHint =>
      'Explanation for the person (optional)';

  @override
  String get moderationRemoveHint =>
      'Hidden for everyone right away. An admin can restore it for 180 days.';

  @override
  String get moderationRemoveConfirm => 'Remove';

  @override
  String moderationBanTitle(String username) {
    return 'Ban $username';
  }

  @override
  String get moderationBanDurationLabel => 'Duration';

  @override
  String moderationBanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get moderationBanPermanent => 'Permanent';

  @override
  String get moderationBanReasonLabel => 'Reason';

  @override
  String get moderationBanReasonHint =>
      'The person sees this text when logging in';

  @override
  String get moderationBanHintNew =>
      'The person will be logged out right away.';

  @override
  String get moderationBanHintReplace => 'Replaces the current ban.';

  @override
  String get moderationBanConfirm => 'Ban';

  @override
  String get moderationUnban => 'Unban';

  @override
  String moderationUserBanned(String username) {
    return '$username has been banned';
  }

  @override
  String get moderationForbidden => 'You don\'t have permission to do that';

  @override
  String get moderationActionFailed => 'Action failed. Please try again.';

  @override
  String moderationUnbanTitle(String username) {
    return 'Unban $username?';
  }

  @override
  String get moderationUnbanMessage => 'They can log in again right away.';

  @override
  String moderationUserUnbanned(String username) {
    return '$username has been unbanned';
  }

  @override
  String get moderationContentRemoved => 'Content removed';

  @override
  String get moderationPictureRemoved =>
      'Profile picture removed. The reports stay open.';

  @override
  String get accountStatusTitle => 'Account status';

  @override
  String get accountStatusEmpty => 'There are no actions against your account.';

  @override
  String get accountStatusLoadFailed => 'Couldn\'t load your account status.';

  @override
  String get accountStatusRemovedPost => 'Post removed';

  @override
  String get accountStatusRemovedComment => 'Comment removed';

  @override
  String get accountStatusRemovedStory => 'Story removed';

  @override
  String get accountStatusRemovedPicture => 'Profile picture removed';

  @override
  String accountStatusBanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Account banned for $count days',
      one: 'Account banned for 1 day',
    );
    return '$_temp0';
  }

  @override
  String get accountStatusBannedPermanent => 'Account permanently banned';

  @override
  String get accountStatusRestored => 'Restored';

  @override
  String get accountStatusReasonLabel => 'Reason';

  @override
  String get accountStatusNoteLabel => 'Note from the moderators';

  @override
  String get accountStatusSnapshotLabel => 'Your content';

  @override
  String get settingsAccountStatusSubtitle => 'Removed content and bans';

  @override
  String get profileActivityContentRemoved => 'Content removed';

  @override
  String get profileActivityContentRestored => 'Content restored';

  @override
  String get profileActivityModerationSubtitle => 'Tap for details';

  @override
  String accountStatusLifted(String date) {
    return 'Lifted early on $date';
  }

  @override
  String get profileActivityAccountUnbanned => 'Suspension lifted';

  @override
  String get userDetailTitle => 'Account';

  @override
  String get userDetailForbidden =>
      'You\'re not allowed to moderate this account.';

  @override
  String get userDetailNotFound => 'This account no longer exists.';

  @override
  String get userDetailLoadFailed => 'Couldn\'t load this account.';

  @override
  String get userDetailRoleUser => 'User';

  @override
  String get userDetailRoleModerator => 'Moderator';

  @override
  String get userDetailRoleAdmin => 'Admin';

  @override
  String userDetailMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String userDetailBannedUntil(String date) {
    return 'Banned until $date';
  }

  @override
  String get userDetailReportsPending => 'Open reports';

  @override
  String get userDetailReportsTotal => 'Total reports';

  @override
  String get userDetailRecentActions => 'Recent actions';

  @override
  String get userDetailNoActions => 'No actions yet.';

  @override
  String get userDetailLogBan => 'Account banned';

  @override
  String get userDetailLogUnban => 'Ban lifted';

  @override
  String get userDetailLogDismissed => 'Reports dismissed';

  @override
  String get userDetailLogResolved => 'Reports resolved';

  @override
  String userDetailLogRoleChange(String oldRole, String newRole) {
    return 'Role changed: $oldRole → $newRole';
  }

  @override
  String get userDetailLogRestored => 'Content restored';

  @override
  String get userDetailLogUnknown => 'Unknown action';

  @override
  String userDetailLogBy(String username) {
    return 'by $username';
  }

  @override
  String get userDetailLogDeletedModerator => 'by a deleted account';

  @override
  String get userDetailLogSnapshotLabel => 'Content';

  @override
  String auditLogAgainst(String username) {
    return 'against $username';
  }

  @override
  String get auditEmpty => 'No moderation actions yet.';

  @override
  String get auditEmptyFiltered => 'No entries for this filter.';

  @override
  String get auditRestore => 'Restore';

  @override
  String get auditRestoreTitle => 'Restore content?';

  @override
  String get auditRestoreMessage =>
      'It will be visible to everyone again. The person will be notified.';

  @override
  String get auditRestored => 'Restored';

  @override
  String get auditRestoredNoLocation =>
      'Restored, but without location (the location no longer exists)';

  @override
  String get auditRestoreGone =>
      'Can\'t be restored anymore: already restored or the deadline has passed';

  @override
  String get auditRestoreConflictComment =>
      'The post of this comment no longer exists. Restore the post first.';

  @override
  String get auditRestoreConflictStory =>
      'The story has expired in the meantime.';

  @override
  String get auditRestoreConflictPicture =>
      'The person has uploaded a new profile picture in the meantime.';

  @override
  String get auditRestoreConflict => 'This content can\'t be restored.';

  @override
  String get auditRestoreForbidden =>
      'You\'re not allowed to moderate this person.';

  @override
  String get auditRestoreFailed => 'Restore failed';

  @override
  String get auditFilterAll => 'All';

  @override
  String get auditFilterBans => 'Bans';

  @override
  String get auditFilterRemovals => 'Removed';

  @override
  String get auditFilterResolved => 'Reports';

  @override
  String get auditFilterRoles => 'Roles';

  @override
  String get auditFilterRestored => 'Restored';

  @override
  String get auditLogDeletedTarget => 'against a deleted account';

  @override
  String get userDetailChangeRole => 'Change role';

  @override
  String userDetailRoleChanged(String username, String role) {
    return '$username is now $role';
  }

  @override
  String roleSheetTitle(String username) {
    return 'Role of $username';
  }

  @override
  String get roleSheetUserHint => 'Regular account without moderation rights.';

  @override
  String get roleSheetModeratorHint =>
      'Reviews reports, removes content and bans for up to 30 days.';

  @override
  String get roleSheetCurrent => 'Current';

  @override
  String get roleSheetBannedHint => 'Banned accounts can\'t be promoted.';

  @override
  String get roleSheetReasonLabel => 'Reason (optional)';

  @override
  String get roleSheetReasonHint => 'Shown in the moderation log';

  @override
  String messengerGroupCreated(int id) {
    return 'Group $id created!';
  }

  @override
  String messengerGroupJoined(int id) {
    return 'Joined group $id!';
  }

  @override
  String get chatInfoPictureProcessFailed => 'Couldn\'t process the image.';

  @override
  String get chatInfoPictureOnlyCreator =>
      'Only the group\'s creator can change the picture.';

  @override
  String get chatInfoPictureUploadFailed => 'Upload failed. Please try again.';

  @override
  String get chatInfoPictureUpdated => 'Group picture updated.';

  @override
  String get chatInfoInviteCodeFailed =>
      'Couldn\'t create a code. Please try again.';

  @override
  String get chatInfoLeftGroup => 'You left the group.';

  @override
  String get chatInfoLeaveFailed =>
      'Couldn\'t leave the group. Please try again.';

  @override
  String get chatInfoCodeCopied => 'Code copied!';

  @override
  String get chatGroupJoinedHint =>
      'Joined! You\'ll find the group in your chat list.';

  @override
  String get createPostImageProcessFailed => 'Couldn\'t process the image';

  @override
  String get createPostImageUploadFailed => 'Image upload failed';

  @override
  String get createPostFailed => 'Couldn\'t create the post';

  @override
  String get createPostSomethingWrong => 'Something went wrong';

  @override
  String messengerRequestsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people want to message you',
      one: '1 person wants to message you',
    );
    return '$_temp0';
  }

  @override
  String rankingStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String rankingRatingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count RATINGS',
      one: '1 RATING',
    );
    return '$_temp0';
  }

  @override
  String rankingPointsToNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more points to the next rank',
      one: '1 more point to the next rank',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get timeToday => 'Today';

  @override
  String get timeYesterday => 'Yesterday';
}
