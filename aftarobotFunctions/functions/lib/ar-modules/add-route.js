"use strict";
// ######################################################################
// Add route to Firestore
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
exports.addRoute = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
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
    console.log(`##### Incoming route: ${JSON.stringify(request.body.route)}`);
    const route = request.body.route;
    if (!route) {
        const msg = "missing route";
        console.error(msg);
        return response.status(400).send(msg);
    }
    yield writeRoute();
    return null;
    function writeRoute() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                if (!route.routeID) {
                    route.routeID = uuid();
                }
                const qs0 = yield fs
                    .collection(constants.Constants.FS_ROUTES)
                    .where("associationID", "==", route.associationID)
                    .where("name", "==", route.name)
                    .get();
                if (qs0.docs.length > 0) {
                    const msg = `route already exists: ${route.name}`;
                    console.error(msg);
                    throw new Error(msg);
                }
                const ref = yield fs.collection(constants.Constants.FS_ROUTES).add(route);
                route.path = ref.path;
                yield ref.set(route);
                console.log(`route written to Firestore ${ref.path}`);
                return response.status(200).send(route);
            }
            catch (e) {
                console.error(e);
                return response.status(400).send(e);
            }
        });
    }
}));
//# sourceMappingURL=add-route.js.map