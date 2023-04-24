const { db } = require('../admin_init')

exports.allReviews = async (req, res) => {
    try {
        const usersSnapshot = await db.collection('reviews').get()
        const reviews = []
        usersSnapshot.docs.map((doc) => {
            const {relative_time_description, text, rating} = doc.data().review
            const review = {
                text,
                rating,
                posted: relative_time_description
            }
            reviews.push(review)
        })
        return res.status(200).json(reviews)
    } catch (err) {
        return { 'error': err }
    }
}