"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var admin = require("firebase-admin");
var load_json_file_1 = require("load-json-file");
var getCredentialsFromFile = function (credentialsFilename) {
    return load_json_file_1.default(credentialsFilename);
};
exports.getCredentialsFromFile = getCredentialsFromFile;
var getFirestoreDBReference = function (credentials) {
    admin.initializeApp({
        credential: admin.credential.cert(credentials),
        databaseURL: "https://" + credentials.project_id + ".firebaseio.com"
    });
    var firestore = admin.firestore();
    firestore.settings({ timestampsInSnapshots: true });
    return firestore;
};
exports.getFirestoreDBReference = getFirestoreDBReference;
var getDBReferenceFromPath = function (db, dataPath) {
    var startingRef;
    if (dataPath) {
        var parts = dataPath.split('/').length;
        var isDoc = parts % 2 === 0;
        startingRef = isDoc ? db.doc(dataPath) : db.collection(dataPath);
    }
    else {
        startingRef = db;
    }
    return startingRef;
};
exports.getDBReferenceFromPath = getDBReferenceFromPath;
var isLikeDocument = function (ref) {
    return ref.collection !== undefined;
};
exports.isLikeDocument = isLikeDocument;
var isRootOfDatabase = function (ref) {
    return ref.batch !== undefined;
};
exports.isRootOfDatabase = isRootOfDatabase;
var sleep = function (timeInMS) { return new Promise(function (resolve) { return setTimeout(resolve, timeInMS); }); };
exports.sleep = sleep;
