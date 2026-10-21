// ========================================================
// University Internship Management System (UIMS)
// Bilingual Internationalization Engine (Arabic <-> English)
// The University of Jordan - KASIT
// ========================================================

const translations = {
    ar: {
        // Institutional & Top Bar
        "univ_name": "الجامعة الأردنية",
        "univ_location": "الجامعة الأردنية - عمّان",
        "college_name": "كلية الملك عبدالله الثاني لتكنولوجيا المعلومات (KASIT)",
        "college_full": "كلية الملك عبدالله الثاني لتكنولوجيا المعلومات - الجامعة الأردنية",
        "system_title": "نظام إدارة التدريب الميداني (UIMS)",
        "system_full_title": "نظام إدارة التدريب الميداني الجامعي (UIMS)",
        "training_office": "مكتب التدريب الميداني - KASIT",
        "all_rights_reserved": "جميع الحقوق محفوظة © " + new Date().getFullYear() + " - الجامعة الأردنية (University of Jordan - KASIT).",
        "switch_lang": "English",
        "current_lang_label": "العربية",

        // Navigation
        "nav_home": "الرئيسية",
        "nav_about": "عن النظام والكلية",
        "nav_contact": "تواصل معنا",
        "nav_login": "تسجيل الدخول",
        "nav_dashboard": "لوحة التحكم",
        "nav_logout": "تسجيل الخروج",
        "nav_public_site": "الموقع العام",
        "nav_menu_header": "قائمة التنقل",

        // Hero & Home
        "hero_badge": "كلية الملك عبدالله الثاني لتكنولوجيا المعلومات (KASIT)",
        "hero_title": "نظام إدارة التدريب الميداني الجامعي",
        "hero_desc": "المنصة الإلكترونية الرسمية الموحدة لربط طلبة كلية تكنولوجيا المعلومات بالجامعة الأردنية مع كبرى شركات الاتصالات والبرمجيات، لمتابعة فرص التدريب، تقييم المهام، وتوثيق الساعات التدريبية (280 ساعة).",
        "btn_enter_system": "الدخول إلى النظام",
        "btn_explore_opps": "استعراض فرص التدريب",
        "pathway_title": "مسار التدريب الميداني 2026",
        "pathway_subtitle": "جامعة كل الأردنيين | نحو تأهيل مهني وتقني متقدم",
        "stat_hours_label": "ساعة تدريبية",
        "stat_company_weight": "تقييم الشركة",
        "stat_academic_weight": "أكاديمي ومهام",
        "supported_majors_title": "التخصصات المعتمدة بكلية KASIT:",
        "major_cs": "علم الحاسوب (CS)",
        "major_cis": "أنظمة المعلومات الحاسوبية (CIS)",
        "major_bit": "تكنولوجيا معلومات الأعمال (BIT)",
        "major_ai": "الذكاء الاصطناعي (AI)",
        "major_cys": "الأمن السيبراني (CYS)",

        // Workflow Steps
        "workflow_badge": "إجراءات التدريب الميداني",
        "workflow_title": "كيف تسير رحلة التدريب الميداني في KASIT؟",
        "workflow_subtitle": "مراحل واضحة تنظم العلاقة بين الطالب، والشركة، والمشرف الأكاديمي، ومنسق الكلية",
        "step1_title": "تسجيل الطالب والمجموعة",
        "step1_desc": "يقوم منسق التدريب بالكلية بإنشاء الحساب، وتحديد متطلبات الساعات (280 ساعة)، وربط الطالب بمشرف أكاديمي منذ البداية.",
        "step2_title": "التقديم وتأكيد العرض",
        "step2_desc": "يستعرض الطالب الفرص المناسبة لتخصصه ويتقدم إليها. عند القبول، يؤكد عرضاً واحداً فقط وفقاً لقواعد الكلية.",
        "step3_title": "تنفيذ المهام وتوثيق الساعات",
        "step3_desc": "يسند مشرف الشركة المهام، ويسلم الطالب أعماله، وتعتمد ساعات التدريب تدريجياً عبر آلية الموافقة المعتمدة.",
        "step4_title": "التقييمين (شركة + أكاديمي)",
        "step4_desc": "يقدم مشرف الشركة تقييمه (40%)، ثم يعد المشرف الأكاديمي تقييمه النهائي (30%) ويرسله لمنسق الكلية.",
        "step5_title": "الاعتماد وإصدار الشهادة",
        "step5_desc": "يراجع منسق التدريب بالكلية كافة النتائج، ويعتمد إتمام التدريب، ويصدر للطالب شهادة التخرج الرسمية بصيغة PDF.",

        // Video Section
        "video_badge": "دليل مرئي مفصل",
        "video_title": "فيديو تعريفي بإجراءات التدريب الميداني في الجامعة الأردنية",
        "video_desc": "شاهد العرض التوضيحي الشامل لآلية التدريب الميداني لكلية الملك عبدالله الثاني لتكنولوجيا المعلومات، بدءاً من التسجيل، مروراً بمتابعة ساعات التدريب في الشركات، وانتهاءً بحساب العلامة النهائية واعتماد المنسق.",
        "video_point1": "شرح تسجيل الدخول وتغيير كلمة المرور المؤقتة.",
        "video_point2": "ضوابط تأكيد فرصة تدريبية واحدة فقط لكل طالب.",
        "video_point3": "توزيع الأوزان: 40% شركة، 30% أكاديمي، 30% مهام وتقارير.",
        "video_point4": "استخراج شهادة إتمام التدريب الرسمية المعتمدة (PDF).",
        "video_note": "تم إعداد هذا المقطع الإرشادي للطلبة والمشرفين والشركات الشريكة للجامعة الأردنية.",

        // Opportunities Preview
        "opps_badge": "فرص التدريب المتاحة حالياً",
        "opps_title": "معاينة أحدث الفرص التدريبية في KASIT",
        "opps_subtitle": "يمكن للزوار استعراض الملخص، بينما يتطلب الاطلاع على التفاصيل الكاملة والتقديم تسجيل الدخول.",
        "btn_login_to_apply": "تسجيل الدخول للتقديم",
        "btn_view_summary": "عرض الملخص",
        "seats_label": "المقاعد:",
        "modal_title": "ملخص فرصة التدريب",
        "modal_desc": "بحسب تعليمات كلية الملك عبدالله الثاني لتكنولوجيا المعلومات، يُشترط تسجيل الدخول للوصول إلى تفاصيل المتطلبات الكاملة ونموذج التقدم المباشر.",
        "modal_rule": "يُسمح للطلبة المسجلين في مساق التدريب الميداني بالتقديم وتأكيد عرض واحد فقط.",
        "modal_close": "إغلاق",

        // Login Page
        "login_portal_title": "بوابة الدخول الموحدة",
        "login_email_label": "البريد الإلكتروني",
        "login_password_label": "كلمة المرور",
        "login_forgot_password": "نسيت كلمة المرور؟",
        "login_btn": "تسجيل الدخول",
        "login_demo_title": "حسابات تجريبية سريعة للعرض:",
        "login_demo_hint": "انقر للتعبئة الفورية",
        "demo_student": "طالب (أحمد)",
        "demo_new_student": "طالب جديد (تغيير كلمة المرور)",
        "demo_company": "مشرف شركة (أمنية)",
        "demo_academic": "مشرف أكاديمي",
        "demo_coordinator": "منسق الكلية",
        "forgot_title": "استعادة كلمة المرور",
        "forgot_desc": "أدخل بريدك الإلكتروني الجامعي المسجل لتلقي رابط إعادة تعيين كلمة المرور مباشرة عبر Firebase.",
        "forgot_btn_send": "إرسال الرابط عبر البريد",

        // Contact Page
        "contact_title": "تواصل مع مكتب التدريب الميداني",
        "contact_subtitle": "نحن هنا للإجابة على استفسارات الطلبة والشركات والمشرفين",
        "contact_form_title": "أرسل لنا رسالة",
        "contact_form_subtitle": "يتم حفظ الرسالة مباشرة في قاعدة بيانات Firebase وإشعار منسق الكلية.",
        "contact_name": "الاسم الكامل",
        "contact_email": "البريد الإلكتروني",
        "contact_subject": "موضوع الرسالة",
        "contact_message": "نص الرسالة والاستفسار",
        "contact_submit_btn": "إرسال الرسالة إلى Firebase",
        "contact_hq_title": "مقر كلية KASIT - الجامعة الأردنية",
        "contact_address_label": "العنوان:",
        "contact_address_val": "شارع الملكة رانيا العبدالله، عمّان 11942، الأردن.<br />الحرم الجامعي - مجمع الكليات العلمية - كلية الملك عبدالله الثاني لتكنولوجيا المعلومات.",
        "contact_email_label": "البريد الإلكتروني للتدريب:",
        "contact_phone_label": "الهاتف والمقاسم:",
        "contact_phone_val": "+962 6 5355000 (فرعي: 22500، 22505)",
        "contact_hours_label": "ساعات الاستقبال الرسمي:",
        "contact_hours_val": "الأحد إلى الخميس، من الساعة 8:30 صباحاً حتى 3:30 بعد الظهر.",
        "contact_privacy_title": "خصوصية البيانات",
        "contact_privacy_val": "كافة الرسائل والاستفسارات تحفظ بشكل آمن في قاعدة بيانات Firebase ولا يطلع عليها سوى منسق التدريب الميداني المعتمد في الكلية.",

        // About Page
        "about_header_badge": "الجامعة الأردنية",
        "about_header_title": "عن نظام التدريب الميداني والكلية",
        "about_header_subtitle": "كلية الملك عبدالله الثاني لتكنولوجيا المعلومات (KASIT)",
        "about_kasit_title": "الجامعة الأردنية وكلية KASIT",
        "about_kasit_p1": "تعد <strong>الجامعة الأردنية</strong> (التي تأسست عام 1962) أم الجامعات الأردنية والمنارة الأكاديمية الأولى في المملكة. وقد أُنشئت <strong>كلية الملك عبدالله الثاني لتكنولوجيا المعلومات (KASIT)</strong> بتوجيهات ملكية سامية عام 2000 لتكون مركز تميز إقليمي في تعليم وبحوث علوم الحاسوب، أنظمة المعلومات، تكنولوجيا معلومات الأعمال، الذكاء الاصطناعي، والأمن السيبراني.",
        "about_kasit_p2": "يهدف مساق <strong>التدريب الميداني (Field Training)</strong> إلى تمكين الطلبة من تطبيق المعارف النظرية والمهارات البرمجية في بيئة عمل حقيقية داخل كبرى شركات قطاع الاتصالات وتكنولوجيا المعلومات (ICT)، مما يرفع جاهزيتهم لسوق العمل المحلي والإقليمي.",
        "about_regulations_title": "متطلبات وضوابط التدريب الميداني",
        "about_reg_hours_title": "المدة والساعات المطلوبة",
        "about_reg_hours_desc": "يُشترط على الطالب إتمام ما لا يقل عن <strong>280 ساعة تدريبية معتمدة</strong> (ما يعادل 8 أسابيع بدوام كامل أو ما يوازيها وفق خطة الكلية).",
        "about_reg_req_title": "شروط التسجيل",
        "about_reg_req_desc": "أن يكون الطالب قد اجتاز ما لا يقل عن <strong>90 ساعة معتمدة</strong> بنجاح وفق خطته الدراسية المعتمدة في KASIT.",
        "about_grading_title": "توزيع العلامات وطريقة التقييم المعتمدة",
        "about_grading_desc": "وفقاً لتعليمات مجلس كلية الملك عبدالله الثاني لتكنولوجيا المعلومات، يتم احتساب النتيجة النهائية للتدريب الميداني بناءً على أوزان محددة لضمان العدالة والتقييم الشامل:",
        "table_th_axis": "المحور التقييمي",
        "table_th_weight": "الوزن النسبي",
        "table_th_criteria": "الجهة المسؤولة والمعايير",
        "grade_company_label": "تقييم مشرف جهة التدريب (الشركة)",
        "about_eval_company_desc": "الالتزام بالدوام، الاحترافية، مهارات العمل الجماعي، الإنجاز التقني للمهام الموكلة.",
        "grade_academic_label": "تقييم المشرف الأكاديمي والتقارير",
        "about_eval_academic_desc": "المتابعة الأكاديمية الدورية، جودة التقارير المرحلية، الملاحظات الإرشادية.",
        "grade_tasks_label": "إنجاز المهام والتقرير النهائي",
        "about_eval_tasks_desc": "تسليم المهام والمشاريع الموكلة وفق المواعيد، التقرير الختامي للتدريب ومخرجات التعلم.",
        "grade_total_label": "المجموع الكلي وشرط النجاح",
        "about_eval_total_desc": "علامة النجاح الدنيا هي <strong>60%</strong> مع اشتراط إتمام الساعات كاملة واعتماد المنسق.",
        "about_goals_title": "أهداف المنصة (UIMS)",
        "about_goal1": "<div><strong>أتمتة شاملة:</strong> إلغاء المعاملات الورقية وتوحيد التقارير في سجل سحابي رقمي.</div>",
        "about_goal2": "<div><strong>ضمان الشفافية:</strong> اطلاع الطالب على تقييمات مهامه وملاحظات مشرفيه لحظياً.</div>",
        "about_goal3": "<div><strong>منع الازدواجية:</strong> إلزام الطالب بتأكيد عرض تدريب واحد فقط لإتاحة الفرص للجميع.</div>",
        "about_goal4": "<div><strong>شهادة معتمدة:</strong> إصدار تقرير رسمي مختوم بإتمام التدريب الميداني بصيغة PDF.</div>",
        "about_training_office": "مكتب التدريب الميداني",
        "about_deanship": "عمادة كلية الملك عبدالله الثاني لتكنولوجيا المعلومات",
        "about_contact_btn": "تواصل مع مكتب التدريب",

        // Footer
        "footer_univ_title": "الجامعة الأردنية",
        "footer_college_sub": "كلية الملك عبدالله الثاني لتكنولوجيا المعلومات (KASIT)",
        "footer_desc": "نظام إلكتروني متكامل يربط الكلية بطلبتها والمؤسسات والشركات الشريكة، لإدارة فرص التدريب الميداني، ومتابعة المهام والساعات التدريبية، واعتماد إتمام التدريب وفق معايير الجامعة الأردنية.",
        "footer_quick_links": "روابط سريعة",
        "footer_link_home": "الصفحة الرئيسية",
        "footer_link_about": "تعليمات وأهداف التدريب الميداني",
        "footer_link_contact": "التواصل مع مكتب التدريب الميداني",
        "footer_link_login": "بوابة تسجيل الدخول الموحدة",
        "footer_contact_office": "مكتب التدريب الميداني - KASIT",
        "footer_contact_bldg": "مبنى كلية الملك عبدالله الثاني لتكنولوجيا المعلومات، الطابق الأول",
        "footer_contact_hours": "الأحد - الخميس: 8:30 صباحاً - 3:30 مساءً",
        "footer_project_sub": "مشروع نظام إدارة التدريب الميداني الجامعي (UIMS)",

        // Dashboard Roles & Sidebar
        "role_student": "طالب متدرب",
        "role_company": "مشرف جهة التدريب (الشركة)",
        "role_academic": "مشرف أكاديمي",
        "role_coordinator": "منسق التدريب بالكلية",

        // Sidebar Links
        "side_dash": "لوحة التحكم",
        "side_profile": "الملف الأكاديمي والشخصي",
        "side_opps": "استكشاف فرص التدريب",
        "side_my_apps": "طلبات التقديم",
        "side_my_tasks": "المهام والتسليمات",
        "side_progress": "التقدم وساعات التدريب والتقرير",
        "side_manage_opps": "إدارة فرص التدريب",
        "side_review_apps": "مراجعة طلبات الطلبة",
        "side_my_trainees": "قائمة المتدربين المقبولين",
        "side_manage_tasks": "إدارة وتقييم المهام",
        "side_hours": "اعتماد ساعات التدريب",
        "side_final_eval": "التقييم النهائي للشركة",
        "side_company_acc": "بيانات حساب الشركة",
        "side_student_monitor": "متابعة تقدم الطلبة",
        "side_academic_eval": "التقييم الأكاديمي النهائي",
        "side_academic_acc": "حساب المشرف الأكاديمي",
        "side_coord_dash": "لوحة التحكم الإحصائية",
        "side_manage_students": "إدارة حسابات الطلبة",
        "side_manage_companies": "إدارة الشركات الشريكة",
        "side_manage_supervisors": "إدارة المشرفين الأكاديميين",
        "side_assign_supervisors": "توزيع وتعيين المجموعات",
        "side_monitor_placements": "متابعة التدريب الشاملة",
        "side_final_review": "مراجعة واعتماد التدريب النهائي",
        "side_contact_msgs": "رسائل تواصل معنا",
        "side_grading_weights": "إعدادات أوزان التقييم",

        // Company Portal & Dashboard
        "comp_portal_badge": "بوابة الشركاء والمشرفين الميدانيين",
        "comp_dash_title": "لوحة تحكم جهة التدريب",
        "comp_supervisor_lbl": "المشرف المسؤول:",
        "comp_partner_faculty": "الكلية الشريكة:",
        "comp_btn_add_opp": "إضافة فرصة تدريب",
        "comp_btn_review_apps": "مراجعة الطلبات",
        "comp_stat_active_opps": "فرص التدريب النشطة",
        "comp_stat_pending_apps": "طلبات بانتظار المراجعة",
        "comp_stat_trainees": "المتدربون الفعليون",
        "comp_stat_pending_tasks": "تسليمات مهام تنتظر التقييم",
        "comp_trainees_header": "متدربو KASIT المقيدون حالياً",
        "btn_view_all": "عرض الكل",
        "th_trainee_name": "اسم المتدرب",
        "th_major": "التخصص",
        "th_approved_hours": "الساعات المعتمدة",
        "th_action": "الإجراء",
        "abbr_hours": "س",
        "comp_tools_title": "أدوات إدارة التدريب الميداني",
        "comp_tool_tasks_title": "تعيين وتقييم المهام",
        "comp_tool_tasks_desc": "إسناد تكاليف للمتدربين وتقييم الأعمال المنجزة",
        "comp_tool_hours_title": "اعتماد ساعات التدريب",
        "comp_tool_hours_desc": "تدقيق واعتماد سجلات الحضور والساعات الأسبوعية",
        "comp_tool_eval_title": "التقييم النهائي للمتدرب (40%)",
        "comp_tool_eval_desc": "إعداد نموذج التقييم وإرساله للمشرف الأكاديمي",

        // Company Subpages
        "comp_opps_title": "إدارة فرص التدريب الميداني",
        "comp_opps_desc": "نشر فرص وتخصصات جديدة، وتحديد أعداد المقاعد المتاحة، وإغلاق أو تعديل الفرص الحالية.",
        "comp_btn_add_new_opp": "إضافة فرصة تدريب جديدة",
        "comp_review_title": "مراجعة طلبات التقديم لفرص التدريب",
        "comp_review_desc": "دراسة السير الذاتية لطلبة كلية KASIT واتخاذ قرار القبول أو الرفض مع بيان الأسباب.",
        "comp_trainees_title": "المتدربون المقبولون (طلبة KASIT)",
        "comp_trainees_desc": "متابعة إنجاز وساعات وتكليفات الطلبة الذين اختاروا وثبتوا تدريبهم في شركتكم.",
        "comp_btn_manage_tasks": "إدارة وتعيين المهام",
        "comp_btn_training_hours": "اعتماد الساعات",
        "comp_tasks_title": "إدارة وتقييم مهام المتدربين",
        "comp_tasks_desc": "إسناد مهام محددة بمعايير واضحة، ومتابعة تسليمات الطلبة وتقييمها.",
        "comp_btn_create_task": "إسناد مهمة جديدة",
        "comp_hours_title": "اعتماد ساعات التدريب الميداني",
        "comp_hours_desc": "تدقيق السجلات الأسبوعية وتأكيد إتمام الساعات التدريبية الفعلية (280 ساعة).",
        "comp_eval_title": "التقييم النهائي للشركة (40%)",
        "comp_eval_desc": "تقييم أداء المتدربين النهائي واعتماد مصفوفة الـ 40% وإرسالها للمشرف الأكاديمي ومنسق الكلية.",
        "comp_acc_title": "بيانات حساب الشركة المشرفة",
        "comp_acc_desc": "معلومات الشركة، موقع المقر، وبيانات التواصل الرسمية.",

        // Shared Table Headers & Badges
        "th_applied_opp": "الفرصة المتقدم إليها",
        "th_applied_date": "تاريخ التقديم",
        "th_resume": "السيرة الذاتية ورسالة التقديم",
        "th_decision": "القرار",
        "th_status": "الحالة",
        "btn_review_cv": "مراجعة السيرة",
        "btn_accept": "قبول",
        "btn_reject": "رفض",
        "lbl_student_id": "الرقم الجامعي:",
        "lbl_email": "البريد:",
        "lbl_phone": "الهاتف:",
        "lbl_academic_supervisor": "المشرف الأكاديمي:",
        "lbl_approved_hours": "الساعات المعتمدة:",
        "badge_approved": "معتمد ومكتمل",
        "badge_pending_eval": "بانتظار التقييم",
        "badge_revision": "يتطلب تعديلاً",
        "badge_in_progress": "قيد التنفيذ",
        "badge_accepted": "مقبول من الشركة",
        "badge_confirmed": "معتمد ومثبت كجهة تدريب",
        "badge_rejected": "مرفوض",
        "badge_pending_review": "بانتظار المراجعة"
    },
    en: {
        // Institutional & Top Bar
        "univ_name": "The University of Jordan",
        "univ_location": "The University of Jordan - Amman",
        "college_name": "King Abdullah II School of Information Technology (KASIT)",
        "college_full": "King Abdullah II School of Information Technology - The University of Jordan",
        "system_title": "Field Training System (UIMS)",
        "system_full_title": "University Internship Management System (UIMS)",
        "training_office": "Field Training Office - KASIT",
        "all_rights_reserved": "All Rights Reserved © " + new Date().getFullYear() + " - The University of Jordan (KASIT).",
        "switch_lang": "العربية",
        "current_lang_label": "English",

        // Navigation
        "nav_home": "Home",
        "nav_about": "About KASIT & UIMS",
        "nav_contact": "Contact Us",
        "nav_login": "Login",
        "nav_dashboard": "Dashboard",
        "nav_logout": "Logout",
        "nav_public_site": "Public Portal",
        "nav_menu_header": "Navigation Menu",

        // Hero & Home
        "hero_badge": "King Abdullah II School of Information Technology (KASIT)",
        "hero_title": "University Internship Management System",
        "hero_desc": "The official unified platform connecting IT students at The University of Jordan with top telecom and software companies to manage opportunities, evaluate tasks, and track required training hours (280 Hours).",
        "btn_enter_system": "Access System",
        "btn_explore_opps": "Explore Opportunities",
        "pathway_title": "Field Training Pathway 2026",
        "pathway_subtitle": "The Mother University | Towards Advanced Professional Excellence",
        "stat_hours_label": "Training Hours",
        "stat_company_weight": "Company Eval",
        "stat_academic_weight": "Academic & Tasks",
        "supported_majors_title": "Approved KASIT Majors:",
        "major_cs": "Computer Science (CS)",
        "major_cis": "Computer Information Systems (CIS)",
        "major_bit": "Business IT (BIT)",
        "major_ai": "Artificial Intelligence (AI)",
        "major_cys": "Cybersecurity (CYS)",

        // Workflow Steps
        "workflow_badge": "Internship Procedures",
        "workflow_title": "How does Field Training work at KASIT?",
        "workflow_subtitle": "A transparent lifecycle connecting Students, Companies, Academic Supervisors, and the Coordinator",
        "step1_title": "Enrollment & Group Setup",
        "step1_desc": "The Coordinator sets up student accounts, establishes the 280-hour requirement, and assigns an Academic Supervisor from day one.",
        "step2_title": "Application & Offer Confirmation",
        "step2_desc": "Students browse matching opportunities and apply. Once accepted, they can confirm only one offer per college regulations.",
        "step3_title": "Task Delivery & Hours Logging",
        "step3_desc": "The Company Supervisor assigns tasks and verifies submissions. Training hours are credited via an approval process.",
        "step4_title": "Dual Evaluations (40% + 30%)",
        "step4_desc": "Company supervisor submits final evaluation (40%), followed by the academic supervisor's evaluation (30%).",
        "step5_title": "Approval & Official Certification",
        "step5_desc": "The Coordinator reviews requirements and grades, approves completion, and issues the official completion report (PDF).",

        // Video Section
        "video_badge": "Comprehensive Video Guide",
        "video_title": "Official Walkthrough of the KASIT Field Training Process",
        "video_desc": "Watch the detailed presentation on the University of Jordan field training regulations, tracking hours, submitting deliverables, and receiving final coordinator approval.",
        "video_point1": "Login guide and changing temporary passwords.",
        "video_point2": "Rules for confirming a single internship offer per student.",
        "video_point3": "Grade weights: 40% Company, 30% Academic, 30% Tasks & Reports.",
        "video_point4": "Issuing the accredited completion certificate (PDF).",
        "video_note": "Prepared for students, supervisors, and corporate partner organizations of The University of Jordan.",

        // Opportunities Preview
        "opps_badge": "Current Open Opportunities",
        "opps_title": "Preview Latest Internship Openings at KASIT",
        "opps_subtitle": "Visitors can view opportunity summaries. Full requirements and application submissions require logging in.",
        "btn_login_to_apply": "Login to Apply",
        "btn_view_summary": "View Summary",
        "seats_label": "Available Seats:",
        "modal_title": "Internship Opportunity Summary",
        "modal_desc": "According to KASIT faculty regulations, students must log in to view full requirements and submit applications.",
        "modal_rule": "Registered internship students are permitted to confirm only one offer.",
        "modal_close": "Close",

        // Login Page
        "login_portal_title": "Unified Login Portal",
        "login_email_label": "University Email Address",
        "login_password_label": "Password",
        "login_forgot_password": "Forgot Password?",
        "login_btn": "Sign In",
        "login_demo_title": "Quick Demo Accounts for Evaluation:",
        "login_demo_hint": "Click to Autofill",
        "demo_student": "Student (Ahmad)",
        "demo_new_student": "New Student (Change Pwd)",
        "demo_company": "Company (Umniah)",
        "demo_academic": "Academic Supervisor",
        "demo_coordinator": "Faculty Coordinator",
        "forgot_title": "Password Recovery",
        "forgot_desc": "Enter your registered university email to receive a password reset link via Firebase.",
        "forgot_btn_send": "Send Reset Link",

        // Contact Page
        "contact_title": "Contact Field Training Office",
        "contact_subtitle": "We are here to assist students, companies, and supervisors",
        "contact_form_title": "Send Us a Message",
        "contact_form_subtitle": "Messages are saved directly into Firebase Cloud Firestore for coordinator review.",
        "contact_name": "Full Name",
        "contact_email": "Email Address",
        "contact_subject": "Message Subject",
        "contact_message": "Message Content",
        "contact_submit_btn": "Submit Message to Firebase",
        "contact_hq_title": "KASIT School - The University of Jordan",
        "contact_address_label": "Address:",
        "contact_address_val": "Queen Rania Al-Abdullah Street, Amman 11942, Jordan.<br />University Campus - Scientific Faculties Complex - KASIT School.",
        "contact_email_label": "Training Email:",
        "contact_phone_label": "Phone & Switchboard:",
        "contact_phone_val": "+962 6 5355000 (Ext: 22500, 22505)",
        "contact_hours_label": "Official Office Hours:",
        "contact_hours_val": "Sunday to Thursday, 8:30 AM to 3:30 PM.",
        "contact_privacy_title": "Data Privacy",
        "contact_privacy_val": "All messages are securely stored in the Firebase database and accessible solely by the authorized faculty internship coordinator.",

        // About Page
        "about_header_badge": "The University of Jordan",
        "about_header_title": "About Field Training & KASIT School",
        "about_header_subtitle": "King Abdullah II School of Information Technology (KASIT)",
        "about_kasit_title": "The University of Jordan & KASIT",
        "about_kasit_p1": "<strong>The University of Jordan</strong> (established in 1962) is the premier academic beacon in the Kingdom. The <strong>King Abdullah II School of Information Technology (KASIT)</strong> was established in 2000 by Royal Decree to be a regional center of excellence in computer science, information systems, business IT, artificial intelligence, and cybersecurity education and research.",
        "about_kasit_p2": "The <strong>Field Training</strong> course aims to empower students to apply theoretical knowledge and programming skills in real-world corporate environments within major ICT companies, boosting their readiness for local and regional job markets.",
        "about_regulations_title": "Field Training Regulations & Hours",
        "about_reg_hours_title": "Duration & Required Hours",
        "about_reg_hours_desc": "Students are required to complete at least <strong>280 accredited training hours</strong> (equivalent to 8 weeks full-time or per faculty curriculum).",
        "about_reg_req_title": "Prerequisites & Registration Terms",
        "about_reg_req_desc": "Students must have successfully completed at least <strong>90 credit hours</strong> per their approved KASIT degree plan.",
        "about_grading_title": "Approved Evaluation & Grade Distribution",
        "about_grading_desc": "Per KASIT Council regulations, the final field training outcome is calculated based on defined weights to ensure fairness and thorough assessment:",
        "table_th_axis": "Evaluation Axis",
        "table_th_weight": "Weight",
        "table_th_criteria": "Responsible Entity & Criteria",
        "grade_company_label": "Company Supervisor Evaluation",
        "about_eval_company_desc": "Attendance commitment, professionalism, teamwork skills, and technical completion of assigned tasks.",
        "grade_academic_label": "Academic Supervisor & Progress Reports",
        "about_eval_academic_desc": "Periodic academic supervision, quality of interim reports, and advisory feedback.",
        "grade_tasks_label": "Task Deliverables & Final Report",
        "about_eval_tasks_desc": "On-time delivery of assigned tasks and projects, final internship report, and learning outcomes.",
        "grade_total_label": "Total Score & Passing Condition",
        "about_eval_total_desc": "The minimum passing grade is <strong>60%</strong>, with mandatory completion of 280 hours and coordinator sign-off.",
        "about_goals_title": "UIMS Platform Objectives",
        "about_goal1": "<div><strong>Full Automation:</strong> Eliminating paper-based workflows and consolidating records in a cloud ledger.</div>",
        "about_goal2": "<div><strong>Transparency Guarantee:</strong> Real-time visibility for students into task evaluations and supervisor feedback.</div>",
        "about_goal3": "<div><strong>Preventing Redundancy:</strong> Enforcing a single confirmed offer per student to ensure fair opportunity access.</div>",
        "about_goal4": "<div><strong>Certified Credential:</strong> Issuing an official stamped certificate of internship completion in PDF format.</div>",
        "about_training_office": "Field Training Office",
        "about_deanship": "Deanship of King Abdullah II School of IT",
        "about_contact_btn": "Contact Training Office",

        // Footer
        "footer_univ_title": "The University of Jordan",
        "footer_college_sub": "King Abdullah II School of Information Technology (KASIT)",
        "footer_desc": "An integrated electronic system connecting KASIT with students and partner enterprises to manage internship opportunities, track tasks and hours, and certify field training completion per University of Jordan standards.",
        "footer_quick_links": "Quick Links",
        "footer_link_home": "Home",
        "footer_link_about": "Internship Guidelines & Objectives",
        "footer_link_contact": "Contact Field Training Office",
        "footer_link_login": "Unified Login Portal",
        "footer_contact_office": "Field Training Office - KASIT",
        "footer_contact_bldg": "King Abdullah II School of IT Building, 1st Floor",
        "footer_contact_hours": "Sunday - Thursday: 8:30 AM - 3:30 PM",
        "footer_project_sub": "University Internship Management System (UIMS) Project",

        // Dashboard Roles & Sidebar
        "role_student": "Trainee Student",
        "role_company": "Company Supervisor",
        "role_academic": "Academic Supervisor",
        "role_coordinator": "Internship Coordinator",

        // Sidebar Links
        "side_dash": "Dashboard",
        "side_profile": "Academic Profile",
        "side_opps": "Explore Opportunities",
        "side_my_apps": "My Applications",
        "side_my_tasks": "Tasks & Submissions",
        "side_progress": "Progress & Final Report",
        "side_manage_opps": "Manage Opportunities",
        "side_review_apps": "Review Applications",
        "side_my_trainees": "Accepted Trainees",
        "side_manage_tasks": "Manage & Grade Tasks",
        "side_hours": "Approve Training Hours",
        "side_final_eval": "Company Final Evaluation",
        "side_company_acc": "Company Account",
        "side_student_monitor": "Student Progress Monitor",
        "side_academic_eval": "Academic Final Evaluation",
        "side_academic_acc": "Academic Supervisor Account",
        "side_coord_dash": "Statistical Dashboard",
        "side_manage_students": "Manage Students",
        "side_manage_companies": "Manage Companies",
        "side_manage_supervisors": "Manage Academic Supervisors",
        "side_assign_supervisors": "Supervisor Assignment",
        "side_monitor_placements": "Internship Placement Monitor",
        "side_final_review": "Final Completion Review",
        "side_contact_msgs": "Contact Messages",
        "side_grading_weights": "Grading Weights Setup",

        // Company Portal & Dashboard
        "comp_portal_badge": "Partner & Field Supervisors Portal",
        "comp_dash_title": "Training Partner Dashboard",
        "comp_supervisor_lbl": "Supervisor in Charge:",
        "comp_partner_faculty": "Partner School:",
        "comp_btn_add_opp": "Add Opportunity",
        "comp_btn_review_apps": "Review Applications",
        "comp_stat_active_opps": "Active Opportunities",
        "comp_stat_pending_apps": "Pending Applications",
        "comp_stat_trainees": "Active Trainees",
        "comp_stat_pending_tasks": "Submissions Pending Review",
        "comp_trainees_header": "Currently Enrolled KASIT Trainees",
        "btn_view_all": "View All",
        "th_trainee_name": "Trainee Name",
        "th_major": "Major",
        "th_approved_hours": "Approved Hours",
        "th_action": "Action",
        "abbr_hours": "hrs",
        "comp_tools_title": "Internship Management Tools",
        "comp_tool_tasks_title": "Assign & Grade Tasks",
        "comp_tool_tasks_desc": "Assign tasks and evaluate completed deliverables",
        "comp_tool_hours_title": "Approve Training Hours",
        "comp_tool_hours_desc": "Verify and approve weekly attendance logs",
        "comp_tool_eval_title": "Final Trainee Evaluation (40%)",
        "comp_tool_eval_desc": "Complete rubric and submit to Academic Supervisor",

        // Company Subpages
        "comp_opps_title": "Manage Field Training Opportunities",
        "comp_opps_desc": "Publish opportunities, configure available seats, and manage active listings.",
        "comp_btn_add_new_opp": "Add New Opportunity",
        "comp_review_title": "Review Student Applications",
        "comp_review_desc": "Review KASIT student resumes and make accept/reject decisions with remarks.",
        "comp_trainees_title": "Accepted Trainees (KASIT Students)",
        "comp_trainees_desc": "Track deliverables, approved hours, and tasks of confirmed trainees.",
        "comp_btn_manage_tasks": "Manage & Assign Tasks",
        "comp_btn_training_hours": "Approve Hours",
        "comp_tasks_title": "Manage & Grade Trainee Tasks",
        "comp_tasks_desc": "Assign deliverables with clear rubrics and evaluate student submissions.",
        "comp_btn_create_task": "Assign New Task",
        "comp_hours_title": "Approve Training Hours",
        "comp_hours_desc": "Audit weekly trainee activity logs and approve completed hours toward the 280-hour goal.",
        "comp_eval_title": "Company Final Evaluation (40%)",
        "comp_eval_desc": "Evaluate trainee final performance based on the 40% rubric and submit to faculty.",
        "comp_acc_title": "Company Supervisor Account Profile",
        "comp_acc_desc": "Company info, office location, and official contact details.",

        // Shared Table Headers & Badges
        "th_applied_opp": "Applied Opportunity",
        "th_applied_date": "Application Date",
        "th_resume": "CV & Cover Letter",
        "th_decision": "Decision",
        "th_status": "Status",
        "btn_review_cv": "Review CV",
        "btn_accept": "Accept",
        "btn_reject": "Reject",
        "lbl_student_id": "Student ID:",
        "lbl_email": "Email:",
        "lbl_phone": "Phone:",
        "lbl_academic_supervisor": "Academic Supervisor:",
        "lbl_approved_hours": "Approved Hours:",
        "badge_approved": "Approved & Completed",
        "badge_pending_eval": "Pending Evaluation",
        "badge_revision": "Revision Required",
        "badge_in_progress": "In Progress",
        "badge_accepted": "Accepted by Company",
        "badge_confirmed": "Confirmed Placement",
        "badge_rejected": "Rejected",
        "badge_pending_review": "Pending Review"
    }
};

