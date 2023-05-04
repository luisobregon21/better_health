const { saveHospitalInfo, getHospitalReviews } = require('./save_hospitals')
const { db } = require('../admin_init')


exports.getHospitalById = async (req, res) => {
    const { hospital } = req.body
    try {
        const hospitalRef = db.collection('hospitals').doc(hospital.place_id)
        const placeId = hospital.place_id
        let reviews;
        const doc = await hospitalRef.get();
        if (!doc.exists) {
            await saveHospitalInfo(hospital);
            try {
                const hospitalData = await getHospitalReviews(placeId);
                console.log("hospital data from revews is: ", hospitalData)
                if (hospitalData) {
                    reviews = hospitalData.result?.reviews ? hospitalData.result.reviews : null
                }
            } catch (error) {
                console.error(`Error getting reviews for hospital ${placeId}:`, error);
                return null;
            }
        } else {
            reviews = doc.data()['reviews'];
        }
        console.log("reviews is :", reviews)
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
        return res.status(400).json({ error: err })
    }
}