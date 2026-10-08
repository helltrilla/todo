<div align="center">
  <img src="assets/screenshots/app_icon.png" alt="TodoApp Logo" width="110" height="110" style="border-radius: 24px;" />
  <h1>TodoApp</h1>
  <p>
    <strong>Современный менеджер задач с категориями, подзадачами, таймером фокусировки и авторизацией через Supabase OTP</strong><br/>
    <em>A modern Flutter task manager featuring custom categories, subtasks, Pomodoro focus timer, and Supabase Email OTP auth</em>
  </p>

  <p>
    <a href="#русский">Русский</a> •
    <a href="#english">English</a> •
    <a href="#скриншоты--screenshots">Скриншоты / Screenshots</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Supabase-OTP_Auth-3ECF8E?logo=supabase&logoColor=white" alt="Supabase" />
    <img src="https://img.shields.io/badge/Architecture-Feature--First_Clean-8687E7" alt="Clean Architecture" />
  </p>
</div>

---

## Скриншоты / Screenshots

> Все скриншоты сделаны на симуляторе iOS с синхронизированным системным временем **`09:41`**.  
> *All screenshots were captured on the iOS Simulator with a synchronized **`09:41`** status bar clock.*

<div align="center">
  <table>
    <tr>
      <td align="center" width="25%">
        <strong>Онбординг / Onboarding</strong><br/><br/>
        <img src="assets/screenshots/onboarding_screen.png" alt="Onboarding Screen" width="210" />
      </td>
      <td align="center" width="25%">
        <strong>Авторизация / Welcome Auth</strong><br/><br/>
        <img src="assets/screenshots/welcome_screen.png" alt="Welcome Screen" width="210" />
      </td>
      <td align="center" width="25%">
        <strong>Задачи и подзадачи / Tasks</strong><br/><br/>
        <img src="assets/screenshots/home_screen.png" alt="Home Screen" width="210" />
      </td>
      <td align="center" width="25%">
        <strong>Профиль и архив / Profile</strong><br/><br/>
        <img src="assets/screenshots/settings_screen.png" alt="Settings & Profile Screen" width="210" />
      </td>
    </tr>
  </table>
</div>

---

## Русский

### О проекте

**TodoApp** — это кроссплатформенное приложение для управления задачами и временем на **Flutter**, выполненное в тёмной минималистичной стилистике (по мотивам дизайн-системы *Listodo UI Kit*) и построенное по принципам **Feature-First Clean Architecture**.

Приложение объединяет планировщик задач с чек-листами, настраиваемые цветные категории с иконками, календарь по дням с барабанами выбора времени в стиле iOS, Pomodoro-таймер для концентрации и двухрежимную авторизацию (облачный вход по 6-значному коду через **Supabase Email OTP** или автономный локальный профиль).

---

### ✨ Ключевые возможности

- **🚀 Интерактивный онбординг при первом запуске**:
  - 3 приветственных слайда с кастомной векторной графикой, которые показываются только при первой установке приложения.
- **🔐 Двухрежимная авторизация (Supabase + Локальный вход)**:
  - **Вход по Email (OTP)**: отправка настоящего 6-значного кода подтверждения на почту через **Supabase Auth REST API**.
  - **Внутренний вход**: регистрация и вход по логину и паролю с локальным хранением для полностью офлайн-работы.
- **✅ Умные задачи и подзадачи (Чек-листы)**:
  - Создание подзадач внутри любой задачи с интерактивными чекбоксами прямо на карточке и бейджем прогресса (`2/3`).
  - Автоматическое завершение основной задачи при выполнении всех её подзадач.
  - Группировка задач по секциям: **Future / Today task** и **Completed task today**.
- **🎨 Кастомные категории с иконками и цветами**:
  - Конструктор категорий с выбором из **12 тематических иконок** и **10 цветовых палитр**.
  - Глобальная категория **«Общее»** с золотой подсветкой — задачи из неё отображаются во всех вкладках и всегда остаются на виду.
- **🔥 4 уровня приоритета с цветовой индикацией**:
  - **P1 — Срочно 🔥** (красный акцент и выделенная рамка карточки)
  - **P2 — Высокий ⚡** (оранжевый акцент)
  - **P3 — Средний 📌** (фиолетовый акцент)
  - **P4 — Низкий 🌿** (зелёный акцент)
- **📅 Календарь и выбор времени в стиле iPhone**:
  - Отдельная вкладка **«Календарь»** с горизонтальной лентой дней недели и переключателем *Активные / Выполненные*.
  - Кастомный диалог выбора даты и времени с двумя крутящимися барабанами (`CupertinoPicker`) для часов (`00–23`) и минут (`00–59`).
- **⏱️ Режим фокусировки (Pomodoro-таймер)**:
  - Вкладка **«Фокус»** с круговым индикатором прогресса, пресетами на `15`, `25`, `45` и `60` минут и счётчиком завершённых сессий.
- **📦 Жесты смахивания и Архив задач**:
  - **Свайп влево** по любой карточке — быстрое удаление задачи с возможностью отмены (`SnackBar`).
  - **Свайп вправо** по выполненной задаче — перенос карточки в **Архив**, доступный из экрана Профиля с возможностью восстановления.

---

### 🏗️ Архитектура и технический стек

