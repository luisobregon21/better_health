const { db } = require('../admin_init')

exports.allHospitals = async () => {
    try {
        const usersSnapshot = await db.collection('hospitals').get()
        const hospitals = []
        usersSnapshot.docs.map((doc) => {
            hospitals.push(doc.data())
        })
        return hospitals
    } catch (err) {
        return { 'error': err }
    }
}