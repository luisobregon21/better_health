const { db } = require('../admin_init')
const { allHospitals } = require('./all_hospitals')
const { Timestamp } = require('firebase-admin/firestore')
const { v4: uuidv4 } = require('uuid');

exports.saveReviews = async (req, res) => {
    const hospitals = await allHospitals();
    hospitals.map(async (hospital) => {
        const { reviews, createdAt, placeId } = hospital
        if (reviews) {
            reviews.map(async (review) => {
                const id = uuidv4()
                const docRef = db.collection('reviews').doc(id);

                try {
                    await docRef.set({
                        review,
                        placeId,
                        createdAt: createdAt,
                        updatedAt: Timestamp.now(),
                    })
                } catch (error) {
                    return res.status(500).json({ error: err })
                }

            })

        }
    })
    return res.status(200).json({ message: 'Reviews where saved successfully' })
}