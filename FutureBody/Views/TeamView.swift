import SwiftUI

struct TeamView: View {
    @StateObject private var friends = FriendsStore()
    @State private var displayNameDraft = ""
    @State private var inviteCode = ""
    @State private var codeToAccept = ""
    @State private var showingInviteCode = false
    @State private var showingError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                identityCard
                inviteCard
                notificationCard
                friendsList
            }
            .padding(20)
        }
        .navigationTitle("仲間")
        .refreshable {
            await friends.reload()
            displayNameDraft = friends.displayName
        }
        .task {
            await friends.reload()
            displayNameDraft = friends.displayName
        }
        .onChange(of: friends.errorMessage) { _, value in
            showingError = value != nil
        }
        .alert("確認してください", isPresented: $showingError) {
            Button("閉じる") {
                friends.errorMessage = nil
            }
        } message: {
            Text(friends.errorMessage ?? "")
        }
        .sheet(isPresented: $showingInviteCode) {
            inviteCodeSheet
                .presentationDetents([.height(300)])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ひとりで始めて、続けるときは一緒に")
                .font(AppFont.regular(15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
            Text("仲間の一歩を見る")
                .font(AppFont.extraBold(28, relativeTo: .title))
            Text("共有するのは完了したことと活動日数だけです。")
                .font(AppFont.regular(14, relativeTo: .body))
                .foregroundStyle(.secondary)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading("あなたの表示名", subtitle: "本名でなく、呼ばれたい名前で大丈夫です")
            HStack(spacing: 10) {
                TextField("表示名", text: $displayNameDraft)
                    .textFieldStyle(.roundedBorder)
                    .font(AppFont.regular(16, relativeTo: .body))
                Button("保存") {
                    Task { await friends.saveDisplayName(displayNameDraft) }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(displayNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .cardSurface()
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading("友達をつなぐ", subtitle: "招待コードを知っている人だけが参加できます")

            Button {
                Task {
                    if let code = await friends.createInviteCode() {
                        inviteCode = code
                        showingInviteCode = true
                    }
                }
            } label: {
                Label("招待コードを作る", systemImage: "person.badge.plus")
            }
            .buttonStyle(PrimaryButtonStyle())

            Divider()

            TextField("相手から届いた8文字のコード", text: $codeToAccept)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .font(AppFont.regular(16, relativeTo: .body))

            Button("友達を追加") {
                Task {
                    await friends.acceptInviteCode(codeToAccept)
                    codeToAccept = ""
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(codeToAccept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .cardSurface()
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("活動日数を友達に表示", isOn: Binding(
                get: { friends.sharingEnabled },
                set: { enabled in
                    Task { await friends.setSharingEnabled(enabled) }
                }
            ))
            .font(AppFont.bold(16, relativeTo: .body))

            Text("共有するのは完了した日数だけです。体重や体調、メニューは表示しません。")
                .font(AppFont.regular(13, relativeTo: .caption))
                .foregroundStyle(.secondary)

            Divider()

            Toggle("友達の完了を知らせる", isOn: Binding(
                get: { friends.notificationsEnabled },
                set: { enabled in
                    Task { await friends.setNotificationsEnabled(enabled) }
                }
            ))
            .font(AppFont.bold(16, relativeTo: .body))

            Text("友達がその日のトレーニングを終えたら、1日1回だけ通知します。")
                .font(AppFont.regular(13, relativeTo: .caption))
                .foregroundStyle(.secondary)
        }
        .cardSurface()
    }

    private var friendsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading("友達の活動", subtitle: friends.friends.isEmpty ? "まずは一人招待してみましょう" : "今日の一歩を、みんなで見守ります")

            if friends.isLoading && friends.friends.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if friends.friends.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2.wave.2")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColor.accent)
                    Text("まだ友達はいません")
                        .font(AppFont.bold(17, relativeTo: .headline))
                    Text("完璧に競うより、続けている人を見つけます。")
                        .font(AppFont.regular(14, relativeTo: .body))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
            } else {
                ForEach(friends.friends) { friend in
                    FriendActivityCard(friend: friend) {
                        Task { await friends.remove(friend) }
                    }
                }
            }
        }
        .cardSurface()
    }

    private var inviteCodeSheet: some View {
        VStack(spacing: 18) {
            Text("このコードを友達に送ってください")
                .font(AppFont.bold(18, relativeTo: .headline))
            Text(inviteCode)
                .font(AppFont.extraBold(34, relativeTo: .title))
                .tracking(5)
                .foregroundStyle(AppColor.accent)
            Text("24時間有効です。")
                .font(AppFont.regular(14, relativeTo: .body))
                .foregroundStyle(.secondary)
            ShareLink(item: inviteCode) {
                Label("コードを共有", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}

private struct FriendActivityCard: View {
    let friend: FriendProfile
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(AppFont.bold(18, relativeTo: .headline))
                    Text(friend.lastWorkoutLabel)
                        .font(AppFont.regular(13, relativeTo: .subheadline))
                        .foregroundStyle(friend.lastWorkoutDate == Self.todayKey ? AppColor.accent : .secondary)
                }
                Spacer()
                Menu {
                    Button("友達を解除", role: .destructive, action: remove)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                metric("連続", value: "(friend.currentStreakDays)日")
                Divider().frame(height: 34)
                metric("累計", value: "(friend.totalWorkoutDays)日")
                Divider().frame(height: 34)
                metric("今週", value: "(friend.weeklyWorkoutDays)日")
            }
        }
        .padding(16)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppFont.regular(12, relativeTo: .caption))
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppFont.bold(16, relativeTo: .body))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }

    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
