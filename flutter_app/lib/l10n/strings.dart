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
  static const forgotSub = 'أدخل بريدك، وسنرسل لك رمز تحقق مكوّنا من ٦ أرقام.';
  static const otpTitle = 'رمز التحقق';
  static const otpSub = 'أدخل الرمز الذي أرسلناه إلى بريدك.';
  static const newPasswordTitle = 'كلمة مرور جديدة';
  static const newPasswordSub = '٨ أحرف على الأقل، تتضمن حرفا كبيرا ورقما.';
  static const sessionExpiredTitle = 'انتهت الجلسة';
  static const sessionExpiredSub = 'لأمانك، طُلب منك تسجيل الدخول مرة أخرى.';
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

  // ---------- Member form ----------
  static const newMember = 'عضو جديد';
  static const editMember = 'تعديل بيانات العضو';
  static const memberName = 'الاسم';
  static const memberNamePlaceholder = 'مثال: أحمد كنعان';
  static const memberDepartment = 'القسم';
  static const memberDepartmentPlaceholder = 'مثال: الإسعاف';
  static const memberNumber = 'الرقم الشخصي';
  static const memberNumberPlaceholder = 'مثال: ١٠٧';
  static const memberNumberHelp = 'رقم يختاره العضو، لا يتكرر داخل المفرزة.';
  static const memberNumberDigitsOnly = 'أدخل أرقاما فقط.';
  static const memberRole = 'الدور في المفرزة';
  static const deleteMember = 'حذف العضو';
  static const deleteMemberBody =
      'سيُحذف العضو من مفرزته ومن كل شفت لم يبدأ بعد. لا يمكن التراجع.';
  static const memberDeleted = 'تم حذف العضو';

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

  // ---------- Batch 0 · item D screens ----------

  // Shared form / action labels
  static const required = 'هذا الحقل مطلوب';
  static const saveChanges = 'حفظ التعديلات';
  static const savedOk = 'تم الحفظ';
  static const noCachedCopy = 'لا نسخة محفوظة.';
  static const optional = 'اختياري';
  static const status = 'الحالة';
  static const percentSign = '٪';

  // Detachment create / edit
  static const newDetachment = 'مفرزة جديدة';
  static const detachmentNamePlaceholder = 'مثال: مفرزة دمشق المركزية';
  static const detachmentRegionPlaceholder = 'مثال: ريف دمشق';
  static const detachmentCenterPlaceholder = 'مثال: مركز داريا';
  static const detachmentNotesPlaceholder = 'ملاحظات داخلية عن المفرزة';
  static const statusActive = 'نشطة';
  static const statusArchived = 'مؤرشفة';
  static const archiveDetachment = 'أرشفة المفرزة';
  static const restoreDetachment = 'إعادة تنشيط المفرزة';

  // Shifts tab
  static const shiftAssignedOfNeeded = 'المسندون';
  static const shiftAttendees = 'المسجّلون';
  static const shiftNoAttendees = 'لا أحد مسند لهذا الشفت بعد.';
  static const shiftCoverageOk = 'التغطية مكتملة';
  static const assignSheetTitle = 'إسناد متطوع';
  static const attendanceSheetTitle = 'تسجيل الحضور';
  static const allMembersAssigned = 'كل أعضاء المفرزة مسندون لهذا الشفت.';
  static const shiftNeeded = 'المطلوب';

  // Storage tab
  static const minimumLevel = 'الحد الأدنى';
  static const noExpiry = 'بلا تاريخ انتهاء';
  static const expired = 'منتهية';
  static const stockOk = 'متوفّر';
  static const stockLowLabel = 'منخفض';
  static const stockEmpty = 'نفد';
  static const itemMovements = 'آخر الحركات';
  static const noMovements = 'لا حركات مسجّلة على هذا الصنف.';
  static const movementIn = 'إدخال';
  static const movementOut = 'صرف';
  static const quantityPlaceholder = 'مثال: ٦';
  static const reasonPlaceholder = 'مثال: صرف لشفت المساء';
  static const record = 'تسجيل';

  // Stats tabs
  static const last7Days = 'آخر ٧ أيام';
  static const statsAttendance = 'نسبة الحضور';
  static const statsCoverage = 'نسبة التغطية';
  static const statsStock = 'الاستهلاك اليومي';
  static const noStats = 'لا إحصائيات بعد.';
  static const noStatsSub = 'ستظهر الأرقام بعد أول أسبوع من التشغيل.';
  static const highest = 'الأعلى';
  static const average = 'المتوسط';

  // Workshop list / edit
  static const searchWorkshops = 'ابحث عن ورشة أو مكان';
  static const filterUpcoming = 'قادمة';
  static const filterPast = 'منتهية';
  static const workshopScheduled = 'مجدولة';
  static const workshopOngoing = 'جارية';
  static const workshopDone = 'منتهية';
  static const newWorkshop = 'ورشة جديدة';
  static const workshopNamePlaceholder = 'مثال: الإسعاف الأولي المتقدم';
  static const workshopLocationPlaceholder = 'مثال: قاعة الشعلان الكبرى';
  static const workshopCapacityPlaceholder = 'مثال: ٢٠';
  static const workshopSeatsLeft = 'مقاعد متبقية';
  static const workshopInvalidCapacity = 'السعة يجب أن تكون رقما أكبر من صفر.';
  static const workshopInvalidDate = 'اختر تاريخا ووقتا للورشة.';
  static const pickDate = 'اختيار التاريخ';
  static const pickTime = 'اختيار الوقت';

  // Workshop tabs
  static const emptyWorkshopTeam = 'لا فريق منظِّم لهذه الورشة.';
  static const emptyWorkshopTeamSub = 'أضف منظِّما ليظهر هنا.';
  static const emptyParticipants = 'لا مشاركين مسجّلين.';
  static const emptyParticipantsSub = 'أضف عضوا أو ضيفا لتبدأ تسجيل الحضور.';
  static const addParticipant = 'أضف مشاركا';
  static const kindMember = 'عضو';
  static const kindGuest = 'ضيف';
  static const totalParticipants = 'إجمالي المشاركين';
  static const presentCount = 'الحاضرون';
  static const attendancePercent = 'نسبة الحضور';
  static const capacityUsage = 'إشغال السعة';
  static const filterMembers = 'الأعضاء';
  static const filterGuests = 'الضيوف';

  // Settings (المزيد)
  static const settingsTitle = 'المزيد';
  static const sectionAccount = 'الحساب';
  static const sectionApp = 'التطبيق';
  static const sectionOrg = 'المؤسسة';
  static const settingsPalette = 'لوحة الألوان';
  static const settingsMode = 'السمة';
  static const settingsModeSystem = 'حسب النظام';
  static const appVersion = 'إصدار التطبيق';

  // Profile
  static const profileName = 'الاسم';
  static const profileEmail = 'البريد الإلكتروني';
  static const profileOrg = 'المؤسسة';
  static const profileNoSession = 'لا جلسة نشطة.';
  static const profileNoSessionSub = 'سجّل الدخول لعرض ملفك الشخصي.';

  // Security
  static const securityMfa = 'التحقق بخطوتين';
  static const securityMfaOn = 'مفعّل';
  static const securityMfaManage = 'إدارة';
  static const securityCurrentSession = 'الجلسة الحالية';
  static const securityRevokeConfirm = 'إنهاء هذه الجلسة؟';
  static const emptySessions = 'لا جلسات أخرى.';
  static const emptySessionsSub = 'هذا هو الجهاز الوحيد المسجّل حاليا.';
  static const startedAt = 'بدأت';

  // Notifications
  static const notifShiftReminders = 'تذكير بالشفتات';
  static const notifShiftRemindersSub = 'تنبيه قبل بداية شفتك بساعة.';
  static const notifStockAlerts = 'تنبيهات المخزون';
  static const notifStockAlertsSub = 'عند انخفاض صنف عن حدّه الأدنى.';
  static const notifWorkshopUpdates = 'تحديثات الورش';
  static const notifWorkshopUpdatesSub = 'تغيّر موعد أو مكان ورشة مسجّل فيها.';
  static const notifJoinRequests = 'طلبات الانضمام';
  static const notifJoinRequestsSub = 'عند تقديم طلب انضمام جديد لمفرزتك.';

  // Org info
  static const orgLegalName = 'الاسم القانوني';
  static const orgAddress = 'العنوان';
  static const orgEmail = 'البريد العام';
  static const orgDetachments = 'عدد المفرزات';
  static const orgMembers = 'عدد الأعضاء';

  // ---------- Tenants (الجهات) ----------
  static const navTenants = 'الجهات';
  static const tenantsTitle = 'الجهات';
  static const tenant = 'الجهة';
  static const searchTenants = 'ابحث عن جهة';
  static const newTenant = 'جهة جديدة';
  static const createTenant = 'أنشئ جهة';
  static const editTenant = 'تعديل الجهة';
  static const tenantName = 'اسم الجهة';
  static const tenantNamePlaceholder = 'مثال: الهلال الأحمر — فرع دمشق';
  static const tenantNotes = 'وصف مختصر';
  static const tenantNotesPlaceholder = 'اختياري — لمن تتبع هذه الجهة';
  static const tenantDetachments = 'المفرزات';
  static const tenantMembers = 'الأعضاء';
  static const emptyTenants = 'لا جهات بعد.';
  static const emptyTenantsSub =
      'الجهة هي المظلّة التي تجمع مفرزاتك. أنشئ واحدة ثم أضف مفرزاتها.';
  static const deleteTenant = 'حذف الجهة';
  static const deleteTenantBody =
      'سيُحذف كل ما داخل هذه الجهة: المفرزات وأعضاؤها وشفتاتها ومخزونها. لا يمكن التراجع.';
  static const tenantDeleted = 'تم حذف الجهة';
  static const tenantEmptyDetachments = 'لا مفرزات في هذه الجهة بعد.';
  static const tenantEmptyDetachmentsSub =
      'أضف أول مفرزة لتبدأ بجدولة الشفتات وإدارة الفريق والمخزن.';
  static const openTenant = 'فتح';
  static const tenantHint =
      'الجهة تجمع عدة مفرزات في نفس المكان تحت إدارة واحدة.';

  // ---------- Detachment lifecycle ----------
  static const deleteDetachment = 'حذف المفرزة';
  static const deleteDetachmentBody =
      'سيُحذف كل ما داخل المفرزة: الأعضاء والشفتات والمخزون. لا يمكن التراجع.';
  static const detachmentDeleted = 'تم حذف المفرزة';
  static const belongsTo = 'ضمن';

  // ---------- Schedule (الجدول) ----------
  static const scheduleTitle = 'جدول الشفتات';
  static const weekOf = 'أسبوع';
  static const thisWeek = 'هذا الأسبوع';
  static const nextWeek = 'الأسبوع القادم';
  static const prevWeek = 'الأسبوع السابق';
  static const daySat = 'السبت';
  static const daySun = 'الأحد';
  static const dayMon = 'الإثنين';
  static const dayTue = 'الثلاثاء';
  static const dayWed = 'الأربعاء';
  static const dayThu = 'الخميس';
  static const dayFri = 'الجمعة';
  static const addShift = 'أضف شفتا';
  static const editShift = 'تعديل الشفت';
  static const deleteShift = 'حذف الشفت';
  static const deleteShiftBody = 'سيُحذف الشفت ومن أُسند إليه. لا يمكن التراجع.';
  static const shiftDeleted = 'تم حذف الشفت';
  static const shiftSaved = 'تم حفظ الشفت';
  static const shiftPeriod = 'الفترة';
  static const periodMorning = 'صباحي';
  static const periodEvening = 'مسائي';
  static const periodNight = 'ليلي';
  static const periodCustom = 'مخصص';
  static const periodMorningTime = '٠٨:٠٠ – ١٤:٠٠';
  static const periodEveningTime = '١٤:٠٠ – ٢٠:٠٠';
  static const periodNightTime = '٢٠:٠٠ – ٠٢:٠٠';
  static const shiftStart = 'من';
  static const shiftEnd = 'إلى';
  static const shiftCenter = 'المركز';
  static const shiftNeededLabel = 'عدد المطلوبين';
  static const shiftNeededHelp = 'كم شخصا يحتاج هذا الشفت ليكتمل؟';
  static const repeatWeekly = 'كرّره كل أسبوع';
  static const repeatWeeklyHelp =
      'سيظهر تلقائيا في نفس اليوم من كل أسبوع، ويمكنك إيقافه لاحقا.';
  static const crossesMidnight = 'ينتهي بعد منتصف الليل';
  static const copyLastWeek = 'انسخ الأسبوع السابق';
  static const copyLastWeekDone = 'تم نسخ شفتات الأسبوع السابق';
  static const copyLastWeekEmpty = 'لا شفتات في الأسبوع السابق لنسخها.';
  static const applyTemplates = 'طبّق الشفتات المتكررة';
  static const applyTemplatesDone = 'تمت إضافة الشفتات المتكررة';
  static const applyTemplatesEmpty = 'لا شفتات متكررة محفوظة بعد.';
  static const templatesTitle = 'الشفتات المتكررة';
  static const templatesSub =
      'قوالب تتكرر أسبوعيا. أوقف أيّها متى شئت دون أن تفقد سجلّ الأسابيع الماضية.';
  static const templateStop = 'إيقاف التكرار';
  static const templateStopped = 'تم إيقاف التكرار';
  static const noShiftsToday = 'لا شفتات في هذا اليوم.';
  static const noShiftsTodaySub = 'أضف شفتا، أو انسخ جدول الأسبوع السابق.';
  static const weekCoverage = 'تغطية الأسبوع';
  static const weekShifts = 'شفتات الأسبوع';
  static const weekGaps = 'شفتات ناقصة';
  static const assignedLabel = 'مسند';
  static const removeFromShift = 'إزالة من الشفت';
  static const shiftConflict = 'هذا العضو مسند لشفت آخر يتقاطع مع هذا الوقت.';
  static const quickFill = 'إسناد سريع';
  static const quickFillHelp = 'يملأ النقص بأعضاء متاحين في هذا الوقت.';
  static const quickFillDone = 'تمت تعبئة النقص';
  static const quickFillNone = 'لا يوجد أعضاء متاحون في هذا الوقت.';
  static const availableNow = 'متاح';
  static const busyNow = 'مشغول في شفت آخر';
  static const startAfterEnd = 'وقت البداية يجب أن يختلف عن وقت النهاية.';
  static const guideAddShift =
      'ابدأ باختيار فترة جاهزة — يمكنك تعديل الوقت بعدها.';

  // ---------- Inventory lifecycle ----------
  static const newItem = 'صنف جديد';
  static const editItem = 'تعديل الصنف';
  static const itemName = 'اسم الصنف';
  static const itemNamePlaceholder = 'مثال: أدرينالين ١ ملغ/مل';
  static const itemUnit = 'الوحدة';
  static const itemUnitPlaceholder = 'مثال: أمبولة';
  static const itemOpeningStock = 'الكمية الحالية';
  static const itemMinimum = 'الحد الأدنى';
  static const itemMinimumHelp = 'عند نزول الكمية تحت هذا الرقم يظهر تنبيه.';
  static const itemExpiry = 'تاريخ الانتهاء';
  static const itemNoExpiry = 'بلا تاريخ انتهاء';
  static const deleteItem = 'حذف الصنف';
  static const deleteItemBody = 'سيُحذف الصنف وكل حركاته. لا يمكن التراجع.';
  static const itemDeleted = 'تم حذف الصنف';
  static const itemSaved = 'تم حفظ الصنف';
  static const addItem = 'أضف صنفا';
  static const filterLow = 'منخفض';
  static const filterExpiring = 'قارب الانتهاء';
  static const searchItems = 'ابحث عن صنف';
  static const invalidNumber = 'أدخل رقما صحيحا.';

  // ---------- Stats + export ----------
  static const statsOverview = 'لمحة';
  static const statsMembers = 'الفريق';
  static const statsShifts = 'الشفتات';
  static const statsStorage = 'المخزن';
  static const exportReport = 'تصدير تقرير';
  static const exportTitle = 'بناء التقرير';
  static const exportSub = 'اختر ما تريد ظهوره في الملف، ثم عاين قبل التصدير.';
  static const exportSections = 'أقسام التقرير';
  static const exportFormat = 'صيغة الملف';
  static const exportPdf = 'PDF';
  static const exportExcel = 'Excel (CSV)';
  static const exportPreview = 'معاينة';
  static const exportRange = 'المدى الزمني';
  static const rangeWeek = 'أسبوع';
  static const rangeMonth = 'شهر';
  static const rangeQuarter = 'ثلاثة أشهر';
  static const secSummary = 'الملخّص العام';
  static const secSummarySub = 'اسم المفرزة، الجهة، التغطية، عدد الأعضاء.';
  static const secMembers = 'جدول الأعضاء';
  static const secMembersSub = 'الاسم، القسم، الرقم، الدور، الحضور.';
  static const secShifts = 'جدول الشفتات';
  static const secShiftsSub = 'اليوم، الوقت، المركز، المسندون، النقص.';
  static const secStorage = 'جرد المخزن';
  static const secStorageSub = 'الصنف، الكمية، الحد الأدنى، الصلاحية.';
  static const secStorageLow = 'الأصناف المنخفضة فقط';
  static const secStorageLowSub = 'قائمة مختصرة لما يحتاج تزويدا.';
  static const secAttendance = 'منحنى الحضور';
  static const secAttendanceSub = 'نسبة الحضور اليومية خلال المدى المختار.';
  static const secCoverage = 'منحنى التغطية';
  static const secCoverageSub = 'نسبة تغطية الشفتات اليومية.';
  static const secConsumption = 'استهلاك المخزون';
  static const secConsumptionSub = 'الوحدات المصروفة يوميا.';
  static const exportNothingSelected = 'اختر قسما واحدا على الأقل.';
  static const exportCopy = 'نسخ محتوى الملف';
  static const exportCopied = 'نُسخ محتوى التقرير إلى الحافظة';
  static const exportSelectAll = 'تحديد الكل';
  static const exportClearAll = 'إلغاء التحديد';
  static const reportGeneratedAt = 'أُنشئ في';
  static const reportFor = 'تقرير مفرزة';
  static const noData = 'لا بيانات';
  static const sectionsChosen = 'قسم مختار';

  // ---------- Beginner guidance ----------
  static const stepOne = 'الخطوة ١';
  static const stepTwo = 'الخطوة ٢';
  static const stepThree = 'الخطوة ٣';
  static const gotIt = 'فهمت';
}
