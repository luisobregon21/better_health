// Firebase App
const { initializeApp: initializeClientApp } = require('firebase/app')
const { getAuth: getClientAuth } = require('firebase/auth')

// Initialize Client
const firebaseConfig = {
    apiKey: "AIzaSyCzuNReLKrZOBlIbpfveDXoz-AB05d6e58",
    authDomain: "betterhealth-f9c79.firebaseapp.com",
    projectId: "betterhealth-f9c79",
    storageBucket: "betterhealth-f9c79.appspot.com",
    messagingSenderId: "707528861411",
    appId: "1:707528861411:web:c9794bbad75f9e804207d6",
    measurementId: "G-VPDNB3F7QH"
  };

// initializing app
initializeClientApp(firebaseConfig)
const auth = getClientAuth()

exports.firebaseConfig = firebaseConfig
exports.auth = auth
