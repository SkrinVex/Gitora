// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Gitora';

  @override
  String get appTagline => 'Powerful Git. Beautifully Simple.';

  @override
  String get navDashboard => 'Главная';

  @override
  String get navChanges => 'Изменения';

  @override
  String get navHistory => 'История';

  @override
  String get navBranches => 'Ветки';

  @override
  String get navRemotes => 'Репозитории';

  @override
  String get navStashes => 'Тайники';

  @override
  String get navSettings => 'Настройки';

  @override
  String get openRepository => 'Открыть репозиторий';

  @override
  String get cloneRepository => 'Клонировать репозиторий';

  @override
  String get newRepository => 'Создать репозиторий';

  @override
  String get recentRepositories => 'Недавние репозитории';

  @override
  String get favorites => 'Избранное';

  @override
  String get noRecentRepositories =>
      'Нет недавних репозиториев. Откройте или клонируйте проект, чтобы начать работу.';

  @override
  String get searchRepositories => 'Поиск репозиториев...';

  @override
  String get removeRecent => 'Удалить из недавних';

  @override
  String get markFavorite => 'Добавить в избранное';

  @override
  String get unmarkFavorite => 'Убрать из избранного';

  @override
  String get openInExplorer => 'Показать в проводнике';

  @override
  String get openInTerminal => 'Открыть в терминале';

  @override
  String get openInEditor => 'Открыть в редакторе кода';

  @override
  String get workingTree => 'Рабочая копия';

  @override
  String get stagedChanges => 'Индексированные изменения';

  @override
  String get unstagedChanges => 'Неиндексированные изменения';

  @override
  String get stageAll => 'Индексировать всё';

  @override
  String get unstageAll => 'Снять индексацию со всех';

  @override
  String get discardAll => 'Отменить все изменения';

  @override
  String get commit => 'Закоммитить';

  @override
  String commitToBranch(String branch) {
    return 'Коммит в ветку $branch';
  }

  @override
  String get commitSummary => 'Краткое сообщение коммита';

  @override
  String get commitDescription => 'Подробное описание (необязательно)';

  @override
  String get amendLastCommit => 'Дополнить последний коммит (Amend)';

  @override
  String get stageFile => 'Индексировать файл';

  @override
  String get unstageFile => 'Убрать из индекса';

  @override
  String get discardFile => 'Отменить изменения';

  @override
  String discardConfirmTitle(String file) {
    return 'Отменить изменения в $file?';
  }

  @override
  String get discardConfirmMessage =>
      'Это действие необратимо. Все незакоммиченные правки в файле будут утеряны.';

  @override
  String get discardAllConfirmTitle =>
      'Отменить все неиндексированные изменения?';

  @override
  String get discardAllConfirmMessage =>
      'Вы уверены, что хотите отменить все локальные правки? Это действие нельзя отменить.';

  @override
  String get noChangesSelected => 'Выберите файл в списке для просмотра diff';

  @override
  String get noChangesTitle => 'Рабочая копия чиста';

  @override
  String get noChangesSubtitle =>
      'В репозитории нет незакоммиченных изменений.';

  @override
  String get binaryFileNotice =>
      'Бинарный файл изменён. Предпросмотр diff для бинарных файлов не поддерживается.';

  @override
  String get unifiedDiff => 'Объединённый';

  @override
  String get sideBySideDiff => 'Двусторонний';

  @override
  String get stageHunk => 'Индексировать блок';

  @override
  String get unstageHunk => 'Убрать блок из индекса';

  @override
  String get copyLine => 'Скопировать строку';

  @override
  String get commitGraph => 'Граф коммитов';

  @override
  String get searchCommits => 'Поиск коммитов по сообщению, автору или SHA...';

  @override
  String get noCommitsFound => 'Коммитов по запросу не найдено';

  @override
  String get commitDetails => 'Сведения о коммите';

  @override
  String get author => 'Автор';

  @override
  String get date => 'Дата';

  @override
  String get sha => 'Хеш';

  @override
  String get parents => 'Родители';

  @override
  String get changedFiles => 'Изменённые файлы';

  @override
  String get copySha => 'Скопировать полный хеш';

  @override
  String get checkoutCommit => 'Переключиться на этот коммит';

  @override
  String get cherryPickCommit => 'Применить коммит (Cherry-pick)';

  @override
  String get revertCommit => 'Откатить коммит (Revert)';

  @override
  String get localBranches => 'Локальные ветки';

  @override
  String get remoteBranches => 'Удалённые ветки';

  @override
  String get tags => 'Теги';

  @override
  String get currentBranch => 'Текущая';

  @override
  String get createBranch => 'Создать ветку';

  @override
  String get branchName => 'Название ветки';

  @override
  String get checkout => 'Переключиться';

  @override
  String get renameBranch => 'Переименовать ветку';

  @override
  String get deleteBranch => 'Удалить ветку';

  @override
  String deleteBranchConfirm(String branch) {
    return 'Вы действительно хотите удалить ветку \'$branch\'?';
  }

  @override
  String get cannotDeleteActiveBranch =>
      'Нельзя удалить текущую активную ветку. Сначала переключитесь на другую ветку.';

  @override
  String mergeInto(String source, String target) {
    return 'Слить \'$source\' в \'$target\'';
  }

  @override
  String rebaseOnto(String current, String onto) {
    return 'Перебазировать \'$current\' на \'$onto\'';
  }

  @override
  String get setUpstream => 'Привязать к upstream';

  @override
  String get remotes => 'Удалённые серверы';

  @override
  String get addRemote => 'Добавить remote';

  @override
  String get remoteName => 'Имя remote (например, origin)';

  @override
  String get remoteUrl => 'URL репозитория';

  @override
  String get fetch => 'Получить (Fetch)';

  @override
  String get pull => 'Стянуть (Pull)';

  @override
  String get push => 'Отправить (Push)';

  @override
  String get forcePush => 'Принудительная отправка (Force Push)';

  @override
  String get forcePushWarning =>
      'Force push может перезаписать удалённую историю и нарушить работу коллег. Вы уверены?';

  @override
  String get syncStatus => 'Синхронизация';

  @override
  String get upToDate => 'Синхронизировано с сервером';

  @override
  String aheadBy(int count) {
    return 'Впереди на $count коммит(а/ов)';
  }

  @override
  String behindBy(int count) {
    return 'Позади на $count коммит(а/ов)';
  }

  @override
  String get stashes => 'Тайники (Stashes)';

  @override
  String get createStash => 'Создать тайник';

  @override
  String get stashMessage => 'Описание тайника (необязательно)';

  @override
  String get includeUntracked => 'Включить неотслеживаемые файлы';

  @override
  String get applyStash => 'Применить тайник';

  @override
  String get popStash => 'Извлечь тайник (Pop)';

  @override
  String get dropStash => 'Удалить тайник';

  @override
  String get dropStashConfirm => 'Вы уверены, что хотите удалить этот тайник?';

  @override
  String get noStashes => 'Нет сохранённых тайников.';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeMode => 'Тема оформления';

  @override
  String get systemTheme => 'Системная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get accentColor => 'Акцентный цвет';

  @override
  String get interfaceDensity => 'Плотность интерфейса';

  @override
  String get comfortable => 'Комфортная';

  @override
  String get compact => 'Компактная';

  @override
  String get reduceMotion => 'Уменьшить анимации';

  @override
  String get gitConfiguration => 'Конфигурация Git';

  @override
  String get gitStatus => 'Статус Git';

  @override
  String get gitInstalled => 'Системный Git обнаружен';

  @override
  String get gitNotInstalled => 'Системный Git не найден';

  @override
  String gitVersion(String version) {
    return 'Версия Git: $version';
  }

  @override
  String get gitPath => 'Путь к исполняемому файлу Git';

  @override
  String get chooseCustomGitPath => 'Выбрать пользовательский git.exe';

  @override
  String get gitUserName => 'Имя пользователя Git';

  @override
  String get gitUserEmail => 'Email пользователя Git';

  @override
  String get saveConfig => 'Сохранить настройки Git';

  @override
  String get gitBackend => 'Движок Git-операций';

  @override
  String get backendAuto => 'Гибридный (LibGit2 + Git CLI)';

  @override
  String get backendLibGit2 => 'Только LibGit2';

  @override
  String get backendCli => 'Только системный Git CLI';

  @override
  String get language => 'Язык интерфейса';

  @override
  String get about => 'О программе Gitora';

  @override
  String get version => 'Версия';

  @override
  String get productIdentifier => 'Идентификатор продукта: dev.skrinvex.gitora';

  @override
  String get commandPalette => 'Командная панель';

  @override
  String get commandPalettePlaceholder =>
      'Введите команду или действие (Esc для выхода)...';

  @override
  String get noCommandsFound => 'Команды не найдены';

  @override
  String get onboardingWelcome => 'Добро пожаловать в Gitora';

  @override
  String get onboardingStep1 => '1. Проверка Git';

  @override
  String get onboardingStep2 => '2. Профиль разработчика';

  @override
  String get onboardingStep3 => '3. Оформление и стиль';

  @override
  String get onboardingStep4 => '4. Первый репозиторий';

  @override
  String get onboardingContinue => 'Продолжить';

  @override
  String get onboardingFinish => 'Запустить Gitora';

  @override
  String get onboardingGitReady => 'Движок Git готов к комфортной работе.';

  @override
  String get onboardingGitInstallNote =>
      'Git не найден в системных путях. Вы можете указать путь вручную или установить его с git-scm.com.';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get discard => 'Отменить';

  @override
  String get apply => 'Применить';

  @override
  String get close => 'Закрыть';

  @override
  String get refresh => 'Обновить';

  @override
  String get success => 'Успешно';

  @override
  String get error => 'Ошибка';

  @override
  String get loading => 'Загрузка...';

  @override
  String get toggleWordWrap => 'Перенос строк';

  @override
  String get enableWordWrap => 'Включить перенос строк';

  @override
  String get disableWordWrap => 'Выключить перенос строк';

  @override
  String get preferredTerminal => 'Предпочитаемый терминал';

  @override
  String get terminalAuto => 'Системный по умолчанию (Авто)';

  @override
  String get terminalWindowsTerminal => 'Windows Terminal';

  @override
  String get terminalPowerShell => 'PowerShell';

  @override
  String get terminalCmd => 'Командная строка (cmd)';

  @override
  String get resetOnboarding => 'Сбросить первоначальную настройку';

  @override
  String get resetOnboardingConfirm =>
      'Сбросить первоначальную настройку? Мастер настройки появится при следующем запуске.';

  @override
  String get onboardingResetNotice =>
      'Первоначальная настройка сброшена. Перезапустите приложение.';

  @override
  String get viewLicenses => 'Лицензии зависимостей';

  @override
  String get errors => 'Ошибки';

  @override
  String get warnings => 'Предупреждения';

  @override
  String get output => 'Вывод';

  @override
  String get filterLogs => 'Фильтр логов...';

  @override
  String get clearLogs => 'Очистить логи';

  @override
  String get noLogsRecorded => 'Нет записей в журнале';

  @override
  String get copyMessage => 'Скопировать сообщение';

  @override
  String get copyFullReport => 'Скопировать полный отчёт';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get logs => 'Журнал';

  @override
  String get gitConfigSaved => 'Конфигурация Git успешно сохранена';
}
