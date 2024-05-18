importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyBZ-iniIGz_mEnPh1y2DIaWJfKXKhMuzqE",
    authDomain: "ladybugg-d6b34.firebaseapp.com",
    projectId: "ladybugg-d6b34",
    storageBucket: "ladybugg-d6b34.appspot.com",
    messagingSenderId: "607579215687",
    appId: "1:607579215687:web:dd48c495f8d8607e821e62",
    measurementId: "G-R729X8CNYN"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});