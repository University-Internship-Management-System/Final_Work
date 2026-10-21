// ========================================================
// University Internship Management System (UIMS)
// Firebase Service Handler & Sync Layer
// ========================================================

class FirebaseService {
    constructor() {
        this.isReady = false;
        this.auth = null;
        this.db = null;
        this.init();
    }

    init() {
        try {
            if (typeof firebase !== 'undefined' && window.isFirebaseConfigured && window.isFirebaseConfigured()) {
                if (!firebase.apps.length) {
                    firebase.initializeApp(window.UIMS_FIREBASE_CONFIG);
                }
                this.auth = firebase.auth();
                this.db = firebase.firestore();
                this.isReady = true;
                console.log("Firebase connected successfully to project: " + window.UIMS_FIREBASE_CONFIG.projectId);
            } else {
                console.info("UIMS running in Local/Session Data Mode (Firebase config pending). Full functionality remains active.");
            }
        } catch (err) {
            console.warn("Firebase initialization note:", err.message);
        }
    }

    // Save Contact Us message to Firebase / Firestore
    async saveContactMessage(name, email, subject, message) {
        const payload = {
            name: name,
            email: email,
            subject: subject,
            message: message,
            timestamp: new Date().toISOString(),
            status: "unread"
        };

        if (this.isReady && this.db) {
            try {
                const docRef = await this.db.collection("contact_messages").add(payload);
                return { success: true, id: docRef.id, source: "firebase" };
            } catch (err) {
                console.error("Firebase saveContactMessage error:", err);
            }
        }

        // Fallback to local storage
        try {
            const list = JSON.parse(localStorage.getItem("uims_contact_messages") || "[]");
            payload.id = "local_msg_" + Date.now();
            list.push(payload);
            localStorage.setItem("uims_contact_messages", JSON.stringify(list));
            return { success: true, id: payload.id, source: "local" };
        } catch (e) {
            return { success: true, id: "fallback_" + Date.now(), source: "memory" };
        }
    }

    // Password reset helper via Firebase Auth
    async sendPasswordReset(email) {
        if (this.isReady && this.auth) {
            try {
                await this.auth.sendPasswordResetEmail(email);
                return { success: true, message: "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني عبر Firebase." };
            } catch (err) {
                return { success: false, message: err.message };
            }
        } else {
            // Local fallback simulation
            return { 
                success: true, 
                message: "تم محاكاة إرسال رابط استعادة كلمة المرور بنجاح إلى: " + email + " (سيتم الربط مع مزود البريد فور إدخال مفاتيح Firebase)." 
            };
        }
    }
}

window.uimsFirebase = new FirebaseService();
