/// Every user-facing string in the app. Widgets import `S` and read a key —
/// no Arabic literals in widget code. When real localization is wired later,
/// only this file changes.
///
/// Keys grouped by feature.
abstract final class S {
  // ---------- App-wide ----------
  static const appName = 'MTM';
  static const retry = 'إعادة المحاولة';
  static const cancel = 'إلغاء';
  static const save = 'حفظ';
  static const confirm = 'تأكيد';
  static const close = 'إغلاق';
  static const search = 'بحث';
  static const filter = 'تصفية';
  static const all = 'الكل';
  static const more = 'المزيد';
  static const details = 'التفاصيل';
  static const edit = 'تعديل';
  static const delete = 'حذف';
  static const create = 'إنشاء';
  static const done = 'تم';
  static const back = 'رجوع';
  static const next = 'التالي';
  static const previous = 'السابق';
  static const copy = 'نسخ';
  static const copied = 'تم النسخ';
  static const yes = 'نعم';
  static const no = 'لا';
  static const now = 'الآن';
  static const empty = 'لا يوجد بعد';

  // ---------- Bottom nav ----------
  static const navHome = 'الرئيسية';
  static const navDetachment = 'المفرزة';
  static const navWorkshop = 'الورشة';
  static const navMore = 'المزيد';

  // ---------- Detachment tabs ----------
  static const detachmentTeam = 'الفريق وأدواره';
  static const detachmentShifts = 'الشفتات';
  static const detachmentStorage = 'المخزن';
  static const detachmentStats = 'الإحصائيات';

  // ---------- Workshop tabs ----------
  static const workshopTeam = 'الفريق وأدواره';
  static const workshopMembers = 'الأعضاء والضيوف';
  static const workshopStats = 'الإحصائيات';

  // ---------- Auth ----------
  static const login = 'تسجيل الدخول';
  static const loginTitle = 'أهلا بعودتك';
  static const loginSub = 'سجّل الدخول لمتابعة عمل مفرزتك';
  static const emailLabel = 'البريد الإلكتروني أو اسم المستخدم';
  static const passwordLabel = 'كلمة المرور';
  static const forgotPassword = 'نسيت كلمة المرور؟';
  static const signIn = 'دخول';
  static const noAccount = 'ليس لديك حساب؟';
  static const requestAccess = 'اطلب الانضمام';
  static const mfaSetupTitle = 'تفعيل التحقق بخطوتين';
  static const mfaSetupSub =
      'امسح رمز QR باستخدام تطبيق مصادقة، أو أدخل السرّ يدويا.';
  static const mfaManualSecret = 'السرّ اليدوي';
  static const mfaBackupCodesTitle = 'رموز الاستعادة';
  static const mfaBackupCodesSub =
      'احفظ هذه الرموز في مكان آمن — كل رمز يُستخدم مرة واحدة فقط.';
  static const mfaChallengeTitle = 'أدخل رمز التحقق';
  static const mfaChallengeSub =
      'أدخل الرمز المكوّن من ٦ أرقام من تطبيق المصادقة.';
  static const forgotTitle = 'إعادة تعيين كلمة المرور';
  static const forgotSub =
      'أدخل بريدك، وسنرسل لك رمز تحقق مكوّنا من ٦ أرقام.';
  static const otpTitle = 'رمز التحقق';
  static const otpSub = 'أدخل الرمز الذي أرسلناه إلى بريدك.';
  static const newPasswordTitle = 'كلمة مرور جديدة';
  static const newPasswordSub =
      '٨ أحرف على الأقل، تتضمن حرفا كبيرا ورقما.';
  static const sessionExpiredTitle = 'انتهت الجلسة';
  static const sessionExpiredSub =
      'لأمانك، طُلب منك تسجيل الدخول مرة أخرى.';
  static const newDeviceTitle = 'جهاز جديد';
  static const newDeviceSub =
      'رصدنا محاولة دخول من جهاز لا نعرفه. أكّد أنه أنت.';
  static const yesItsMe = 'نعم، هذا أنا';
  static const notMe = 'ليس أنا';

  // ---------- Home ----------
  static const homeGreeting = 'أهلا';
  static const activeShift = 'شفتك الآن';
  static const noActiveShift = 'لا يوجد شفت نشط الآن';
  static const timeRemaining = 'الوقت المتبقي';
  static const attendanceProgress = 'الحضور';
  static const primaryAction = 'تسجيل حضور';
  static const needsYourDecision = 'يحتاج قرارك';
  static const secondaryStats = 'لمحة عامة';
  static const unfilledShifts = 'شفتات غير مكتملة';
  static const expiringStock = 'مخزون قارب على الانتهاء';
  static const pendingJoinRequests = 'طلبات انضمام معلّقة';
  static const workshopsThisWeek = 'ورش هذا الأسبوع';
  static const attendanceRate = 'نسبة الحضور';
  static const stockLow = 'أدوية منخفضة';

  // ---------- Detachment ----------
  static const detachments = 'المفرزات';
  static const detachmentListTitle = 'المفرزات';
  static const filterActive = 'نشطة';
  static const filterArchived = 'مؤرشفة';
  static const filterAll = 'الكل';
  static const searchDetachments = 'ابحث عن مفرزة أو مركز';
  static const createDetachment = 'مفرزة جديدة';
  static const editDetachment = 'تعديل المفرزة';
  static const detachmentName = 'اسم المفرزة';
  static const detachmentRegion = 'المنطقة';
  static const detachmentCenter = 'المركز الرئيسي';
  static const detachmentNotes = 'ملاحظات';
  static const memberCount = 'الأعضاء';
  static const shiftCount = 'الشفتات هذا الأسبوع';
  static const coverage = 'التغطية';
  static const emptyDetachments = 'لا مفرزات بعد.';
  static const emptyDetachmentsSub =
      'أنشئ مفرزتك الأولى لتبدأ بجدولة الشفتات وإدارة الفريق.';

