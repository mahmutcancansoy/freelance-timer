import Foundation

enum Language: String, CaseIterable, Codable {
    case english = "en"
    case turkish = "tr"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }

    static var preferred: Language {
        if let saved = UserDefaults.standard.string(forKey: "preferredLanguage"),
           let language = Language(rawValue: saved) { return language }
        let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
        return systemLang == "tr" ? .turkish : .english
    }
}

struct Localization {
    static func duration(_ seconds: TimeInterval, lang: Language) -> String {
        let totalMinutes = max(0, Int(seconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let hourUnit = lang == .turkish ? "sa" : "h"
        let minuteUnit = lang == .turkish ? "dk" : "m"
        if hours > 0 { return minutes > 0 ? "\(hours)\(hourUnit) \(minutes)\(minuteUnit)" : "\(hours)\(hourUnit)" }
        return "\(minutes)\(minuteUnit)"
    }

    static func string(for key: String, lang: Language) -> String {
        let dict: [String: [Language: String]] = [
            "dashboard": [.english: "Dashboard", .turkish: "Ana Sayfa"],
            "projects": [.english: "Projects", .turkish: "Projeler"],
            "reports": [.english: "Reports", .turkish: "Raporlar"],
            "settings": [.english: "Settings", .turkish: "Ayarlar"],
            "focus_session": [.english: "Focus Session", .turkish: "Odaklanma Seansı"],
            "new_task": [.english: "New Task", .turkish: "Yeni Görev"],
            "save": [.english: "Finish", .turkish: "Bitir"],
            "cancel": [.english: "Cancel", .turkish: "İptal"],
            "duration": [.english: "Duration", .turkish: "Süre"],
            "recent_tasks": [.english: "Recent Tasks", .turkish: "Son Görevler"],
            "daily_goal": [.english: "Daily Goal", .turkish: "Günlük Hedef"],
            "session_history": [.english: "Session History", .turkish: "Seans Geçmişi"],
            "weekly_activity": [.english: "Weekly Activity", .turkish: "Haftalık Aktivite"],
            "hourly_rate": [.english: "Hourly Rate", .turkish: "Saatlik Ücret"],
            "tag_name": [.english: "Tag Name", .turkish: "Etiket Adı"],
            "tag_color": [.english: "Tag Color", .turkish: "Etiket Rengi"],
            "create_tag": [.english: "Create New Tag", .turkish: "Yeni Etiket Oluştur"],
            "billable": [.english: "BILLABLE", .turkish: "FATURALANABİLİR"],
            "non_billable": [.english: "NON-BILLABLE", .turkish: "FATURALANMAZ"],
            "current_task": [.english: "Current Task:", .turkish: "Mevcut Görev:"],
            "language": [.english: "Language", .turkish: "Dil"],
            "edit": [.english: "Edit", .turkish: "Düzenle"],
            "resting": [.english: "Rest", .turkish: "Dinlenme"],
            "waitingforrest": [.english: "Get Ready", .turkish: "Hazırlan"],
            "focus": [.english: "Focus", .turkish: "Odaklan"],
            "set_daily_goal": [.english: "Set Daily Goal", .turkish: "Günlük Hedef Belirle"],
            "target": [.english: "Target", .turkish: "Hedef"],
            "placeholder_task": [.english: "What are you working on?", .turkish: "Şu an ne üzerine çalışıyorsun?"],
            "min": [.english: "min", .turkish: "dk"],
            "short_break": [.english: "Short Break", .turkish: "Kısa Mola"],
            "long_break": [.english: "Long Break", .turkish: "Uzun Mola"],
            "billing_config": [.english: "Billing Configuration", .turkish: "Faturalandırma Yapılandırması"],
            "general": [.english: "General", .turkish: "Genel"],
            "timer_durations": [.english: "Timer Durations (minutes)", .turkish: "Zamanlayıcı Süreleri (dakika)"],
            "select_tags": [.english: "Select Tags", .turkish: "Etiket Seç"],
            "configure_experience": [.english: "Configure your focus experience", .turkish: "Odaklanma deneyiminizi yapılandırın"],
            "start_focus": [.english: "Start Focus", .turkish: "Odaklanmayı Başlat"],
            "pause": [.english: "Pause", .turkish: "Duraklat"],
            "resume": [.english: "Resume", .turkish: "Devam Et"],
            "stop": [.english: "Stop", .turkish: "Durdur"],
            "open_dashboard": [.english: "Open Dashboard", .turkish: "Paneli Aç"],
            "quit": [.english: "Quit", .turkish: "Kapat"],
            "today": [.english: "Today", .turkish: "Bugün"],
            "yesterday": [.english: "Yesterday", .turkish: "Dün"],
            "sessions": [.english: "Sessions", .turkish: "Seanslar"],
            "earned": [.english: "Earned", .turkish: "Kazanç"],
            "active_projects_tracked": [.english: "active projects tracked", .turkish: "aktif proje takip ediliyor"],
            "no_projects_yet": [.english: "No projects tracked yet.", .turkish: "Henüz takip edilen proje yok."],
            "start_focus_to_see": [.english: "Start a focus session to see your projects here.", .turkish: "Projelerinizi burada görmek için bir odaklanma seansı başlatın."],
            "billable_amount": [.english: "Billable", .turkish: "Faturalanabilir"],
            "time_distribution": [.english: "Time Distribution", .turkish: "Zaman Dağılımı"],
            "total_hours": [.english: "Total Hours", .turkish: "Toplam Saat"],
            "total_earned": [.english: "Total Earned", .turkish: "Toplam Kazanç"],
            "analyze_productivity": [.english: "Analyze your productivity", .turkish: "Verimliliğinizi analiz edin"],
            "time_by_tag": [.english: "Time by Tag", .turkish: "Etikete Göre Süre"],
            "no_data_to_report": [.english: "No data to report yet.", .turkish: "Henüz raporlanacak veri yok."],
            "billable_summary": [.english: "Billable Summary", .turkish: "Faturalandırma Özeti"],
            "total_earned_to_date": [.english: "Total earned to date", .turkish: "Bugüne kadarki toplam kazanç"],
            "history": [.english: "History", .turkish: "Geçmiş"],
            "untimed": [.english: "Untimed", .turkish: "Serbest"],
            "delete": [.english: "Delete", .turkish: "Sil"],
            "break_history": [.english: "Break History", .turkish: "Mola Geçmişi"],
            "sessions_only": [.english: "Sessions", .turkish: "Seanslar"],
            "breaks_only": [.english: "Breaks", .turkish: "Molalar"],
            "all": [.english: "All", .turkish: "Tümü"],
            "no_history": [.english: "No history found.", .turkish: "Geçmiş bulunamadı."],
            "confirm_delete": [.english: "Are you sure you want to delete this session?", .turkish: "Bu seansı silmek istediğinize emin misiniz?"],
            "menu": [.english: "Menu", .turkish: "Menü"],
            "tags": [.english: "Tags", .turkish: "Etiketler"],
            "goal_reached": [.english: "Daily goal reached!", .turkish: "Günlük hedefe ulaşıldı!"],
            "remaining_to_goal": [.english: "remaining to reach your goal", .turkish: "hedefinize ulaşmak için kalan süre"],
            "entries_found": [.english: "entries found", .turkish: "kayıt bulundu"],
            "project_details": [.english: "Project Details", .turkish: "Proje Detayları"],
            "total_focus": [.english: "Total Focus", .turkish: "Toplam Odaklanma"],
            "total_break": [.english: "Total Break", .turkish: "Toplam Mola"],
            "total_focused_time": [.english: "Total focused time", .turkish: "Toplam odaklanma süresi"],
            "tasks_completed": [.english: "Tasks completed", .turkish: "Tamamlanan görevler"],
            "billable_amount_stats": [.english: "Billable amount", .turkish: "Faturalanabilir tutar"],
            "today_stats": [.english: "Today", .turkish: "Bugün"],
            "pending_stats": [.english: "Pending", .turkish: "Beklemede"],
            "add_break": [.english: "Add Break", .turkish: "Mola Ekle"],
            "start_break": [.english: "Start Break", .turkish: "Molayı Başlat"],
            "idle": [.english: "Ready", .turkish: "Hazır"],
            "focusing": [.english: "Focusing", .turkish: "Odaklanıyor"],
            "paused": [.english: "Paused", .turkish: "Duraklatıldı"],
            "recent_activity": [.english: "Recent Activity", .turkish: "Son Etkinlik"],
            "no_recent_activity": [.english: "No recent activity.", .turkish: "Henüz etkinlik yok."],
            "create": [.english: "Create", .turkish: "Oluştur"],
            "reset": [.english: "Reset", .turkish: "Sıfırla"],
            "skip": [.english: "Skip", .turkish: "Atla"],
            "focus_complete": [.english: "Focus Session Complete! 🎯", .turkish: "Odaklanma Seansı Tamamlandı! 🎯"],
            "long_break_ready": [.english: "Great work! Ready for a long break?", .turkish: "Harika iş! Uzun bir molaya hazır mısın?"],
            "short_break_ready": [.english: "Nice focus! Ready for a short break?", .turkish: "Güzel odaklandın! Kısa bir molaya hazır mısın?"],
            "break_complete": [.english: "Break's Over! 💪", .turkish: "Mola Bitti! 💪"],
            "ready_to_focus": [.english: "Ready to focus? Let's get back to work.", .turkish: "Odaklanmaya hazır mısın? İşe dönelim."],
            "session_deleted": [.english: "Session deleted.", .turkish: "Seans silindi."],
            "focus_completed_waiting": [.english: "Focus session completed. Waiting for manual break start.", .turkish: "Odaklanma seansı tamamlandı. Mola başlatmanız bekleniyor."],
            "now": [.english: "Now", .turkish: "Şimdi"]
        ]

        return dict[key]?[lang] ?? dict[key]?[.english] ?? key
    }
}
