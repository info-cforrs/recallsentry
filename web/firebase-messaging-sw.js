importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: 'AIzaSyAilMejhWBiDq-31ACj62EndsWw7RfqMDQ',
  appId: '1:17657815993:web:2ec9c405c656315dd90c68',
  messagingSenderId: '17657815993',
  projectId: 'recallsentry-app',
  authDomain: 'recallsentry-app.firebaseapp.com',
  storageBucket: 'recallsentry-app.firebasestorage.app',
  measurementId: 'G-C8PDB2BHM1',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