Проект следует строгой **Feature-First Clean Architecture** с разделением каждого модуля на слои `domain`, `data` и `presentation` и функциональной обработкой ошибок через `Result<T>` (`Success<T>` / `Error<T>`).

```text
lib/
├── core/
│   ├── app_router/       # Навигация GoRouter и защита маршрутов (Auth & Onboarding guards)
│   ├── app_theme/        # Тёмная тема, палитра цветов и типографика
│   ├── config/           # Конфигурация окружения и ключей Supabase
│   └── errors/           # Базовые классы Failure и монада Result<T>
├── features/
│   ├── auth/             # Модуль авторизации, онбординга и профиля пользователя
│   │   ├── domain/       # Сущность AppUser и контракт IAuthRepository
│   │   ├── data/         # AuthRepositoryImpl (Supabase REST API + SharedPreferences)
│   │   └── presentation/ # AuthController, Onboarding, Welcome, EmailOtp, InternalAuth, Settings
│   └── tasks/            # Модуль задач, категорий, календаря и таймера фокуса
│       ├── domain/       # Модели Task, SubTask, PriorityLevel, TaskCategoryStyle, ITaskRepository
│       ├── data/         # TaskLocalRepository (локальная персистентность JSON)
│       └── presentation/ # TaskController, HomeScreen, CalendarTabView, FocusTabView, виджеты
└── main.dart             # Точка входа и инициализация зависимостей (Provider)
```

| Категория | Технологии |
| :--- | :--- |
| **Фреймворк и язык** | Flutter 3.x, Dart 3.11+ |
| **Управление состоянием** | `provider` (`ChangeNotifier`) |
| **Навигация** | `go_router` |
| **Бэкенд и авторизация** | Supabase Auth REST API (`http`) + Local Auth |
| **Локальное хранилище** | `shared_preferences` |
| **Локализация дат** | `intl` |
| **Тестирование** | `flutter_test`, `mocktail` |

---

### 🚀 Установка и запуск

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/helltrilla/todo.git
   cd todo
   ```

2. **Установите зависимости:**
   ```bash
   flutter pub get
   ```

3. **Запустите приложение:**
   ```bash
   flutter run
   ```
   > При необходимости вы можете передать собственные ключи Supabase через `--dart-define`:
   > ```bash
   > flutter run \
   >   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
   >   --dart-define=SUPABASE_ANON_KEY=your-anon-key
   > ```

4. **Проверка анализатора и запуск тестов:**
   ```bash
   flutter analyze --fatal-infos
   flutter test --coverage
   ```

---

## English

### Overview

**TodoApp** is a cross-platform task and productivity manager built with **Flutter**, crafted around a sleek dark UI inspired by the *Listodo UI Kit* and engineered using **Feature-First Clean Architecture**.

It combines smart checklists/subtasks, customizable colored categories with icons, an iOS-style scroll-wheel date & time picker, a daily calendar view, a Pomodoro focus timer, and dual-mode authentication (real 6-digit **Supabase Email OTP** verification alongside an offline local account mode).

---

### ✨ Key Features

- **🚀 First-Launch Interactive Onboarding**:
  - A 3-step illustrated onboarding walkthrough displayed exclusively on the first launch after installation.
- **🔐 Dual Authentication (Supabase Email OTP + Offline Local Auth)**:
  - **Email OTP Sign-In**: Sends a real 6-digit verification code via the **Supabase Auth REST API**.
  - **Internal Offline Sign-In**: Username & password authentication persisted locally for full offline capability.
- **✅ Smart Tasks & Interactive Subtasks**:
  - Add multi-step checklists to any task, toggle subtasks directly on the task card, and track completion with a live badge (`2/3`).
  - Checking off all subtasks automatically marks the parent task as completed.
  - Organized into **Future / Today task** and **Completed task today** sections.
- **🎨 Custom Categories with Icons & Color Palettes**:
  - Create custom categories choosing from **12 icons** and **10 curated colors**.
  - Built-in global category (**«Общее» / General**) highlighted in gold that stays visible across all category filters.
- **🔥 4 Visual Priority Levels**:
  - **P1 — Urgent 🔥** (Red highlight & accented card border)
  - **P2 — High ⚡** (Orange highlight)
  - **P3 — Medium 📌** (Purple highlight)
  - **P4 — Low 🌿** (Green highlight)
- **📅 Calendar View & iPhone-Style Time Wheels**:
  - Dedicated **Calendar** tab with a horizontal week strip and *Active / Completed* filter tabs.
  - Custom Date & Time dialog featuring dual `CupertinoPicker` scroll wheels for hours (`00–23`) and minutes (`00–59`).
- **⏱️ Focus Mode (Pomodoro Timer)**:
  - Dedicated **Focus** tab with a circular progress ring, `15`, `25`, `45`, and `60`-minute presets, and a completed session counter.
- **📦 Swipe Gestures & Completed Task Archive**:
  - **Swipe Left** on any task card to delete it (with an Undo `SnackBar`).
  - **Swipe Right** on a completed task card to move it to the **Archive**, where it can be viewed, restored, or permanently removed from the Profile screen.

---

### 🛠️ Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/helltrilla/todo.git
   cd todo
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Run static analysis and unit/widget tests:**
   ```bash
   flutter analyze --fatal-infos
   flutter test --coverage
   ```
