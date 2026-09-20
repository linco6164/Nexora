importScripts(
  'https://www.gstatic.com/firebasejs/11.0.2/firebase-app-compat.js'
);

importScripts(
  'https://www.gstatic.com/firebasejs/11.0.2/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: 'AIzaSyB3RG390AGz8-CgI--V36EajzrQGgiVD64',
  authDomain: 'flutternexora.firebaseapp.com',
  projectId: 'flutternexora',
  storageBucket: 'flutternexora.firebasestorage.app',
  messagingSenderId: '674750679479',
  appId: '1:674750679479:web:39ce2d7154b6873fe78032',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Background message:',
    payload
  );

  const notification = payload.notification;

  if (!notification) {
    return;
  }

  self.registration.showNotification(
    notification.title || 'Nexora Store',
    {
      body: notification.body || '',
      icon: '/icons/Icon-192.png',
    },
  );
});