const functions = require('firebase-functions');
const { newUser } = require('./users/newUser');
const { usersLogin } = require('./users/usersLogin');
const { usersLogout } = require('./users/userLogout');
const { withAuth } = require('./firebaseAuth');

const express = require('express');
const app = express();

const cors = require('cors');
app.use(
    cors({
        origin: '*',
    })
);

// Users Post endpoints
app.post('/users/new', newUser);
app.post('/login', usersLogin);
app.put('/logout', withAuth, usersLogout);

exports.api = functions.https.onRequest(app);
