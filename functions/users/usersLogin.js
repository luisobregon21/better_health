const { signInWithEmailAndPassword } = require('firebase/auth')
const { Timestamp } = require('firebase-admin/firestore')
const { auth } = require('../app_init')
const { db } = require('../admin_init')

exports.usersLogin = async (req, res) => {
    const { email, password } = req.body

    if (!email || !password) {
        return res.status(400).json({
            error: 'Need Both email and password',
        })
    }
    try {
        const userCredential = await signInWithEmailAndPassword(
            auth,
            email,
            password
        )
        // console.log('user ', userCredential.user)

        const token = await userCredential.user.getIdToken()
        console.log(token)

        const userSnapshot = await db
            .collection('users')
            .doc(userCredential.user.uid)
            .get()
        // content data by itself
        const userData = userSnapshot.data()
        await db
            .doc(`users/${userData.id}`)
            .update('isOnline', true, 'updatedAt', Timestamp.now())
        userData.isOnline = true
        return res.status(200).json({
            ...userData,
            createdAt: userData.createdAt.toDate(),
            updatedAt: userData.updatedAt.toDate(),
            token,
        })
    } catch (error) {
        console.error(error)
        return res.status(400).json({
            error: error.message,
        })
    }
}