  // ---------- Team ----------
  static const teamListTitle = 'أعضاء الفريق';
  static const roleLead = 'قائد مفرزة';
  static const roleMedic = 'مسعف';
  static const roleTrainee = 'متدرب';
  static const roleVolunteer = 'متطوع';
  static const changeRole = 'تغيير الدور';
  static const assignRole = 'تعيين دور';
  static const emptyTeam = 'لا أعضاء في هذه المفرزة بعد.';
  static const emptyTeamSub = 'أضف أول عضو لتبدأ بتوزيع الأدوار والشفتات.';
  static const addMember = 'أضف عضوا';

  // ---------- Shifts ----------
  static const shiftsTitle = 'شفتات اليوم';
  static const coverageGap = 'نقص في التغطية';
  static const assignVolunteer = 'إسناد متطوع';
  static const checkIn = 'تسجيل الحضور';
  static const present = 'حاضر';
  static const late = 'متأخر';
  static const absent = 'غائب';
  static const notInvited = 'لم يُدعَ';
  static const emptyShifts = 'لا شفتات اليوم.';
  static const emptyShiftsSub = 'أنشئ شفتا جديدا لبدء تسجيل الحضور.';
  static const newShift = 'شفت جديد';

  // ---------- Inventory ----------
  static const storageTitle = 'المخزن';
  static const stockIn = 'إدخال';
  static const stockOut = 'صرف';
  static const currentStock = 'المخزون الحالي';
  static const expiresOn = 'تنتهي في';
  static const daysToExpiry = 'يوم للانتهاء';
  static const belowMinimum = 'أقل من الحد الأدنى';
  static const movementSheet = 'حركة مخزون';
  static const quantity = 'الكمية';
  static const reason = 'السبب';
  static const emptyInventory = 'المخزن فارغ.';
  static const emptyInventorySub = 'أضف صنفا لتبدأ بتتبع الحركة والصلاحية.';

  // ---------- Workshops ----------
  static const workshopsTitle = 'الورش';
  static const emptyWorkshops = 'لا ورش مجدولة.';
  static const emptyWorkshopsSub = 'أنشئ ورشة جديدة لفتح باب التسجيل.';
  static const createWorkshop = 'ورشة جديدة';
  static const editWorkshop = 'تعديل الورشة';
  static const workshopName = 'اسم الورشة';
  static const workshopDate = 'التاريخ';
  static const workshopCapacity = 'السعة';
  static const workshopLocation = 'المكان';
  static const registeredMembers = 'الأعضاء المسجّلون';
  static const guests = 'الضيوف';
  static const markAttendance = 'وضع الحضور';
  static const capacity = 'السعة';
  static const full = 'مكتملة';

  // ---------- Stats ----------
  static const statsWeekly = 'أسبوعي';
  static const statsMonthly = 'شهري';
  static const consumption = 'الاستهلاك';

  // ---------- Settings (المزيد) ----------
  static const settingsProfile = 'الملف الشخصي';
  static const settingsSecurity = 'الأمان';
  static const settingsSessions = 'الجلسات النشطة';
  static const settingsDevices = 'الأجهزة المربوطة';
  static const settingsRevoke = 'إلغاء';
  static const settingsNotifications = 'التنبيهات';
  static const settingsOrg = 'المؤسسة';
  static const settingsAppearance = 'المظهر';
  static const settingsMotion = 'مستوى الحركة';
  static const settingsMotionSub =
      'قلّل الحركة لتحسين الأداء على الأجهزة القديمة أو لتفضيل تجربة أهدأ.';
  static const settingsMotionFull = 'حركة كاملة';
  static const settingsMotionReduced = 'حركة مخففة';
  static const settingsPaletteSlate = 'Slate';
  static const settingsPaletteCopper = 'Copper';
  static const settingsPaletteClay = 'Clay';
  static const settingsModeLight = 'فاتح';
  static const settingsModeDark = 'داكن';
  static const signOut = 'تسجيل الخروج';
  static const signOutConfirm = 'هل تريد تسجيل الخروج فعلا؟';

  // ---------- States (loading / empty / error / offline) ----------
  static const errTitle = 'تعذّر التحميل';
  static const errGeneric =
      'حدث خطأ أثناء جلب البيانات. تحقق من اتصالك ثم أعد المحاولة.';
  static const offlineTitle = 'بدون اتصال';
  static const offlineSub = 'تعرض بيانات محلية. آخر تحديث ';
  static const staleData = 'بيانات محفوظة — لم يتم التحديث';
  static const partialRefreshFailed = 'تعذّر التحديث في الخلفية';

  // ---------- Time labels ----------
  static const secondsAgo = 'قبل ثوانٍ';
  static const minAgo = 'قبل دقيقة';
  static const minsAgo = 'قبل %d دقيقة';
  static const hourAgo = 'قبل ساعة';
  static const hoursAgo = 'قبل %d ساعات';
  static const today = 'اليوم';
  static const tomorrow = 'غدا';
  static const yesterday = 'أمس';
}
