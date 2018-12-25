"use strict";
// ######################################################################
// Add Landmark to Firestore
// ######################################################################
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const constants = require("../models/constants");
const uuid = require("uuid/v1");
exports.addLandmark = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    if (!request.body) {
        const msg = "ERROR - request has no body";
        console.error(msg);
        return response.status(400).send(msg);
    }
    const fs = admin.firestore();
    try {
        const settings = { /* your settings... */ timestampsInSnapshots: true };
        fs.settings(settings);
    }
    catch (e) { }
    console.log(`##### Incoming debug; ${request.body.debug}`);
    console.log(`##### Incoming landmark: ${JSON.stringify(request.body.landmark)}`);
    const landmark = request.body.landmark;
    if (!landmark) {
        const msg = "missing landmark";
        console.error(msg);
        return response.status(400).send(msg);
    }
    yield writeLandmark();
    return null;
    function writeLandmark() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                if (!landmark.landmarkID) {
                    landmark.landmarkID = uuid();
                }
                if (!landmark.routeID) {
                    const msg = `missing routeID for ${landmark.landmarkName}`;
                    console.error(msg);
                    return response.status(400).send(msg);
                }
                if (!landmark.latitude) {
                    const msg = `missing latitude ${landmark.latitude}`;
                    console.error(msg);
                    return response.status(400).send(msg);
                }
                if (!landmark.longitude) {
                    const msg = `missing longitude`;
                    console.error(msg);
                    return response.status(400).send(msg);
                }
                const qs0 = yield fs
                    .collection(constants.Constants.FS_LANDMARKS)
                    .where("routeID", "==", landmark.routeID)
                    .where("landmarkName", "==", landmark.landmarkName)
                    .get();
                if (qs0.docs.length > 0) {
                    const msg = `Landmark already exists on this route: ${landmark.landmarkName} routeID: ${landmark.routeID}`;
                    console.error(msg);
                    return response.status(201).send(landmark);
                }
                const qs = yield fs
                    .collection(constants.Constants.FS_LANDMARKS)
                    .where("latitude", "==", landmark.latitude)
                    .where("longitude", "==", landmark.longitude)
                    .where("routeID", "==", landmark.routeID)
                    .get();
                if (qs.docs.length > 0) {
                    const msg = `Landmark already exists: ${landmark.landmarkName} routeID: ${landmark.routeID}`;
                    console.error(msg);
                    return response.status(201).send(landmark);
                }
                const ref = yield fs
                    .collection(constants.Constants.FS_LANDMARKS)
                    .add(landmark);
                landmark.path = ref.path;
                yield ref.set(landmark);
                console.log(`Landmark written to Firestore ${ref.path}`);
                return response.status(200).send(landmark);
            }
            catch (e) {
                console.error(e);
                return response.status(400).send(e);
            }
        });
    }
}));
//# sourceMappingURL=add-landmark.js.map