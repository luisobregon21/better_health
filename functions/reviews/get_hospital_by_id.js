const { saveHospitalInfo } = require('./save_hospitals')
const { db } = require('../admin_init')

exports.getHospitalById = async (req, res) => {
    const { hospital } = req.body
    try {

        const hospitalRef = db.collection('hospitals').doc(hospital.place_id)

        const doc = await hospitalRef.get();
        if (!doc.exists) {
            await saveHospitalInfo(hospital);
        }

        const { reviews } = doc.data();

        if (reviews) {
            const textReviews = reviews.map((review) => {
                if (review.text && review.text !== "") {
                    return review.text
                }
            })
            return res.status(200).json({ 'reviews': textReviews })
        } else {
            return res.status(200).json({ 'reviews': [] })
        }
    } catch (err) {
        return res.status(500).json({ error: err })
    }
}