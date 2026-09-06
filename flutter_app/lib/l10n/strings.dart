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
  static const roleShiftSupervisor = 'مشرف الشفت';
  static const roleAdministrator = 'إداري';
  static const roleFollowUp = 'متابعة';
  static const roleMember = 'عضو';
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
  static const notCheckedIn = 'لم يسجل الدخول';
  static const checkedIn = 'سجّل الدخول';
  static const checkedOut = 'سجّل الخروج';
  static const absent = 'غائب';
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
  static const settingsProfile = 'حسابي';
  static const settingsSecurity = 'الأمان';
  static const settingsSessions = 'الجلسات النشطة';
  static const settingsDevices = 'الأجهزة المربوطة';
  static const settingsRevoke = 'إلغاء';
  static const settingsNotifications = 'التنبيهات';
  static const settingsOrg = 'المؤسسة';
  static const settingsAppearance = 'المظهر';
  static const settingsMotion = 'جودة الحركة والأداء';
  static const settingsMotionSub =
      'اختر مستوى الحركة المناسب لجهازك. المستويات الأخف تختصر مدة الحركة '
      'وتوقف التأثيرات المكلفة لتبقى الواجهة سريعة الاستجابة.';
  static const settingsMotionPerformance = 'الأداء';
  static const settingsMotionLow = 'منخفضة';
  static const settingsMotionBalanced = 'متوازنة';
  static const settingsMotionHigh = 'عالية';
  static const settingsMotionMaximum = 'أقصى سلاسة';
  static const settingsMotionPerformanceHint =
      'الحركة موقوفة عمليا: تظهر الواجهة في حالتها النهائية مباشرة، بلا '
      'ضبابية ولا ظلال إضافية ولا تأثيرات متكررة. أقصى سرعة استجابة، '
      'للأجهزة الضعيفة.';
  static const settingsMotionLowHint =
      'حركة قصيرة وخفيفة: بلا ضبابية ولا تأثيرات متكررة، والأرقام والأشرطة '
      'تظهر بقيمتها فورا.';
  static const settingsMotionBalancedHint =
      'الوضع الافتراضي المنصوح به: كل التأثيرات حاضرة بتكلفة مخفضة ومدة '
      'أقصر.';
  static const settingsMotionHighHint =
      'انتقالات أنعم: المدد الكاملة، ضبابية أوسع، تدرّج أعمق للقوائم، '
      'ومنحنيات الحركة المميزة للتطبيق.';
  static const settingsMotionMaximumHint =
      'أعلى جودة: أوسع مسافة حركة وضبابية، مع تلاشٍ متقاطع كامل بين '
      'التبويبات. بلا أي تأثير مهدور.';
  static const settingsMotionOsNotice =
      'نظام الجهاز يطلب إيقاف الحركة، وهذا الطلب مطبَّق حاليا فوق المستوى '
      'المختار.';
  // ---- Themes & Performance ----
  static const sectionThemesPerformance = 'السمات والأداء';
  static const settingsQuality = 'جودة الرسوم والحركة';
  static const settingsQualitySub =
      'يحدد هذا الخيار حجم العمل في كل إطار: مدة الحركة، الضبابية، الظلال، '
      'والتأثيرات المتكررة. المستويات الأخف تبقي الواجهة أسرع استجابة.';
  static const settingsFrameRate = 'معدل الإطارات';
  static const settingsFrameRateSub =
      'المعدل المطلوب من شاشة الجهاز. لا يقوم التطبيق بإسقاط إطارات أبدا، '
      'بل يطلب من النظام وضع العرض المناسب.';
  static const settingsFrameRateAuto = 'تلقائي';
  static const settingsFrameRate30 = '٣٠ إطار/ث';
  static const settingsFrameRate60 = '٦٠ إطار/ث';
  static const settingsFrameRate90 = '٩٠ إطار/ث';
  static const settingsFrameRate120 = '١٢٠ إطار/ث';
  static const settingsFrameRateAutoHint =
      'يترك الاختيار للنظام: يخفض المعدل على الشاشات الساكنة ويرفعه عند '
      'التمرير. الخيار الآمن على كل الأجهزة.';
  static const settingsFrameRateFixedHint =
      'يطلب من النظام تثبيت وضع عرض بهذا المعدل طوال استخدام التطبيق.';
  static const settingsFrameRateUnsupported =
      'هذا الجهاز لا يتيح للتطبيقات اختيار معدل الإطارات، لذا يبقى الوضع '
      'التلقائي هو الخيار الوحيد.';
  static const settingsFrameRateCurrent = 'المعدل الحالي للشاشة';
  static const settingsFrameRateNearest =
      'أقرب معدل تدعمه الشاشة هو المستخدَم فعليا.';
  static const settingsFrameRateHz = 'هرتز';

  // ---- Shifts: day copy, template dates, card summary ----
  static const copyPreviousDay = 'انسخ اليوم السابق';
  static const copyPreviousDayDone = 'تم نسخ شفتات اليوم السابق.';
  static const copyPreviousDayEmpty = 'لا شفتات في اليوم السابق للنسخ.';
  static const shiftManager = 'مسؤول الشفت';
  static const shiftManagerUnset = 'لم يُحدَّد مسؤول للشفت';
  static const templateEditTitle = 'أيام القالب';
  static const templateEditSub =
      'اختر الأيام التي يتكرر فيها هذا الشفت. إضافة يوم تنشئ شفتا عليها، '
      'وإزالة يوم تحذف شفته إن كان فارغا فقط — اليوم الذي عليه أفراد يبقى '
      'كما هو.';
  static const templateEdit = 'تعديل الأيام';
  static const templateSaved = 'تم تحديث أيام القالب.';
  static const templateLockedDay = 'يوم عليه أفراد — لا يمكن إزالته.';
  static const templateNeedsTwoDays =
      'قالب بيوم واحد لم يعد تكرارا، وسيتوقف عند الحفظ.';

  // ---- Workshop statistics (dashboard, detail, export) ----
  static const workshopStatsTitle = 'إحصائيات الورشة';
  static const workshopStatsSubtitle = 'تقرير الأداء والحضور';
  static const statsGroupParticipants = 'طلاب/ضيوف';
  static const statsGroupTeam = 'الفريق';
  static const statsAttendanceSection = 'معدلات الحضور';
  static const statsFinanceSection = 'الملخص المالي';
  static const statsDetailSection = 'التفصيل';
  static const statsPresentAbsent = 'حاضر / غائب';
  static const statsPayers = 'الدافعون';
  static const statsNonPayers = 'غير دافع/غير محدد';
  static const statsTotalCollected = 'الإجمالي';
  static const statsRegistrationFee = 'رسم الاشتراك';
  static const statsFreeWorkshop = 'ورشة مجانية — لا رسم اشتراك';
  static const paymentPaid = 'دافع';
  static const paymentUnpaid = 'غير دافع';
  static const paymentUnspecified = 'غير محدد';
  static const participantGuest = 'ضيف';
  static const participantMember = 'متطوع';
  static const currencyUnit = 'ل.س';
  static const statsColCategory = 'الفئة';
  static const statsColPresent = 'الحاضر';
  static const statsColAbsent = 'الغائب';
  static const statsColName = 'الاسم';
  static const statsColRole = 'الدور';
  static const statsColAttendance = 'الحضور';
  static const statsColPayment = 'الدفع';
  static const statsCopyTitle = 'نسخ الأسماء';
  static const statsCopySub =
      'نسخ سريع لأسماء الدافعين فقط بصيغة "رقم - اسم" للصق المباشر في '
      'المحادثات والقوائم.';
  static const statsCopyParticipants = 'نسخ المشاركين';
  static const statsCopyTeam = 'نسخ الفريق';
  static const statsCopyEmpty = 'لا توجد أسماء في هذه القائمة بعد';
  static const statsCopyNoPayers = 'لا يوجد دافعون في هذه القائمة بعد';
  static const statsCopyDone = 'تم نسخ أسماء الدافعين';
  static const statsExportTitle = 'تصدير التقرير الكامل';
  static const statsExportSub =
      'ملف واحد يشمل ملخص الحضور والدفع مع الإجمالي المالي، وقائمة المشاركين '
      'وقائمة الفريق بالأسماء والأدوار.';
  static const statsExportCustom = 'تصدير مخصص';
  static const statsExportCustomSub =
      'اختر الأقسام التي تريد تضمينها في ملف تقرير الورشة.';
  static const statsSecSummary = 'ملخص الحضور والدفع';
  static const statsSecSummarySub = 'حضور وغياب ودفع كل فئة مع الإجمالي المالي';
  static const statsSecParticipants = 'قائمة المشاركين';
  static const statsSecParticipantsSub = 'الأسماء مرقمة مع الحضور وحالة الدفع';
  static const statsSecTeam = 'قائمة أعضاء الفريق';
  static const statsSecTeamSub = 'الأسماء مرقمة مع الدور والحضور وحالة الدفع';
  static const statsExportEmpty = 'لا توجد بيانات لتصديرها بعد';
  static const statsNoParticipants = 'لا يوجد مشاركون مسجلون بعد.';
  static const statsNoTeam = 'لا يوجد أعضاء فريق مسجلون بعد.';
  static const statsFinancialTotalLine = 'الإجمالي المالي';
  static const statsPayerMultiplier = 'دافع ×';

  static const settingsMotionFull = 'حركة كاملة';
  static const settingsMotionReduced = 'حركة مخففة';
  static const settingsPaletteMedical = 'طبّي';
  static const settingsPaletteSlate = 'Slate';
  static const settingsPaletteCopper = 'Copper';
  static const settingsPaletteClay = 'Clay';
  static const settingsPaletteIndigo = 'Indigo';
  static const settingsPaletteTeal = 'Teal';
  static const settingsModeLight = 'فاتح';
  static const settingsModeDark = 'داكن';
  static const settingsEyeProtect = 'حماية العين';
  static const settingsEyeProtectSub =
      'تدرّج دافئ منخفض الأزرق يريح العين في الإضاءة الخافتة. يعمل فوق أي لوحة ألوان.';
  static const settingsEyeProtectOn = 'مفعّلة';
  static const settingsEyeProtectOff = 'متوقفة';
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

  // ---------- Forced upgrade (blocking app state) ----------
  static const upgradeTitle = 'التطبيق يحتاج إلى تحديث';
  static const upgradeBody =
      'هذا الإصدار لم يعد مدعوما. يرجى تحديث MTM للاستمرار في استخدام '
      'نظام إدارة الفرق الطبية.';
  static const upgradeCurrentVersion = 'الإصدار الحالي';
  static const upgradeMinimumVersion = 'الحد الأدنى المدعوم';
  static const upgradeAction = 'تحديث التطبيق';
  static const upgradeChecking = 'جارٍ التحقق من الإصدار';
  static const upgradeCheckFailedTitle = 'تعذّر التحقق من التحديث';
  static const upgradeCheckFailedBody =
      'تعذّر الاتصال للتحقق من التحديث. تحقق من اتصال الإنترنت وحاول مرة أخرى.';
  static const upgradeLinkCopied = 'نُسخ رابط التحديث';
  static const upgradeLinkUnavailable = 'رابط التحديث غير متاح حاليا.';

  // ---------- Problem / error taxonomy ----------
  // Frontend-owned copy for known problem codes. Widgets never show backend
  // `detail` text for these — see FRONTEND-BACKEND-INTEGRATION.md §2.
  static const problemUnexpectedTitle = 'تعذر إكمال العملية';
  static const problemUnexpectedBody = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  static const errNotFound = 'لم يُعثر على العنصر المطلوب.';
  static const errNotPermittedTitle = 'صلاحية غير متوفرة';
  static const errNotPermitted = 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
  static const errConflictTitle = 'تغيّر هذا العنصر';
  static const errConflict =
      'حدّثه شخص آخر قبلك. أعد التحميل ثم حاول مرة أخرى.';
  // Optimistic-concurrency stale write (`ProblemCode.staleWrite`) — distinct
  // from errConflict above. No blind retry is offered: resubmitting the same
  // write against the same (now-stale) version fails the same way again: see
  // FRONTEND-BACKEND-INTEGRATION.md §4.
  static const errStaleWriteTitle = 'تغيّر هذا العنصر من جهاز آخر';
  static const errStaleWrite =
      'حدَّثه شخص آخر منذ أن بدأت تعديلك. راجع الفروقات ثم اختر النسخة المناسبة.';
  static const errValidation = 'تحقّق من الحقول المميّزة ثم أعد المحاولة.';
  static const errServer =
      'تعذّر إكمال الطلب على الخادم. حاول مرة أخرى بعد قليل.';
  static const errNetwork =
      'تعذّر الوصول إلى الخادم. تحقّق من الاتصال وحاول مجددا.';
  // Label for a safe support reference on a substantial unexpected-error
  // screen. Only shown when the backend actually provides an id.
  static const problemReferenceLabel = 'مرجع الدعم';

  // ---------- Conflict resolution ----------
  // Feature adapters own field labels and formatted values. These strings
  // describe only the shared resolution workflow; no backend message or raw
  // field path is presented by the generic screen.
  static const conflictReviewTitle = 'مراجعة التعارض';
  static const conflictTitle = 'وجد تعارض في التعديلات';
  static const conflictDescription =
      'تم تعديل هذه البيانات من جهاز آخر قبل مزامنة تعديلاتك. راجع النسختين واختر التعديل المناسب.';
  static const conflictLocalVersion = 'نسختك';
  static const conflictLocalVersionSub = 'تعديلاتك غير المزامنة';
  static const conflictCurrentVersion = 'النسخة الحالية';
  static const conflictCurrentVersionSub = 'آخر نسخة تمت مزامنتها مع الفريق';
  static const conflictDifferencesTitle = 'التعديلات المختلفة';
  static const conflictDifferencesBody =
      'تظهر هنا الحقول التي تختلف بين النسختين فقط.';
  static const conflictUseLocal = 'استخدام تعديلي';
  static const conflictUseCurrent = 'استخدام النسخة الحالية';
  static const conflictReviewLater = 'مراجعة لاحقاً';
  static const conflictDecisionFailed =
      'تعذّر حفظ اختيارك. لم يُغلق التعارض، ويمكنك المحاولة مرة أخرى.';
  static const conflictUnavailableTitle = 'التعارض غير متاح الآن';
  static const conflictUnavailableBody =
      'ارجع إلى المزامنة أو قائمة المراجعة وافتح التعارض من هناك.';
  static const conflictShiftRecord = 'الشفت';
  static const conflictShiftDate = 'التاريخ';
  static const conflictShiftTime = 'الوقت';

  // Choosing the shared version throws away an unsynced local edit, so it is
  // the one choice on this screen that asks first (roadmap §17).
  static const conflictUseCurrentConfirmTitle = 'استخدام النسخة الحالية؟';
  static const conflictUseCurrentConfirmBody =
      'سيؤدي هذا إلى تجاهل تعديلك غير المزامن، ولا يمكن التراجع عنه.';

  // Why a resolution could not be applied. Each answers the same three
  // questions: what happened, is my data safe, what can I do now.
  static const conflictAlreadyResolved = 'تم حل هذا التعارض بالفعل.';
  static const conflictRecordChanged =
      'تغيرت هذه البيانات مرة أخرى. افتح التعارض من جديد لمراجعة أحدث نسخة.';
  static const conflictRecordDeleted =
      'تم حذف هذا السجل من جهاز آخر، ولم يعد من الممكن تطبيق تعديلك عليه.';
  static const conflictNotPermitted =
      'لا تملك صلاحية تنفيذ هذا التغيير. تعديلك محفوظ ولم يُفقد.';
  static const conflictOfflineDecision =
      'يحتاج هذا الاختيار اتصالا بالإنترنت. تعديلك محفوظ ولم يُفقد.';

  // ---------- Needs Review inbox ----------
  // The explicit list of changes waiting on a human decision. Plain language
  // only: no operation id, no idempotency key, no wire code, no backend
  // state name (FRONTEND-BACKEND-INTEGRATION.md §3, §10, §16).
  static const needsReviewTitle = 'تغييرات تحتاج مراجعة';
  static const needsReviewIntro =
      'حفظت هذه التغييرات على جهازك، وتغيّرت البيانات نفسها من جهاز آخر قبل مزامنتها. افتح كل تغيير واختر النسخة المناسبة.';
  static const needsReviewOpen = 'مراجعة';
  static const needsReviewEmptyTitle = 'لا توجد تغييرات تحتاج مراجعة';
  static const needsReviewEmptyBody =
      'تُزامَن تغييراتك تلقائيًا. سيظهر هنا أي تغيير يحتاج قرارك.';
  // Listed, but with nothing safe to compare on this device yet. The change
  // itself is still saved and still waiting — never presented as a loss.
  static const needsReviewUnavailable =
      'تفاصيل هذا التغيير غير متاحة على هذا الجهاز';
  static const needsReviewUnavailableBody =
      'تغييرك محفوظ ولم يُفقد. أعد المزامنة عند توفر الاتصال لعرض الفروقات.';
  static const needsReviewDetectedPrefix = 'ظهر ';
  // Fallback names for the kind of record involved, so an internal grouping
  // tag never reaches the screen. See `needsReviewRecordLabel`.
  static const needsReviewRecordShift = 'تغيير على شفت';
  static const needsReviewRecordInventory = 'تغيير على المخزون';
  static const needsReviewRecordMember = 'تغيير على عضو فريق';
  static const needsReviewRecordGeneric = 'تغيير غير مزامن';

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
  static const attendanceDate = 'تاريخ الحضور';
  static const absenceDate = 'تاريخ الغياب';
  static const checkInTime = 'الدخول';
  static const checkOutTime = 'الخروج';
  static const presentTotal = 'إجمالي الحضور';
  static const absentTotal = 'إجمالي الغياب';
  static const completedTotal = 'الحضور المكتمل';
  static const memberFilter = 'تصفية حسب العضو';
  static const allMembers = 'كل الأعضاء';
  static const attendanceDetails = 'تفاصيل الحضور';
  static const attendanceSummary = 'ملخص حضور الأعضاء';
  static const pendingTotal = 'دون تسجيل حضور';
  static const reportPage = 'صفحة';
  static const reportOf = 'من';
  static const pdfReady = 'تم إنشاء ملف PDF.';
  static const pdfError = 'تعذّر إنشاء ملف PDF.';
  static const capacityUsage = 'إشغال السعة';
  static const filterMembers = 'الأعضاء';
  static const filterGuests = 'الضيوف';

  // Settings (المزيد)
  static const settingsTitle = 'المزيد';
  static const sectionAccount = 'الحساب';
  static const sectionApp = 'التطبيق';
  static const sectionOrg = 'المؤسسة';
  static const sectionSync = 'المزامنة';

  // ---------- Sync (local-first writes) ----------
  // The app saves locally first and synchronises afterwards. These strings
  // describe that to the user in plain terms — no ids, no wire codes, no
  // backend state names (see FRONTEND-BACKEND-INTEGRATION.md §3, prompt §10).
  static const syncNow = 'مزامنة الآن';
  static const syncStatusLabel = 'حالة المزامنة';
  static const syncAllSynced = 'كل التغييرات متزامنة';
  static const syncInProgress = 'جارٍ المزامنة…';
  static const syncPendingOne = 'تغيير واحد بانتظار المزامنة';
  // %d → Arabic-Indic count.
  static const syncPendingMany = '%d تغييرات بانتظار المزامنة';
  static const syncLastAtPrefix = 'آخر مزامنة ';
  static const syncNever = 'لم تتم المزامنة بعد';
  static const syncOfflineNote =
      'لا يوجد اتصال. تُحفظ تغييراتك محليًا وتُزامَن تلقائيًا عند عودة الاتصال.';
  static const syncFailedNote =
      'تعذّرت المزامنة الآن. تغييراتك محفوظة وستتم إعادة المحاولة تلقائيًا.';
  static const syncDoneNote = 'اكتملت المزامنة.';
  // Some changes went through and some did not — never reported as either a
  // clean success or a flat failure.
  static const syncPartialNote =
      'تمت مزامنة بعض التغييرات، وبقيت تغييرات أخرى بانتظار المزامنة.';
  // Shown after a local save that still has to travel.
  static const savedPendingSync = 'تم الحفظ · بانتظار المزامنة';
  // A run found at least one stale-write conflict (see conflict resolution
  // strings below) — never shown as a generic failure.
  static const syncNeedsReviewNote =
      'توجد تغييرات تحتاج مراجعة قبل إكمال المزامنة.';
  // The quiet Settings attention row for operations waiting on a human
  // conflict decision. %d → Arabic-Indic count.
  static const syncReviewOne = 'تغيير واحد يحتاج مراجعة';
  static const syncReviewMany = '%d تغييرات تحتاج مراجعة';
  // The attention row is the way in to the Needs Review list.
  static const syncReviewOpenHint = 'افتح قائمة المراجعة';

  // ---------- Sync Center (roadmap §6) ----------
  // One headline the admin can read in a second, one supporting sentence,
  // and counts in plain words. The headline strings below are deliberately
  // distinct from the count lines so the screen never says the same thing
  // twice, and none of them names a queue, a revision or a transport.
  static const syncHeadlinePending = 'توجد تغييرات بانتظار المزامنة';
  static const syncHeadlineOffline = 'لا يوجد اتصال بالإنترنت';
  static const syncHeadlineFailed = 'تعذر إكمال المزامنة';
  static const syncHeadlineNeedsReview = 'توجد تغييرات تحتاج مراجعتك';

  // The supporting sentence under the headline: what it means and what the
  // user can do about it. Distinct from the snackbar notes above on purpose —
  // a note reports one run, these describe the standing situation.
  static const syncBodyUpToDate = 'كل تغييراتك محفوظة ووصلت إلى الفريق.';
  static const syncBodyPending =
      'تُرسل تغييراتك تلقائيا، ويمكنك المزامنة الآن.';
  static const syncBodySyncing = 'يجري إرسال تغييراتك الآن.';
  static const syncBodyOffline =
      'أنت غير متصل بالإنترنت. ستتم المزامنة عند عودة الاتصال.';
  static const syncBodyFailed =
      'تعذر إكمال بعض التغييرات. يمكنك إعادة المحاولة.';
  static const syncBodyNeedsReview =
      'يوجد تعديل يحتاج مراجعتك قبل إكمال المزامنة.';

  // The connection chip. Shown only when a sync run actually proved one way
  // or the other — the app has no separate connectivity source to ask.
  static const syncConnected = 'متصل';
  static const syncDisconnected = 'غير متصل';

  static const syncLastSuccessPrefix = 'آخر مزامنة ناجحة: ';
  // Changes that were attempted and did not go through. Still saved, still
  // owed to the server. %d → Arabic-Indic count.
  static const syncFailedOne = 'تغيير واحد تعذر إرساله';
  static const syncFailedMany = '%d تغييرات تعذر إرسالها';
  static const syncNeedsInternet = 'المزامنة تحتاج اتصالا بالإنترنت.';
  // The one reassurance every sync/conflict error state has to carry.
  static const syncDataSafeNote = 'تغييراتك محفوظة على جهازك ولن تُفقد.';
  static const syncStatusLoading = 'جارٍ تحميل حالة المزامنة…';
  static const syncLoadFailedTitle = 'تعذر عرض حالة المزامنة';
  static const syncLoadFailedBody =
      'تغييراتك محفوظة على جهازك. أعد المحاولة لعرض الحالة.';
  static const settingsPalette = 'لوحة الألوان';
  static const settingsMode = 'السمة';
  static const settingsModeSystem = 'حسب النظام';
  static const appVersion = 'إصدار التطبيق';

  // ---- Settings hub (Point 1: hub + nested category screens) ----
  // The hub row/page title for quality + frame-rate. "Themes" reuses
  // settingsAppearance below; "Sync" reuses sectionSync above — the same
  // word already labels both the hub's section and its one row for
  // Organization, so this follows that existing pattern rather than adding
  // a near-duplicate string.
  static const settingsPerformanceTitle = 'الأداء والحركة';

  // ---------- Today / operations dashboard ----------
  // The landing screen answers one question: what is happening today, and
  // what needs a decision. Every line below describes a record that exists —
  // nothing here is raised speculatively (see `today_selectors.dart`).
  static const dashboardNoDetachmentTitle = 'لا مفرزة متاحة';
  static const dashboardNoDetachmentBody =
      'لا توجد مفرزة نشطة ضمن صلاحياتك. اطلب من المسؤول إضافتك إلى مفرزة '
      'لتظهر شفتات اليوم هنا.';
  static const dashboardSwitchDetachment = 'تبديل المفرزة';
  static const dashboardPickDetachment = 'اختر المفرزة';
  static const dashboardNoShiftsToday = 'لا شفتات اليوم في هذه المفرزة.';
  static const dashboardNoShiftNow = 'لا شفت يعمل الآن.';
  static const dashboardNextShift = 'الشفت التالي';
  static const dashboardNoNextShift = 'لا شفت قادم مجدول.';
  static const dashboardTomorrow = 'غدا';
  static const dashboardOpenShift = 'فتح الشفت';
  static const dashboardViewSchedule = 'عرض الجدول';
  static const dashboardQuickActions = 'إجراءات سريعة';
  static const dashboardAllClear = 'لا شيء يحتاج قرارك الآن.';
  // Attendance line on the running shift: present / assigned, with what is
  // still open beside it.
  static const dashboardPresent = 'حاضر';
  static const dashboardAwaiting = 'بلا تسجيل';
  static const dashboardAssignedOf = 'من';
  // Alerts. %d → Arabic-Indic count.
  static const alertUnderstaffedTitle = 'شفت ناقص التغطية';
  static const alertUnderstaffedBody = 'ينقصه %d متطوعين';
  static const alertUnderstaffedBodyOne = 'ينقصه متطوع واحد';
  static const alertMissingAttendanceTitle = 'حضور غير مسجّل';
  static const alertMissingAttendanceBody = '%d أعضاء بلا تسجيل حضور';
  static const alertMissingAttendanceBodyOne = 'عضو واحد بلا تسجيل حضور';
  static const alertLowStockTitle = 'نقص في المخزن';
  static const alertLowStockBody = '%d أصناف عند حدّها الأدنى أو أقل';
  static const alertLowStockBodyOne = 'صنف واحد عند حدّه الأدنى أو أقل';
  static const alertExpiringTitle = 'أصناف قرب انتهائها';
  static const alertExpiringBody = '%d أصناف تنتهي قريبا';
  static const alertExpiringBodyOne = 'صنف واحد ينتهي قريبا';
  static const alertSyncFailedTitle = 'تعذّرت المزامنة';
  static const alertOpenAction = 'فتح';
  static const alertReviewAction = 'مراجعة';

  // ---------- Members module ----------
  static const membersApply = 'تطبيق';
  static const membersClearSearch = 'مسح البحث';
  static const membersEmptySearchSub =
      'جرّب اسما آخر، أو أزل التصفية لعرض كل الأعضاء.';
  static const membersFilters = 'تصفية';
  static const membersFiltersTitle = 'تصفية الأعضاء';
  static const membersFilterRole = 'الدور';
  static const membersFilterDepartment = 'القسم';
  static const membersClearFilters = 'إزالة التصفية';
  static const membersShowingCount = 'ظاهر %d من %d';
  static const memberContactSection = 'التواصل';
  static const memberContactHidden = 'بيانات التواصل غير متاحة لصلاحيتك.';
  static const memberNoPhone = 'لا رقم مسجّل لهذا العضو.';
  static const memberPhone = 'الهاتف';
  static const memberIdentitySection = 'البيانات';
  static const memberTodaySection = 'اليوم';
  static const memberNoAssignmentToday = 'لا إسناد لهذا العضو اليوم.';
  static const memberDetachmentLabel = 'المفرزة';
  static const memberRemovedTitle = 'لم يعد هذا العضو موجودا';
  static const memberRemovedBody =
      'ربما حُذف السجل من جهاز آخر. عد إلى قائمة الأعضاء.';
  static const memberBackToRoster = 'العودة إلى الأعضاء';

  // Profile — the signed-in administrator's own account.
  //
  // Only administrative accounts sign in to MTM (one main admin and a handful
  // of others), so this copy is about an account and its grant, never about a
  // volunteer's shifts, attendance or specialty. Those belong to the Members
  // module, which manages *other* people's records.
  static const profileName = 'الاسم';
  static const profileEmail = 'البريد الإلكتروني';
  static const profileOrg = 'المؤسسة';
  static const profileNoSession = 'لا جلسة نشطة.';
  static const profileNoSessionSub = 'سجّل الدخول لعرض حسابك.';
  static const profileAccountSection = 'بيانات الحساب';
  static const profileAccessSection = 'الصلاحيات';
  static const profileSecuritySection = 'الأمان والجلسات';
  static const profileAccessLevel = 'مستوى الصلاحيات';
  static const profileAccessFull = 'صلاحيات كاملة على المؤسسة';
  static const profileAccessOrg = 'صلاحيات على مستوى المؤسسة';
  static const profileAccessScoped = 'صلاحيات ضمن مفارز محددة';
  static const profileAccessNone = 'لا صلاحيات ممنوحة';
  static const profileAccessNote =
      'تُمنح صلاحيات حسابك من مشرف الحسابات، ويطبّقها الخادم على كل طلب.';
  static const profileManagesAdmins = 'إدارة حسابات المشرفين';
  static const profileEditsOrg = 'تعديل بيانات المؤسسة';
  static const profileScope = 'نطاق الصلاحيات';
  static const profileScopeOrgWide = 'كل المؤسسة';
  // %d → Arabic-Indic count of detachments carrying a grant.
  static const profileScopeOneDetachment = 'مفرزة واحدة';
  static const profileScopeManyDetachments = '%d مفارز';
  static const profileReadOnlyNote =
      'تعديل بيانات الحساب غير متاح من التطبيق حاليا. راجع مشرف الحسابات.';
  static const profileSecurityRow = 'الجلسات والتحقق بخطوتين';
  static const profilePasswordReset = 'إعادة تعيين كلمة المرور';
  static const profilePasswordResetSub =
      'يُرسل رمز تحقق إلى بريدك، ثم تختار كلمة مرور جديدة.';
  static const profileSignOutFailed = 'تعذّر تسجيل الخروج. حاول مرة أخرى.';
  static const profileGranted = 'ممنوحة';
  static const profileNotGranted = 'غير ممنوحة';

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
  static const deleteShiftBody =
      'سيُحذف الشفت ومن أُسند إليه. لا يمكن التراجع.';
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
  static const repeatOnDays = 'كرّر الشفت في أيام محددة';
  static const repeatOnDaysHelp =
      'اختر الأيام التي يتكرر فيها هذا الشفت. تُنشأ نسخة لكل يوم، وتُدار كل واحدة على حدة. اليوم المقفل به مسندون ولا يُحذف.';
  static const daysUnit = 'أيام';
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
  static const manageShiftTitle = 'إدارة الشفت';
  static const shiftMembersSection = 'المسندون';
  static const moreMembers = 'آخرون';
  static const templatesButton = 'القوالب';
  static const templateDays = 'أيام';
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
  static const searchMembers = 'ابحث عن عضو';
  static const selectedMembers = 'الأعضاء المسندون';
  static const unselectedMembers = 'أعضاء المفرزة المتاحون';
  static const dragMembersHere = 'اضغط على العضو أو اسحبه إلى هنا';
  static const manualMemberName = 'إدخال اسم عضو يدويا';
  static const addAndAssign = 'إضافة وإسناد';
  static const duplicateMemberName =
      'يوجد عضو بهذا الاسم. اختر العضو الموجود بدلا من إنشاء سجل مكرر.';
  static const memberCreatedAndAssigned = 'تمت إضافة العضو وإسناده للشفت.';
  static const memberAssigned = 'تم إسناد العضو للشفت.';
  static const noMatchingMembers = 'لا يوجد أعضاء مطابقون للبحث.';
  static const checkInDateTime = 'تاريخ ووقت الدخول';
  static const checkOutDateTime = 'تاريخ ووقت الخروج';
  static const editCheckIn = 'تعديل الدخول';
  static const editCheckOut = 'تعديل الخروج';
  static const checkoutRequiresCheckin = 'سجّل الدخول أولا قبل تسجيل الخروج.';
  static const checkoutBeforeCheckin =
      'لا يمكن أن يكون وقت الخروج قبل وقت الدخول.';
  static const startAfterEnd = 'وقت البداية يجب أن يختلف عن وقت النهاية.';
  static const guideAddShift =
      'ابدأ باختيار فترة جاهزة — يمكنك تعديل الوقت بعدها.';

  // ---------- Attendance edit window & corrections ----------
  static const attendanceWindowExpired =
      'انتهت مهلة التعديل الاعتيادي لهذا الشفت (ساعة واحدة بعد نهايته).';
  static const attendanceWindowClosedOrdinary =
      'انتهت المهلة الاعتيادية لتعديل هذا الحضور. المعروض هنا للاطلاع فقط، '
      'ولا يمكن تعديله من هذه الشاشة بعد الآن.';
  static const addCorrection = 'إضافة تصحيح';
  static const correctionHistoryTitle = 'سجل التصحيحات';
  static const noCorrectionsYet = 'لا تصحيحات مسجّلة على هذا الحضور.';
  static const correctionReasonLabel = 'سبب التصحيح';
  static const correctionReasonPlaceholder = 'اشرح سبب هذا التصحيح — إلزامي';
  static const correctionReasonRequired = 'سبب التصحيح مطلوب.';
  static const correctionBefore = 'قبل';
  static const correctionAfter = 'بعد';
  static const correctedBy = 'صحّحه';
  static const saveCorrection = 'حفظ التصحيح';
  static const cancelCorrection = 'إلغاء';

  // ---------- Inventory lifecycle ----------
  static const newItem = 'صنف جديد';
  static const editItem = 'تعديل الصنف';
  static const itemName = 'اسم الصنف';
  static const itemNamePlaceholder = 'مثال: أدرينالين ١ ملغ/مل';
  static const itemUnit = 'الوحدة';
  static const itemUnitPlaceholder = 'مثال: أمبولة';
  static const itemOpeningStock = 'الكمية الحالية';
  static const packagingUnit = 'وحدة التعبئة';
  static const packagingIndividual = 'وحدة فردية';
  static const packagingStrip = 'شريط';
  static const packagingCarton = 'كرتونة';
  static const individualUnitsCount = 'عدد الوحدات الفردية';
  static const stripsCount = 'عدد الشرائط';
  static const cartonsCount = 'عدد الكراتين';
  static const unitsPerStrip = 'الوحدات الفردية في كل شريط';
  static const stripsPerCarton = 'الشرائط في كل كرتونة';
  static const baseUnits = 'وحدة فردية';
  static const availableBreakdown = 'المتاح';
  static const convertedQuantity = 'ما يعادل بالوحدات الفردية';
  static const cartonsLabel = 'كرتونة';
  static const stripsLabel = 'شريط';
  static const individualUnitsLabel = 'وحدة فردية';
  static const stockBeforeAfter = 'الرصيد قبل/بعد';
  static const recordedBy = 'سجّلها';
  static const packagingMetadataRequired =
      'حدّد عدد الوحدات في الشريط وعدد الشرائط في الكرتونة قبل اختيار هذه التعبئة.';
  static const positiveIntegerRequired = 'أدخل عددا صحيحا أكبر من صفر.';
  static const insufficientStock = 'الكمية المطلوبة أكبر من المخزون المتاح.';
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
  static const secAttendance = 'الحضور';
  static const secAttendanceSub =
      'الإجماليات، وسجل أيام كل عضو، ونسبة الحضور اليومية خلال المدى المختار.';
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

  // ---------- Detachment status strip ----------
  // Shown under the detail-shell app bar, on every tab. The lifecycle line
  // is copied from the legacy details header (نشط / غير نشط); the storage
  // line is new — a rollup of the stock the detachment holds.
  static const detachmentStatusStrip = 'حالة المفرزة';
  static const storageStatusHealthy = 'المخزن مكتمل';
  static const storageStatusLow = 'نقص في المخزن';
  static const storageStatusExpiring = 'أصناف قرب انتهائها';
  static const storageStatusDepleted = 'أصناف نفدت';
  static const storageStatusEmpty = 'لا مخزن';

  // ---------- Member status page ----------
  static const memberStatusTitle = 'حالة العضو';
  static const memberStatusCurrent = 'الحالة الآن';
  static const memberAttendanceLog = 'سجل الحضور';
  static const memberAttendanceLogSub =
      'كل يوم أُسند إليه فيه شفت، ووقت الدخول والخروج.';
  static const noAttendanceRecords = 'لا سجل حضور بعد';
  static const noAttendanceRecordsSub =
      'لم يُسنَد هذا العضو إلى أي شفت خلال هذه المدة.';
  static const notCheckedInShort = 'بلا تسجيل دخول';

  // ---------- Notifications Center ----------
  // The operational feed at `/notifications`. Distinct from
  // `settingsNotifications` ("التنبيهات"), which is the push-preference
  // screen at `/more/notifications` — one is what happened, the other is what
  // the device is allowed to interrupt you for.
  static const notificationsTitle = 'الإشعارات';
  static const notificationsOpen = 'فتح الإشعارات';
  static const notificationsUnreadOne = 'إشعار واحد غير مقروء';
  static const notificationsUnreadMany = '%d إشعارات غير مقروءة';
  static const notificationsNoneUnread = 'لا إشعارات غير مقروءة';
  static const notificationsEmptyTitle = 'لا إشعارات';
  static const notificationsEmptyBody =
      'كل شيء على ما يرام. سيظهر هنا ما يحتاج انتباهك في مفرزتك.';
  static const notificationsMarkAllRead = 'تعليم الكل كمقروء';
  static const notificationsMarkAllReadDone = 'تم تعليم الإشعارات كمقروءة';
  static const notificationsMarkReadFailed = 'تعذّر حفظ حالة القراءة.';
  static const notificationsTargetGone = 'لم يعد هذا السجل متاحا.';
  static const notificationsUnreadDot = 'غير مقروء';
  static const notificationsGroupUpcoming = 'قادم';
  static const notificationsGroupToday = 'اليوم';
  static const notificationsGroupYesterday = 'أمس';
  static const notificationsGroupEarlier = 'أقدم';

  // One title and one short line per supported kind. Every kind here is
  // derived from a real record — nothing is worded for a condition the app
  // cannot actually observe.
  static const notifShiftUnderstaffedTitle = 'شفت ناقص التغطية';
  static const notifShiftUnderstaffedBody = 'ينقص %d متطوعا';
  static const notifShiftAttendanceTitle = 'حضور غير مسجّل';
  static const notifShiftAttendanceBody = 'بقي %d بلا تسجيل';
  static const notifShiftSoonTitle = 'شفت يبدأ قريبا';
  static const notifShiftSoonBody = 'يبدأ %s';
  static const notifStockDepletedTitle = 'صنف نفد من المخزن';
  static const notifStockDepletedBody = 'لا يوجد رصيد';
  static const notifStockLowTitle = 'صنف تحت الحد الأدنى';
  static const notifStockLowBody = 'بقي %d';
  static const notifStockExpiringTitle = 'صنف قرب انتهاء صلاحيته';
  static const notifStockExpiringBody = 'ينتهي %s';
  static const notifSyncConflictTitle = 'تغيير يحتاج مراجعة';
  static const notifSyncConflictBody = 'تعديلك يتعارض مع النسخة الحالية';
  static const notifSyncFailedTitle = 'تعذّرت مزامنة تغيير';
  static const notifSyncFailedBody = 'ما زال محفوظا على جهازك';

  // ---------- Beginner guidance ----------
  static const stepOne = 'الخطوة ١';
  static const stepTwo = 'الخطوة ٢';
  static const stepThree = 'الخطوة ٣';
  static const gotIt = 'فهمت';
}
