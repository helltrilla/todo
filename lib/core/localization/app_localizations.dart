import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/core/localization/app_language.dart';
import 'package:todo/core/localization/locale_controller.dart';

class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    final controller = context.watch<LocaleController?>();
    return AppLocalizations(controller?.currentLanguage ?? AppLanguage.ru);
  }

  // Navigation & Common
  String get tasks => switch (language) {
        AppLanguage.ru => 'Задачи',
        AppLanguage.en => 'Tasks',
        AppLanguage.de => 'Aufgaben',
        AppLanguage.fr => 'Tâches',
        AppLanguage.sr => 'Задаци',
      };

  String get calendar => switch (language) {
        AppLanguage.ru => 'Календарь',
        AppLanguage.en => 'Calendar',
        AppLanguage.de => 'Kalender',
        AppLanguage.fr => 'Calendrier',
        AppLanguage.sr => 'Календар',
      };

  String get focus => switch (language) {
        AppLanguage.ru => 'Фокус',
        AppLanguage.en => 'Focus',
        AppLanguage.de => 'Fokus',
        AppLanguage.fr => 'Focus',
        AppLanguage.sr => 'Фокус',
      };

  String get profile => switch (language) {
        AppLanguage.ru => 'Профиль',
        AppLanguage.en => 'Profile',
        AppLanguage.de => 'Profil',
        AppLanguage.fr => 'Profil',
        AppLanguage.sr => 'Профил',
      };

  String get settings => switch (language) {
        AppLanguage.ru => 'Настройки',
        AppLanguage.en => 'Settings',
        AppLanguage.de => 'Einstellungen',
        AppLanguage.fr => 'Paramètres',
        AppLanguage.sr => 'Подешавања',
      };

  String get back => switch (language) {
        AppLanguage.ru => 'Назад',
        AppLanguage.en => 'Back',
        AppLanguage.de => 'Zurück',
        AppLanguage.fr => 'Retour',
        AppLanguage.sr => 'Назад',
      };

  String get cancel => switch (language) {
        AppLanguage.ru => 'Отмена',
        AppLanguage.en => 'Cancel',
        AppLanguage.de => 'Abbrechen',
        AppLanguage.fr => 'Annuler',
        AppLanguage.sr => 'Откажи',
      };

  String get close => switch (language) {
        AppLanguage.ru => 'Закрыть',
        AppLanguage.en => 'Close',
        AppLanguage.de => 'Schließen',
        AppLanguage.fr => 'Fermer',
        AppLanguage.sr => 'Затвори',
      };

  String get clear => switch (language) {
        AppLanguage.ru => 'Очистить',
        AppLanguage.en => 'Clear',
        AppLanguage.de => 'Löschen',
        AppLanguage.fr => 'Effacer',
        AppLanguage.sr => 'Обриши',
      };

  String get clearAll => switch (language) {
        AppLanguage.ru => 'Очистить всё',
        AppLanguage.en => 'Clear All',
        AppLanguage.de => 'Alles löschen',
        AppLanguage.fr => 'Tout effacer',
        AppLanguage.sr => 'Обриши све',
      };

  String get delete => switch (language) {
        AppLanguage.ru => 'Удалить',
        AppLanguage.en => 'Delete',
        AppLanguage.de => 'Löschen',
        AppLanguage.fr => 'Supprimer',
        AppLanguage.sr => 'Обриши',
      };

  String get deleteForever => switch (language) {
        AppLanguage.ru => 'Удалить навсегда',
        AppLanguage.en => 'Delete Forever',
        AppLanguage.de => 'Endgültig löschen',
        AppLanguage.fr => 'Supprimer définitivement',
        AppLanguage.sr => 'Обриши заувек',
      };

  String get exit => switch (language) {
        AppLanguage.ru => 'Выйти',
        AppLanguage.en => 'Sign Out',
        AppLanguage.de => 'Abmelden',
        AppLanguage.fr => 'Déconnexion',
        AppLanguage.sr => 'Изађи',
      };

  // Appearance & Theme
  String get appearanceAndTheme => switch (language) {
        AppLanguage.ru => 'Тема и оформление',
        AppLanguage.en => 'Appearance & Theme',
        AppLanguage.de => 'Erscheinungsbild & Design',
        AppLanguage.fr => 'Apparence et thème',
        AppLanguage.sr => 'Изглед и тема',
      };

  String get theme => switch (language) {
        AppLanguage.ru => 'Тема оформления',
        AppLanguage.en => 'App Theme',
        AppLanguage.de => 'App-Design',
        AppLanguage.fr => 'Thème de l\'application',
        AppLanguage.sr => 'Тема апликације',
      };

  String get themeSubtitle => switch (language) {
        AppLanguage.ru => 'Выберите тёмный, светлый или системный вид',
        AppLanguage.en => 'Choose dark, light, or system appearance',
        AppLanguage.de => 'Wähle dunkles, helles oder System-Design',
        AppLanguage.fr => 'Choisissez le mode sombre, clair ou système',
        AppLanguage.sr => 'Изаберите тамни, светли или системски изглед',
      };

  String get themeDark => switch (language) {
        AppLanguage.ru => 'Тёмная',
        AppLanguage.en => 'Dark',
        AppLanguage.de => 'Dunkel',
        AppLanguage.fr => 'Sombre',
        AppLanguage.sr => 'Тамна',
      };

  String get themeLight => switch (language) {
        AppLanguage.ru => 'Светлая',
        AppLanguage.en => 'Light',
        AppLanguage.de => 'Hell',
        AppLanguage.fr => 'Clair',
        AppLanguage.sr => 'Светла',
      };

  String get themeMidnight => switch (language) {
        AppLanguage.ru => 'Midnight (AMOLED)',
        AppLanguage.en => 'Midnight (AMOLED)',
        AppLanguage.de => 'Mitternacht (AMOLED)',
        AppLanguage.fr => 'Minuit (AMOLED)',
        AppLanguage.sr => 'Поноћ (AMOLED)',
      };

  String get themeSystem => switch (language) {
        AppLanguage.ru => 'Системная',
        AppLanguage.en => 'System',
        AppLanguage.de => 'System',
        AppLanguage.fr => 'Système',
        AppLanguage.sr => 'Системска',
      };

  // Language
  String get languageTitle => switch (language) {
        AppLanguage.ru => 'Язык приложения',
        AppLanguage.en => 'App Language',
        AppLanguage.de => 'App-Sprache',
        AppLanguage.fr => 'Langue de l\'application',
        AppLanguage.sr => 'Језик апликације',
      };

  String get languageSubtitle => switch (language) {
        AppLanguage.ru => 'Русский, English, Deutsch, Français, Српски',
        AppLanguage.en => 'Russian, English, German, French, Serbian',
        AppLanguage.de => 'Russisch, Englisch, Deutsch, Französisch, Serbisch',
        AppLanguage.fr => 'Russe, Anglais, Allemand, Français, Serbe',
        AppLanguage.sr => 'Руски, Енглески, Немачки, Француски, Српски',
      };

  String get selectLanguage => switch (language) {
        AppLanguage.ru => 'Выбор языка',
        AppLanguage.en => 'Select Language',
        AppLanguage.de => 'Sprache wählen',
        AppLanguage.fr => 'Sélectionner la langue',
        AppLanguage.sr => 'Изаберите језик',
      };

  // Notifications & Haptics
  String get notificationsAndHaptics => switch (language) {
        AppLanguage.ru => 'Уведомления и отклик',
        AppLanguage.en => 'Notifications & Haptics',
        AppLanguage.de => 'Benachrichtigungen & Haptik',
        AppLanguage.fr => 'Notifications et haptique',
        AppLanguage.sr => 'Обавештења и вибрација',
      };

  String get testNotification => switch (language) {
        AppLanguage.ru => 'Проверить Push-уведомление',
        AppLanguage.en => 'Test Push Notification',
        AppLanguage.de => 'Push-Benachrichtigung testen',
        AppLanguage.fr => 'Tester la notification push',
        AppLanguage.sr => 'Тестирајте Push обавештење',
      };

  String get testNotificationSubtitle => switch (language) {
        AppLanguage.ru => 'Отправить тестовое уведомление через 2 секунды',
        AppLanguage.en => 'Send a test notification in 2 seconds',
        AppLanguage.de => 'Test-Benachrichtigung in 2 Sekunden senden',
        AppLanguage.fr => 'Envoyer une notification test dans 2 secondes',
        AppLanguage.sr => 'Пошаљите тест обавештење за 2 секунде',
      };

  String get testNotificationSent => switch (language) {
        AppLanguage.ru => 'Тестовое уведомление отправлено! (придёт через 2 сек)',
        AppLanguage.en => 'Test notification sent! (arriving in 2 sec)',
        AppLanguage.de => 'Test-Benachrichtigung gesendet! (kommt in 2 Sek)',
        AppLanguage.fr => 'Notification test envoyée ! (arrive dans 2 sec)',
        AppLanguage.sr => 'Тест обавештење је послато! (стиже за 2 сек)',
      };

  String get testNotificationPermissionError => switch (language) {
        AppLanguage.ru => 'Разрешите уведомления для TodoApp в настройках телефона',
        AppLanguage.en => 'Please enable notifications for TodoApp in device settings',
        AppLanguage.de => 'Bitte aktiviere Benachrichtigungen für TodoApp in den Geräteeinstellungen',
        AppLanguage.fr => 'Veuillez activer les notifications pour TodoApp dans les paramètres',
        AppLanguage.sr => 'Омогућите обавештења за TodoApp у подешавањима телефона',
      };

  String get haptics => switch (language) {
        AppLanguage.ru => 'Тактильная вибрация (Haptics)',
        AppLanguage.en => 'Tactile Haptics',
        AppLanguage.de => 'Haptisches Feedback',
        AppLanguage.fr => 'Retour haptique',
        AppLanguage.sr => 'Тактилна вибрација (Haptics)',
      };

  String get hapticsSubtitle => switch (language) {
        AppLanguage.ru => 'Отклик Taptic Engine при кликах и прокрутке времени',
        AppLanguage.en => 'Taptic Engine feedback on taps and scrolling',
        AppLanguage.de => 'Taptic Engine Feedback beim Tippen und Scrollen',
        AppLanguage.fr => 'Retour Taptic Engine lors des clics et défilement',
        AppLanguage.sr => 'Taptic Engine одговор при клику и скроловању',
      };

  // Data & Tasks
  String get dataManagement => switch (language) {
        AppLanguage.ru => 'Управление данными',
        AppLanguage.en => 'Data Management',
        AppLanguage.de => 'Datenverwaltung',
        AppLanguage.fr => 'Gestion des données',
        AppLanguage.sr => 'Управљање подацима',
      };

  String get clearCompleted => switch (language) {
        AppLanguage.ru => 'Очистить выполненные задачи',
        AppLanguage.en => 'Clear completed tasks',
        AppLanguage.de => 'Erledigte Aufgaben löschen',
        AppLanguage.fr => 'Effacer les tâches terminées',
        AppLanguage.sr => 'Обриши завршене задатке',
      };

  String clearCompletedSubtitle(int count) {
    if (count == 0) {
      return switch (language) {
        AppLanguage.ru => 'Нет выполненных задач',
        AppLanguage.en => 'No completed tasks',
        AppLanguage.de => 'Keine erledigten Aufgaben',
        AppLanguage.fr => 'Aucune tâche terminée',
        AppLanguage.sr => 'Нема завршених задатака',
      };
    }
    return switch (language) {
      AppLanguage.ru => 'Удалить завершённые задачи ($count)',
      AppLanguage.en => 'Delete completed tasks ($count)',
      AppLanguage.de => 'Erledigte Aufgaben löschen ($count)',
      AppLanguage.fr => 'Supprimer les tâches terminées ($count)',
      AppLanguage.sr => 'Обриши завршене задатке ($count)',
    };
  }

  String get clearCompletedConfirmTitle => switch (language) {
        AppLanguage.ru => 'Очистить выполненные?',
        AppLanguage.en => 'Clear completed?',
        AppLanguage.de => 'Erledigte löschen?',
        AppLanguage.fr => 'Effacer les terminées ?',
        AppLanguage.sr => 'Обрисати завршене?',
      };

  String clearCompletedConfirmMsg(int count) => switch (language) {
        AppLanguage.ru => 'Будет удалено выполненных задач: $count.',
        AppLanguage.en => '$count completed tasks will be deleted.',
        AppLanguage.de => '$count erledigte Aufgaben werden gelöscht.',
        AppLanguage.fr => '$count tâches terminées seront supprimées.',
        AppLanguage.sr => 'Биће обрисано завршених задатака: $count.',
      };

  String get resetAllTasks => switch (language) {
        AppLanguage.ru => 'Сбросить все задачи',
        AppLanguage.en => 'Reset all tasks',
        AppLanguage.de => 'Alle Aufgaben zurücksetzen',
        AppLanguage.fr => 'Réinitialiser toutes les tâches',
        AppLanguage.sr => 'Ресетуј све задатке',
      };

  String resetAllTasksSubtitle(int total) {
    if (total == 0) {
      return switch (language) {
        AppLanguage.ru => 'Список задач пуст',
        AppLanguage.en => 'Task list is empty',
        AppLanguage.de => 'Aufgabenliste ist leer',
        AppLanguage.fr => 'La liste de tâches est vide',
        AppLanguage.sr => 'Листа задатака је празна',
      };
    }
    return switch (language) {
      AppLanguage.ru => 'Удалить все задачи и архив ($total)',
      AppLanguage.en => 'Delete all tasks and archive ($total)',
      AppLanguage.de => 'Alle Aufgaben und Archiv löschen ($total)',
      AppLanguage.fr => 'Supprimer toutes les tâches et archives ($total)',
      AppLanguage.sr => 'Обриши све задатке и архиву ($total)',
    };
  }

  String get resetAllTasksConfirmTitle => switch (language) {
        AppLanguage.ru => 'Сбросить все задачи?',
        AppLanguage.en => 'Reset all tasks?',
        AppLanguage.de => 'Alle Aufgaben zurücksetzen?',
        AppLanguage.fr => 'Réinitialiser toutes les tâches ?',
        AppLanguage.sr => 'Ресетовати све задатке?',
      };

  String resetAllTasksConfirmMsg(int total) => switch (language) {
        AppLanguage.ru =>
          'Все задачи ($total) и архив будут очищены, но ваш профиль останется активным.',
        AppLanguage.en =>
          'All tasks ($total) and archive will be cleared, but your profile remains active.',
        AppLanguage.de =>
          'Alle Aufgaben ($total) und das Archiv werden gelöscht, dein Profil bleibt jedoch aktiv.',
        AppLanguage.fr =>
          'Toutes les tâches ($total) et archives seront effacées, mais votre profil reste actif.',
        AppLanguage.sr =>
          'Сви задаци ($total) и архива биће очишћени, али ваш профил остаје активан.',
      };

  // Account & Security
  String get accountAndSecurity => switch (language) {
        AppLanguage.ru => 'Аккаунт и безопасность',
        AppLanguage.en => 'Account & Security',
        AppLanguage.de => 'Konto & Sicherheit',
        AppLanguage.fr => 'Compte et sécurité',
        AppLanguage.sr => 'Налог и безбедност',
      };

  String get privacyPolicy => switch (language) {
        AppLanguage.ru => 'Политика конфиденциальности',
        AppLanguage.en => 'Privacy Policy',
        AppLanguage.de => 'Datenschutzerklärung',
        AppLanguage.fr => 'Politique de confidentialité',
        AppLanguage.sr => 'Политика приватности',
      };

  String get privacyPolicySubtitle => switch (language) {
        AppLanguage.ru => 'Условия хранения данных и конфиденциальность',
        AppLanguage.en => 'Data storage terms and privacy',
        AppLanguage.de => 'Bedingungen zur Datenspeicherung und Datenschutz',
        AppLanguage.fr => 'Conditions de stockage des données et confidentialité',
        AppLanguage.sr => 'Услови складиштења података и приватност',
      };

  String get copyPrivacyLink => switch (language) {
        AppLanguage.ru => 'Скопировать ссылку на документ',
        AppLanguage.en => 'Copy document link',
        AppLanguage.de => 'Dokumentlink kopieren',
        AppLanguage.fr => 'Copier le lien du document',
        AppLanguage.sr => 'Копирај везу до документа',
      };

  String get privacyLinkCopied => switch (language) {
        AppLanguage.ru => 'Ссылка на политику конфиденциальности скопирована',
        AppLanguage.en => 'Privacy policy link copied to clipboard',
        AppLanguage.de => 'Link zur Datenschutzerklärung in Zwischenablage kopiert',
        AppLanguage.fr => 'Lien de la politique de confidentialité copié',
        AppLanguage.sr => 'Веза до политике приватности је копирана',
      };

  String get signOut => switch (language) {
        AppLanguage.ru => 'Выйти из аккаунта',
        AppLanguage.en => 'Sign Out',
        AppLanguage.de => 'Abmelden',
        AppLanguage.fr => 'Se déconnecter',
        AppLanguage.sr => 'Одјавите се',
      };

  String get signOutSubtitle => switch (language) {
        AppLanguage.ru => 'Вернуться на экран приветствия',
        AppLanguage.en => 'Return to welcome screen',
        AppLanguage.de => 'Zurück zum Willkommensbildschirm',
        AppLanguage.fr => 'Retourner à l\'écran de bienvenue',
        AppLanguage.sr => 'Повратак на екран добродошлице',
      };

  String get signOutConfirmTitle => switch (language) {
        AppLanguage.ru => 'Выход из аккаунта',
        AppLanguage.en => 'Sign Out',
        AppLanguage.de => 'Abmelden',
        AppLanguage.fr => 'Déconnexion',
        AppLanguage.sr => 'Одјава са налога',
      };

  String get signOutConfirmMsg => switch (language) {
        AppLanguage.ru => 'Вы уверены, что хотите выйти из текущего профиля?',
        AppLanguage.en => 'Are you sure you want to sign out of the current profile?',
        AppLanguage.de => 'Möchtest du dich wirklich vom aktuellen Profil abmelden?',
        AppLanguage.fr => 'Êtes-vous sûr de vouloir vous déconnecter du profil actuel ?',
        AppLanguage.sr => 'Да ли сте сигурни да желите да се одјавите са тренутног профила?',
      };

  String get deleteAccount => switch (language) {
        AppLanguage.ru => 'Удалить аккаунт и данные',
        AppLanguage.en => 'Delete Account & Data',
        AppLanguage.de => 'Konto & Daten löschen',
        AppLanguage.fr => 'Supprimer le compte et les données',
        AppLanguage.sr => 'Обришите налог и податке',
      };

  String get deleteAccountSubtitle => switch (language) {
        AppLanguage.ru => 'Безвозвратно удалить профиль и все задачи',
        AppLanguage.en => 'Permanently remove profile and all tasks',
        AppLanguage.de => 'Profil und alle Aufgaben dauerhaft entfernen',
        AppLanguage.fr => 'Supprimer définitivement le profil et toutes les tâches',
        AppLanguage.sr => 'Трајно уклоните профил и све задатке',
      };

  String get deleteAccountConfirmTitle => switch (language) {
        AppLanguage.ru => 'Удалить аккаунт и данные?',
        AppLanguage.en => 'Delete account and data?',
        AppLanguage.de => 'Konto und Daten löschen?',
        AppLanguage.fr => 'Supprimer le compte et les données ?',
        AppLanguage.sr => 'Обрисати налог и податке?',
      };

  String get deleteAccountConfirmMsg => switch (language) {
        AppLanguage.ru =>
          'Ваш профиль и все созданные задачи будут безвозвратно удалены с этого устройства. Это действие нельзя отменить.',
        AppLanguage.en =>
          'Your profile and all created tasks will be permanently removed from this device. This action cannot be undone.',
        AppLanguage.de =>
          'Dein Profil und alle erstellten Aufgaben werden dauerhaft von diesem Gerät entfernt. Diese Aktion kann nicht rückgängig gemacht werden.',
        AppLanguage.fr =>
          'Votre profil et toutes les tâches créées seront définitivement supprimés de cet appareil. Cette action est irréversible.',
        AppLanguage.sr =>
          'Ваш профил и сви креирани задаци биће трајно уклоњени са овог уређаја. Ова радња се не може опозвати.',
      };

  String get tipFooter => switch (language) {
        AppLanguage.ru =>
          'Совет: зажмите иконку TodoApp на домашнем экране телефона для быстрого создания задачи или запуска Фокуса.',
        AppLanguage.en =>
          'Tip: long-press the TodoApp icon on your home screen to quickly create a task or launch Focus.',
        AppLanguage.de =>
          'Tipp: Halte das TodoApp-Symbol auf dem Startbildschirm gedrückt, um schnell eine Aufgabe zu erstellen oder den Fokus zu starten.',
        AppLanguage.fr =>
          'Astuce : appuyez longuement sur l\'icône TodoApp sur l\'écran d\'accueil pour créer rapidement une tâche ou lancer le Focus.',
        AppLanguage.sr =>
          'Савет: притисните и држите икону TodoApp на почетном екрану за брзо креирање задатка или покретање Фокуса.',
      };

  // Home Screen
  String get searchTasksHint => switch (language) {
        AppLanguage.ru => 'Поиск задач...',
        AppLanguage.en => 'Search tasks...',
        AppLanguage.de => 'Aufgaben suchen...',
        AppLanguage.fr => 'Rechercher des tâches...',
        AppLanguage.sr => 'Претражи задатке...',
      };

  String get allCategory => switch (language) {
        AppLanguage.ru => 'Все',
        AppLanguage.en => 'All',
        AppLanguage.de => 'Alle',
        AppLanguage.fr => 'Toutes',
        AppLanguage.sr => 'Све',
      };

  String get noTasksTitle => switch (language) {
        AppLanguage.ru => 'У вас нет задач',
        AppLanguage.en => 'No tasks yet',
        AppLanguage.de => 'Keine Aufgaben',
        AppLanguage.fr => 'Aucune tâche',
        AppLanguage.sr => 'Нема задатака',
      };

  String get noTasksSubtitle => switch (language) {
        AppLanguage.ru => 'Нажмите +, чтобы добавить первую задачу',
        AppLanguage.en => 'Tap + to add your first task',
        AppLanguage.de => 'Tippe auf +, um die erste Aufgabe hinzuzufügen',
        AppLanguage.fr => 'Appuyez sur + pour ajouter votre première tâche',
        AppLanguage.sr => 'Додирните + да додате први задатак',
      };

  String get newTask => switch (language) {
        AppLanguage.ru => 'Создать задачу',
        AppLanguage.en => 'New Task',
        AppLanguage.de => 'Neue Aufgabe',
        AppLanguage.fr => 'Nouvelle tâche',
        AppLanguage.sr => 'Нови задатак',
      };

  // Focus Screen
  String get focusModeTitle => switch (language) {
        AppLanguage.ru => 'Фокус режим',
        AppLanguage.en => 'Focus Mode',
        AppLanguage.de => 'Fokus-Modus',
        AppLanguage.fr => 'Mode Focus',
        AppLanguage.sr => 'Режим фокуса',
      };

  String get play => switch (language) {
        AppLanguage.ru => 'Играть',
        AppLanguage.en => 'Play',
        AppLanguage.de => 'Abspielen',
        AppLanguage.fr => 'Lecture',
        AppLanguage.sr => 'Пусти',
      };

  String get pause => switch (language) {
        AppLanguage.ru => 'Пауза',
        AppLanguage.en => 'Pause',
        AppLanguage.de => 'Pause',
        AppLanguage.fr => 'Pause',
        AppLanguage.sr => 'Пауза',
      };

  String get previous => switch (language) {
        AppLanguage.ru => 'Назад',
        AppLanguage.en => 'Previous',
        AppLanguage.de => 'Zurück',
        AppLanguage.fr => 'Précédent',
        AppLanguage.sr => 'Назад',
      };

  String get next => switch (language) {
        AppLanguage.ru => 'Вперёд',
        AppLanguage.en => 'Next',
        AppLanguage.de => 'Weiter',
        AppLanguage.fr => 'Suivant',
        AppLanguage.sr => 'Напред',
      };

  String get ambientSounds => switch (language) {
        AppLanguage.ru => 'Фоновые звуки',
        AppLanguage.en => 'Ambient Sounds',
        AppLanguage.de => 'Hintergrundgeräusche',
        AppLanguage.fr => 'Sons d\'ambiance',
        AppLanguage.sr => 'Амбијентални звуци',
      };

  String get ambientRain => switch (language) {
        AppLanguage.ru => 'Дождь',
        AppLanguage.en => 'Rain',
        AppLanguage.de => 'Regen',
        AppLanguage.fr => 'Pluie',
        AppLanguage.sr => 'Киша',
      };

  String get ambientWaves => switch (language) {
        AppLanguage.ru => 'Прибой',
        AppLanguage.en => 'Waves',
        AppLanguage.de => 'Wellen',
        AppLanguage.fr => 'Vagues',
        AppLanguage.sr => 'Таласи',
      };

  String get ambientCafe => switch (language) {
        AppLanguage.ru => 'Кафе',
        AppLanguage.en => 'Cafe',
        AppLanguage.de => 'Café',
        AppLanguage.fr => 'Café',
        AppLanguage.sr => 'Кафић',
      };

  String get ambientVinyl => switch (language) {
        AppLanguage.ru => 'Винил',
        AppLanguage.en => 'Vinyl',
        AppLanguage.de => 'Vinyl',
        AppLanguage.fr => 'Vinyle',
        AppLanguage.sr => 'Грамофон',
      };

  String get ambientOff => switch (language) {
        AppLanguage.ru => 'Выкл',
        AppLanguage.en => 'Off',
        AppLanguage.de => 'Aus',
        AppLanguage.fr => 'Désactivé',
        AppLanguage.sr => 'Искљ.',
      };

  String get playlists => switch (language) {
        AppLanguage.ru => 'Плейлисты',
        AppLanguage.en => 'Playlists',
        AppLanguage.de => 'Playlists',
        AppLanguage.fr => 'Playlists',
        AppLanguage.sr => 'Плејлисте',
      };

  String get addPlaylist => switch (language) {
        AppLanguage.ru => '+ Добавить',
        AppLanguage.en => '+ Add',
        AppLanguage.de => '+ Hinzufügen',
        AppLanguage.fr => '+ Ajouter',
        AppLanguage.sr => '+ Додај',
      };
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);
}
