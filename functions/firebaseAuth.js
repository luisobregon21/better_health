const { adminAuth, db } = require('./admin_init')

exports.withAuth = async (req, res, next) => {
    const token = req.headers.authorization?.split('Bearer ')[1]

    if (!token) {
        return res.status(401).send('Unauthorized')
    }

    try {
        const decodedToken = await adminAuth.verifyIdToken(token)

        const user = await db.collection('users').doc(decodedToken.uid).get()

        req.user = {
            ...user.data(),
            createdAt: user.data().createdAt.toDate(),
            updatedAt: user.data().updatedAt.toDate(),
        }

        next()
    } catch (error) {
        console.error(error)
        return res.status(403).send('Unauthorized')
    }
}
