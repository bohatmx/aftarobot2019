"use strict";
// ######################################################################
// Add Vehicles to Firestore
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
const add_vehicle_helper_1 = require("./add-vehicle-helper");
const uuid = require("uuid/v1");
exports.addVehicles = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
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
    console.log(`##### Incoming vehicles: ${JSON.stringify(request.body.vehicles)}`);
    const vehicles = request.body.vehicles;
    if (!vehicles) {
        response.status(400).send(`Missing vehicle batch`);
    }
    else {
        yield writeVehicles();
    }
    return null;
    function writeVehicles() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log(`adding ${vehicles.length} vehicles to Firestore`);
            const results = [];
            try {
                for (const vehicle of vehicles) {
                    const resultVehicle = yield add_vehicle_helper_1.VehicleHelper.writeVehicle(vehicle);
                    results.push(resultVehicle);
                }
                console.log(`${vehicles.length} batched vehicles added to Firestore. complete. cool.`);
                return response.status(200).send(results);
            }
            catch (e) {
                console.log(e);
                return response.status(400).send(e);
            }
        });
    }
}));
//# sourceMappingURL=add-vehicles.js.map