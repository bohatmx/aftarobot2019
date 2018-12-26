"use strict";
// ######################################################################
// Add Vehicle to Firestore
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
exports.addVehicle = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    if (!request.body) {
        console.log("ERROR - request has no body");
        return response.sendStatus(400);
    }
    const fs = admin.firestore();
    try {
        const settings = { /* your settings... */ timestampsInSnapshots: true };
        fs.settings(settings);
    }
    catch (e) { }
    console.log(`##### Incoming debug; ${request.body.debug}`);
    console.log(`##### Incoming vehicle: ${JSON.stringify(request.body.vehicle)}`);
    const vehicle = request.body.vehicle;
    if (!vehicle.vehicleType) {
        console.error("Vehicle has no type");
        return response.status(400).send("Vehicle does not have a type");
    }
    yield writeVehicle();
    return null;
    function writeVehicle() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                if (!vehicle.assocPath) {
                    const msg = `Missing vehicle.assocPath`;
                    console.error(msg);
                    return response.status(400).send(msg);
                }
                if (!vehicle.associationID) {
                    const msg = `Missing vehicle associationID`;
                    console.error(msg);
                    return response.status(400).send(msg);
                }
                if (!vehicle.vehicleType) {
                    const msg = `Missing vehicle type`;
                    console.error(msg);
                    return response.status(400).send(msg);
                }
                const qs = yield fs
                    .doc(vehicle.assocPath)
                    .collection(constants.Constants.FS_VEHICLES)
                    .where("vehicleReg", "==", vehicle.vehicleReg)
                    .get();
                if (qs.docs.length > 0) {
                    const msg = `Vehicle already exists: ${vehicle.vehicleReg}`;
                    console.error(msg);
                    return response.status(201).send(vehicle);
                }
                const ref = yield fs
                    .doc(vehicle.assocPath)
                    .collection(constants.Constants.FS_VEHICLES)
                    .add(vehicle);
                vehicle.path = ref.path;
                yield ref.set(vehicle);
                if (vehicle.ownerPath) {
                    const ref2 = yield fs
                        .doc(vehicle.ownerPath)
                        .collection(constants.Constants.FS_VEHICLES)
                        .add(vehicle);
                    vehicle.path = ref2.path;
                    yield ref.set(vehicle);
                }
                else {
                    console.error(`car has no owner path, please check: ${vehicle.vehicleReg}`);
                }
                console.log(`car written to Firestore ${ref.path}`);
                return response.status(200).send(vehicle);
            }
            catch (e) {
                console.log(e);
                return response.status(400).send(e);
            }
        });
    }
}));
//# sourceMappingURL=add-vehicle.js.map