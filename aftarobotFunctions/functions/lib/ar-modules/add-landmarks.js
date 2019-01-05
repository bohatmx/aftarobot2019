"use strict";
// ######################################################################
// Add Landmarks to Firestore
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
exports.addLandmarks = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
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
    console.log(`##### Incoming landmarks: ${JSON.stringify(request.body.landmarks)}`);
    const landmarks = request.body.landmarks;
    if (!landmarks) {
        const msg = "missing landmarks";
        console.error(msg);
        return response.status(400).send(msg);
    }
    yield writeLandmarks();
    return null;
    function writeLandmarks() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                for (const mark of landmarks) {
                    if (!mark.landmarkID) {
                        mark.landmarkID = uuid();
                    }
                    if (!mark.routeID) {
                        const msg = `missing routeID for ${mark.landmarkName}`;
                        console.error(msg);
                        return response.status(400).send(msg);
                    }
                    if (!mark.latitude) {
                        const msg = `missing latitude ${mark.latitude}`;
                        console.error(msg);
                        return response.status(400).send(msg);
                    }
                    if (!mark.longitude) {
                        const msg = `missing longitude`;
                        console.error(msg);
                        return response.status(400).send(msg);
                    }
                    const qs0 = yield fs
                        .collection(constants.Constants.FS_LANDMARKS)
                        .where("routeID", "==", mark.routeID)
                        .where("landmarkName", "==", mark.landmarkName)
                        .get();
                    if (qs0.docs.length > 0) {
                        const msg = `Landmark already exists on this route: ${mark.landmarkName} routeID: ${mark.routeID}`;
                        console.error(msg);
                    }
                    else {
                        const qs = yield fs
                            .collection(constants.Constants.FS_LANDMARKS)
                            .where("latitude", "==", mark.latitude)
                            .where("longitude", "==", mark.longitude)
                            .where("routeID", "==", mark.routeID)
                            .get();
                        if (qs.docs.length > 0) {
                            const msg = `Landmark already exists: ${mark.landmarkName} routeID: ${mark.routeID}`;
                            console.error(msg);
                        }
                        else {
                            mark.path = `landmarks/${mark.landmarkID}`;
                            const ref = yield fs
                                .collection(constants.Constants.FS_LANDMARKS)
                                .doc(mark.landmarkID)
                                .set(mark);
                            console.log(`Landmark written to Firestore ${mark.path} - ${mark.landmarkName}`);
                        }
                    }
                }
                return response.status(200).send(landmarks);
            }
            catch (e) {
                console.error(e);
                return response
                    .status(400)
                    .send(`Batched landmarks addition failed. ${e}`);
            }
        });
    }
}));
//# sourceMappingURL=add-landmarks.js.map