const { saveHospitalInfo } = require('./save_hospitals')
const axios = require('axios')
const path = require('path')
require('dotenv').config({'path': path.resolve(__dirname, '../../.env')});
const { GOOGLE_API_KEY } = process.env;


async function fetchAndSaveHospitals(nextPageToken = null) {
    let hospitalsPR = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=hospitals+in+Puerto+Rico&key=${GOOGLE_API_KEY}`;
    if (nextPageToken) {
        hospitalsPR += `&page_token=${nextPageToken}`;
    }

    try {
        const response = await axios.get(hospitalsPR);
        const hospitals = response.data.results;

        // Save hospitals to Firestore
        const promises = hospitals.map(async (hospital) => {
            await saveHospitalInfo(hospital);
        });
        await Promise.all(promises);

        // Check if there are more results and recursively fetch them
        if (response.data.next_page_token) {
            const nextPageToken = response.data.next_page_token;
            await new Promise(resolve => setTimeout(resolve, 2000)); // add a delay of 2 seconds
            await fetchAndSaveHospitals(nextPageToken);
        }
    } catch (error) {
        console.error(error);
    }
}



exports.saveHospitalReviews = async (req, res) => {
    try {
        await fetchAndSaveHospitals();
        res.status(200).send('Hospitals saved successfully!');
    } catch (error) {
        console.error(`Error saving hospitals: ${error}`);
        res.status(400).send('Error saving hospitals.');
    }
}
