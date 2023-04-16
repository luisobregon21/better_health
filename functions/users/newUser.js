const { Timestamp } = require('firebase-admin/firestore')
const { db } = require('../admin_init')
const { createUserWithEmailAndPassword } = require('firebase/auth')
const { auth, firebaseConfig } = require('../app_init')
const { sendEmailVerification } = require('firebase/auth')
const validator = require("email-validator");


const config = firebaseConfig

// function validates email
const isEmail = (email) => {
    return validator.validate(email)
}

exports.newUser = async (req, res) => {
    const { username, email, password, confirmationPassword } = req.body
    if (!username || !password || !email || !confirmationPassword) {
        return res.status(400).json({ message: 'Missing required field' })
    } else if (!isEmail(email)) {
        return res
            .status(400)
            .json({ message: 'Must be a valid email address' })
    }
    if (password !== confirmationPassword) {
        return res.status(400).json({ message: 'Passwords do not match' })
    }

    const noImg = 'no-profile.png'
    try {
        const { user } = await createUserWithEmailAndPassword(
            auth,
            email,
            password
        )

        // See the UserRecord reference doc for the contents of userRecord.
        console.log('Successfully created new user:', user.uid)

        //creating new user in users table that matches newly created user in firebase auth
        const newUser = {
            id: user.uid,
            username,
            email,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
            profile: `https://firebasestorage.googleapis.com/v0/b/${config.storageBucket}/o/${noImg}?alt=media`,
            age: null,
            weight: null,
            Height: null,
            score: null,
            location: null,
            emergencyContacts: []
        }

        await db.collection('users').doc(user.uid).set(newUser)
        const token = await user.getIdToken()
        sendEmailVerification(user)
        // sendEmail(user.email)

        return res.status(201).json({
            ...newUser,
            createdAt: newUser.createdAt.toDate(),
            updatedAt: newUser.updatedAt.toDate(),
            token,
        })
    } catch (err) {
        console.log('Error creating new user:', err)
        return res.status(400).json({ message: err.message })
    }
}
