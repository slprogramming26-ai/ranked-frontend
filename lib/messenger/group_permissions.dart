import 'messenger_api_service.dart';

// Was ich mit einem anderen Gruppenmitglied machen darf.
enum MemberAction { promote, demote, kick, transfer }

// Welche Aktionen das Info-Sheet beim Tippen auf [target] anbietet.
// Leeres Set = keine Aktionen -> Tippen oeffnet direkt das Profil.
Set<MemberAction> allowedMemberActions({
  required GroupRole myRole,
  required int myUserId,
  required GroupMember target,
}) {
  if (myUserId == target.id || target.role == GroupRole.creator) return const {};
  switch ((myRole, target.role)) {
    case (GroupRole.admin, GroupRole.member):
      return const {MemberAction.kick, MemberAction.promote};
    case (GroupRole.creator, GroupRole.admin):
      return const {MemberAction.demote, MemberAction.transfer, MemberAction.kick};
    case (GroupRole.creator, GroupRole.member):
      return const {MemberAction.transfer, MemberAction.promote, MemberAction.kick};
    default:
      return const {};
  }

}