"use strict";
// ######################################################################
// Add cities to Firestore
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
const city_helper_1 = require("./city-helper");
exports.addCities = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
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
    console.log(`##### Incoming body; ${request.body}`);
    console.log(`##### Incoming cities: ${JSON.stringify(request.body.cities)}`);
    const cities = request.body.cities;
    if (!cities) {
        const msg = "missing cities";
        console.error(msg);
        return response.status(400).send(msg);
    }
    yield writeCities();
    return null;
    function writeCities() {
        return __awaiter(this, void 0, void 0, function* () {
            const results = [];
            try {
                for (const city of cities) {
                    const result = yield city_helper_1.CityHelper.writeCity(city);
                    results.push(result);
                }
                return response.status(200).send(results);
            }
            catch (e) {
                console.error(e);
                return response.status(400).send(e);
            }
        });
    }
}));
//# sourceMappingURL=add-cities.js.map