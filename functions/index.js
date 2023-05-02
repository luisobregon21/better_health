const functions = require('firebase-functions');
const { newUser } = require('./users/newUser');
const { usersLogin } = require('./users/usersLogin');
const { usersLogout } = require('./users/userLogout');
const { withAuth } = require('./firebaseAuth');
// const { saveHospitalReviews } = require('./reviews/hospital_reviews')
// const { saveReviews } = require('./reviews/save_reviews')
const { allReviews } = require('./reviews/all_reviews');
const { getOverallSentiment } = require('./model/classify_reviews');
const { getHospitalById } = require('./reviews/get_hospital_by_id');

const express = require('express');
const app = express();

const runtimeOpts = {
    timeoutSeconds: 540,
    memory: '1GB'
};


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

// only run once
// app.get('/getHospitalData', saveHospitalReviews);
// app.put('/saveReviews', saveReviews)
app.get('/getReviews', allReviews);
app.get('/getReviewSentiments', getOverallSentiment);
app.post('/getHospitalById', getHospitalById);
exports.api = functions.runWith(runtimeOpts).https.onRequest(app);
