// Admin SDK
const { initializeApp } = require('firebase-admin/app')
const admin = require('firebase-admin')
const { getFirestore } = require('firebase-admin/firestore')
const { getAuth } = require('firebase-admin/auth')

// Initialize SDK
initializeApp()
const db = getFirestore()
const adminAuth = getAuth()

module.exports = {
    db,
    adminAuth,
    admin,
}
