// Views/Settings/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dailyNewWordGoal") private var dailyGoal = 10

    @State private var showMakeupAlert = false
    @State private var makeupMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // 学习目标
                Section("学习设置") {
                    Stepper("每日新词目标: \(dailyGoal)", value: $dailyGoal, in: 5...50, step: 5)
                }

                // 补签
                Section("打卡") {
                    Button("补签 (今日)") {
                        let manager = StreakManager(modelContainer: modelContext.container)
                        let remaining = manager.remainingMakeups()
                        if remaining > 0 {
                            manager.checkIn(isMakeup: true)
                            makeupMessage = "补签成功！本月剩余 \(remaining - 1) 次"
                        } else {
                            makeupMessage = "本月补签次数已用完"
                        }
                        showMakeupAlert = true
                    }
                }

                // 已购课程
                Section("已购课程") {
                    Text("已购课程列表（待实现）")
                        .foregroundColor(.secondary)
                }

                // iCloud
                Section("同步") {
                    Toggle("iCloud 同步", isOn: .constant(true))
                        .disabled(true) // 完整版开启
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
            .alert("补签", isPresented: $showMakeupAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(makeupMessage)
            }
        }
    }
}
