import Foundation

enum Strings {
    static let table: [String: [AppLanguage: String]] = [

        // MARK: - Accessibility
        "permission.title": [
            .en: "Accessibility Access Needed",
            .ru: "Нужен доступ к Универсальному доступу",
        ],
        "permission.body": [
            .en: """
            BetterClipboard uses Accessibility access only to detect a double ⌘ press.

            Your data is never sent anywhere.
            """,
            .ru: """
            BetterClipboard использует Универсальный доступ только для обнаружения двойного нажатия ⌘.

            Данные никуда не отправляются.
            """,
        ],
        "permission.openSettings": [
            .en: "Open System Settings",
            .ru: "Открыть Системные настройки",
        ],
        "permission.later": [
            .en: "Later",
            .ru: "Позже",
        ],

        // MARK: - Item types
        "itemType.text": [.en: "Text", .ru: "Текст"],
        "itemType.link": [.en: "Links", .ru: "Ссылки"],
        "itemType.image": [.en: "Images", .ru: "Изображения"],
        "itemType.file": [.en: "Files", .ru: "Файлы"],
        "itemType.rtf": [.en: "Formatted Text", .ru: "Форматированный текст"],

        "item.image": [.en: "Image", .ru: "Изображение"],
        "item.yesterday": [.en: "Yesterday", .ru: "Вчера"],

        // MARK: - Position
        "position.lastPosition.title": [.en: "Last position", .ru: "На прежнем месте"],
        "position.lastPosition.subtitle": [
            .en: "Where you left the window last time",
            .ru: "Там, где вы оставили окно в прошлый раз",
        ],
        "position.screenCorner.title": [.en: "Screen corner", .ru: "В углу экрана"],
        "position.screenCorner.subtitle": [
            .en: "Bottom-right corner of the screen",
            .ru: "Правый нижний угол экрана",
        ],

        // MARK: - Menu
        "menu.showHistory": [.en: "Show History", .ru: "Показать историю"],
        "menu.settings": [.en: "Settings…", .ru: "Настройки…"],
        "menu.checkUpdates": [
            .en: "Check for Updates…",
            .ru: "Проверить обновления…"
        ],
        "menu.quit": [.en: "Quit", .ru: "Выйти"],
        "settings.windowTitle": [.en: "Settings — BetterClipboard", .ru: "Настройки — BetterClipboard"],

        // MARK: - Filter bar
        "filter.close": [.en: "Close", .ru: "Закрыть"],
        "filter.all": [.en: "All", .ru: "Все"],
        "filter.pinned": [.en: "Pinned", .ru: "Закреплённые"],
        "filter.rtf": [.en: "RTF", .ru: "RTF"],

        // MARK: - Search
        "search.button": [.en: "Search", .ru: "Поиск"],
        "search.placeholder": [.en: "Search clipboard…", .ru: "Поиск по буферу…"],
        "search.cancel": [.en: "Cancel", .ru: "Отмена"],
        "search.noResults": [.en: "No results", .ru: "Ничего не найдено"],

        // MARK: - Calendar
        "calendar.button": [.en: "Filter by date", .ru: "Фильтр по дате"],
        "calendar.clear": [.en: "Clear date", .ru: "Сбросить дату"],
        "calendar.done": [.en: "Done", .ru: "Готово"],

        // MARK: - Context menu
        "context.paste": [.en: "Paste", .ru: "Вставить"],
        "context.pasteWithoutFormatting": [
            .en: "Paste Without Formatting",
            .ru: "Вставить без форматирования",
        ],
        "context.unpin": [.en: "Unpin", .ru: "Открепить"],
        "context.pin": [.en: "Pin", .ru: "Закрепить"],
        "context.removeFavorite": [.en: "Remove from Favorites", .ru: "Убрать из избранного"],
        "context.addFavorite": [.en: "Add to Favorites", .ru: "В избранное"],
        "context.delete": [.en: "Delete", .ru: "Удалить"],

        "popup.empty": [.en: "Empty", .ru: "Пусто"],

        // MARK: - Settings tabs
        "settingsTab.general": [.en: "General", .ru: "Основные"],
        "settingsTab.position": [.en: "Position", .ru: "Позиция"],
        "settingsTab.history": [.en: "History", .ru: "История"],
        "settingsTab.capture": [.en: "Capture", .ru: "Захват"],
        "settingsTab.appearance": [.en: "Appearance", .ru: "Внешний вид"],
        "settingsTab.about": [.en: "About", .ru: "О программе"],
        "settingsTab.resetAll": [.en: "Reset All", .ru: "Сбросить всё"],

        // MARK: - Settings general
        "settings.general.header": [.en: "General", .ru: "Основные"],
        "settings.general.launchAtLogin": [
            .en: "Launch at login",
            .ru: "Запускать при входе в систему",
        ],
        "settings.general.doubleCommand": [.en: "Double ⌘ to open", .ru: "Двойной ⌘ для открытия"],
        "settings.general.doubleCommandInterval": [
            .en: "Double-press interval: %@ s",
            .ru: "Интервал двойного нажатия: %@ с",
        ],
        "settings.general.autoHide": [
            .en: "Hide window after paste",
            .ru: "Скрывать окно после вставки",
        ],
        "settings.general.language": [.en: "Language", .ru: "Язык"],

        // MARK: - Settings position
        "settings.position.header": [.en: "Where to open the window", .ru: "Где открывать окно"],
        "settings.position.mode": [.en: "Mode", .ru: "Режим"],
        "settings.position.resetSaved": [
            .en: "Reset Saved Position",
            .ru: "Сбросить сохранённую позицию",
        ],

        // MARK: - Settings history
        "settings.history.header": [.en: "History", .ru: "История"],
        "settings.history.maxItems": [.en: "Max items: %@", .ru: "Максимум элементов: %@"],
        "settings.history.unlimited": [.en: "Max items: unlimited", .ru: "Максимум элементов: без ограничений"],
        "settings.history.zeroNote": [
            .en: "Set to 0 for unlimited history",
            .ru: "Установите 0 для неограниченной истории",
        ],
        "settings.history.keepPinned": [
            .en: "Keep pinned items when clearing",
            .ru: "При очистке сохранять закреплённые",
        ],
        "settings.history.showTimestamps": [
            .en: "Show copy time",
            .ru: "Показывать время копирования",
        ],
        "settings.history.clearNow": [.en: "Clear All History", .ru: "Очистить всю историю"],
        "settings.history.clearRange": [.en: "Clear by date range", .ru: "Очистить за период"],
        "settings.history.from": [.en: "From", .ru: "С"],
        "settings.history.to": [.en: "To", .ru: "По"],
        "settings.history.clearRangeButton": [
            .en: "Delete Items in Range",
            .ru: "Удалить за выбранный период",
        ],

        // MARK: - Settings capture
        "settings.capture.header": [
            .en: "What to save to history",
            .ru: "Что сохранять в историю",
        ],
        "settings.capture.note": [
            .en: "Disabled types won't be added to history",
            .ru: "Отключённые типы не будут попадать в историю",
        ],

        // MARK: - Settings appearance
        "settings.appearance.header": [.en: "Appearance", .ru: "Внешний вид"],
        "settings.appearance.width": [.en: "Window width: %@ pt", .ru: "Ширина окна: %@ pt"],
        "settings.appearance.note": [
            .en: "The window uses the system material and automatically adapts to light/dark mode.",
            .ru: "Окно использует системный материал и автоматически подстраивается под светлую/тёмную тему.",
        ],

        // MARK: - About
        "settings.about.header": [.en: "About", .ru: "О программе"],
        "settings.about.appName": [.en: "BetterClipboard", .ru: "BetterClipboard"],
        "settings.about.tagline": [
            .en: "A clipboard manager for macOS",
            .ru: "Менеджер буфера обмена для macOS",
        ],
        "settings.about.version": [.en: "Version 1.1", .ru: "Версия 1.1"],
        "settings.about.shortcuts": [
            .en: "Double ⌘ — open history\nClick — paste\n⌘+Click / Right-click — paste without formatting\nType to search when the window is open",
            .ru: "Двойной ⌘ — открыть историю\nКлик — вставить\n⌘+клик / ПКМ — вставить без форматирования\nПечать — поиск, когда окно открыто",
        ],
    ]
}
