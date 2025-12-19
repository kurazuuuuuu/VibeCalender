//
//  MainTabView.swift
//  VibeCalender
//
//  Created by Kanaha Noma on 2025/12/17.
//

import SwiftUI

/// メインタブビュー（Liquid Glass - 浮遊タブバー）
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // タブコンテンツ（下部にパディングを追加してタブバーの後ろまでスクロール可能に）
            Group {
                switch selectedTab {
                case 0:
                    WeeklyCalendarView()
                case 1:
                    TimelineView()
                default:
                    WeeklyCalendarView()
                }
            }
            
            // 下部のブラーグラデーション
            VStack(spacing: 0) {
                Spacer()
                
                // ブラーグラデーション（コンテンツがタブバーに近づくにつれてブラー）
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(.systemBackground).opacity(0.3), location: 0.3),
                        .init(color: Color(.systemBackground).opacity(0.7), location: 0.6),
                        .init(color: Color(.systemBackground).opacity(0.95), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .allowsHitTesting(false)
                
                // タブバーの下の余白
                Color(.systemBackground).opacity(0.95)
                    .frame(height: 100)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            
            // Liquid Glass 浮遊タブバー
            floatingTabBar
        }
        .sheet(isPresented: $showAddSheet) {
            AddEventView()
        }
    }
    
    // MARK: - 浮遊 Liquid Glass タブバー
    
    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            // Calendar タブ
            GlassTabButton(
                icon: "calendar",
                title: "Calendar",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            
            Spacer()
            
            // Timeline タブ
            GlassTabButton(
                icon: "clock",
                title: "Timeline",
                isSelected: selectedTab == 1
            ) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
            
            Spacer()
            
            // 追加ボタン（浮遊 Liquid Glass）
            floatingAddButton
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 14)
        .background(
            // 浮遊タブバー背景
            ZStack {
                // メインのガラス効果
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                
                // 上部のハイライト
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // 境界線
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        // 浮遊感を出すシャドウ（複数レイヤー）
        .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - 浮遊追加ボタン
    
    private var floatingAddButton: some View {
        Button(action: { showAddSheet = true }) {
            ZStack {
                // 外側のグローエフェクト
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 58, height: 58)
                    .blur(radius: 4)
                
                // 外側のグラデーションリング
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.9),
                                Color.blue.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 50, height: 50)
                
                // 内側のガラス効果
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                // プラスアイコン
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .shadow(color: .blue.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Liquid Glass タブボタン

struct GlassTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .symbolVariant(isSelected ? .fill : .none)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    : AnyShapeStyle(Color.gray)
            )
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                            
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.08))
                            
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.4),
                                            Color.blue.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                }
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - プレースホルダービュー

/// タイムラインビュー（別担当のため仮実装）
struct TimelineView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 100)
                
                // Liquid Glass風アイコン
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.gray, .gray.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                
                Text("Timeline")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("別担当が実装予定")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 200)
            }
            .frame(maxWidth: .infinity)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// 予定追加ビュー（Liquid Glass適用）
struct AddEventView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Liquid Glass風アイコン
                ZStack {
                    // グローエフェクト
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.5),
                                            Color.purple.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .blue.opacity(0.3), radius: 30, x: 0, y: 15)
                
                VStack(spacing: 12) {
                    Text("勝手に予定追加")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("AIがあなたの傾向から\n予定を生成します")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 生成ボタン（Liquid Glass）
                Button(action: {
                    // TODO: AI予定生成
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("予定を生成")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        }
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("予定追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(EventManager())
}
