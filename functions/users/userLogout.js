const { Timestamp } = require('firebase-admin/firestore')
const { db } = require('../admin_init')

exports.usersLogout = async (req, res) => {
    try {
        await db
            .doc(`users/${req.user.id}`)
            .update('isOnline', false, 'updatedAt', Timestamp.now())
        return res.status(200).json({ message: 'user logged out successfully' })
    } catch (err) {
        console.error(err)
        return res.status(500).json({ message: 'User Log Out Failed' })
    }
}
