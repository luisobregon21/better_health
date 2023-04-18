const { Timestamp } = require('firebase-admin/firestore')
const { db } = require('../admin_init')
const axios = require('axios')
const path = require('path')
require('dotenv').config({ 'path': path.resolve(__dirname, '../../.env') });
const { GOOGLE_API_KEY } = process.env;


async function getHospitalReviews(placeId) {
  const hospitalbyId = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,rating,reviews&key=${GOOGLE_API_KEY}`;
  try {
    const response = await axios.get(hospitalbyId);
    const hospital = response.data;
    return hospital;
  } catch (error) {
    console.error(`Error getting reviews for hospital ${placeId}:`, error);
    return null;
  }
}

exports.saveHospitalInfo = async (hospital) => {
  const { name, place_id: placeId, geometry } = hospital;
  const docRef = db.collection('hospitals').doc(placeId);
  try {
    await docRef.set({
      name,
      placeId,
      geometry,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    const hospital = await getHospitalReviews(placeId)
    if (hospital) {
      const rating = hospital.result?.rating ? hospital.result.rating : null
      const reviews = hospital.result?.reviews ? hospital.result.reviews : null
      await docRef.update({
        rating,
        reviews,
        updatedAt: Timestamp.now(),
      });
    }
  } catch (error) {
    console.error(`Error saving hospital ${placeId}: ${error}`);
  }
}


