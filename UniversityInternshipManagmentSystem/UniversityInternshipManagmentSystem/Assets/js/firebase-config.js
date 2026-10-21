// ========================================================
// University Internship Management System (UIMS)
// University of Jordan (UJ) - KASIT
// Firebase Configuration File
// ========================================================

const firebaseConfig = {
    apiKey: "YOUR_API_KEY_HERE",
    authDomain: "your-project-id.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project-id.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
};

// Check if credentials have been replaced with real credentials
const isFirebaseConfigured = () => {
    return firebaseConfig.apiKey && 
           firebaseConfig.apiKey !== "YOUR_API_KEY_HERE" && 
           firebaseConfig.projectId !== "your-project-id";
};

window.UIMS_FIREBASE_CONFIG = firebaseConfig;
window.isFirebaseConfigured = isFirebaseConfigured;