class I18nManager {
    constructor() {
        this.currentLang = this.getSavedLanguage();
    }

    getSavedLanguage() {
        const match = document.cookie.match(new RegExp('(^| )uims_lang=([^;]+)'));
        if (match) return match[2];
        return localStorage.getItem('uims_lang') || 'ar';
    }

    setLanguage(lang) {
        if (lang !== 'ar' && lang !== 'en') lang = 'ar';
        this.currentLang = lang;
        localStorage.setItem('uims_lang', lang);
        document.cookie = `uims_lang=${lang};path=/;max-age=${60 * 60 * 24 * 365}`;
        this.applyLanguage(lang);
    }

    toggleLanguage() {
        const nextLang = this.currentLang === 'ar' ? 'en' : 'ar';
        this.setLanguage(nextLang);
    }

    applyLanguage(lang) {
        const html = document.documentElement;
        html.lang = lang;
        html.dir = (lang === 'ar' ? 'rtl' : 'ltr');

        // Swap bootstrap stylesheet if present
        const bsLink = document.getElementById('bootstrapCss');
        if (bsLink) {
            if (lang === 'ar') {
                bsLink.href = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css';
            } else {
                bsLink.href = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css';
            }
        }

        const dict = translations[lang] || translations.ar;

        // Apply translations to all DOM elements with data-i18n
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (dict[key]) {
                if (el.tagName === 'INPUT' && (el.type === 'button' || el.type === 'submit')) {
                    el.value = dict[key];
                } else if (dict[key].indexOf('<') !== -1) {
                    el.innerHTML = dict[key];
                } else {
                    el.innerText = dict[key];
                }
            }
        });

        // Apply translations to input placeholders
        document.querySelectorAll('[data-i18n-ph]').forEach(el => {
            const key = el.getAttribute('data-i18n-ph');
            if (dict[key]) {
                el.placeholder = dict[key];
            }
        });

        // Update language toggle button label across all buttons
        const switchButtons = document.querySelectorAll('.lang-switcher-btn');
        switchButtons.forEach(btn => {
            btn.innerHTML = `<i class="bi bi-globe2 me-1"></i> ${dict['switch_lang']}`;
        });
    }

    init() {
        this.applyLanguage(this.currentLang);
    }
}

window.uimsI18n = new I18nManager();

document.addEventListener('DOMContentLoaded', function () {
    window.uimsI18n.init();
});
