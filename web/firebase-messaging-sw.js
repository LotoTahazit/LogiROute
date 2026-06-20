/* eslint-disable no-undef */
// FCM service worker for LogiRoute web push.
// Config must match lib/firebase_options.dart (web platform).
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAR0UQPT5RMlEOFg8rTV_NbYl4yQMbhJbE',
  authDomain: 'logiroute-app.firebaseapp.com',
  projectId: 'logiroute-app',
  storageBucket: 'logiroute-app.firebasestorage.app',
  messagingSenderId: '375119625021',
  appId: '1:375119625021:web:250eccc94710e0d83f6354',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'LogiRoute';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
