"use strict";
// ######################################################################
// Add Country to Firestore
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
const country_helper_1 = require("./country-helper");
const uuid = require("uuid/v1");
exports.addCountries = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
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
    console.log(`##### Incoming country: ${JSON.stringify(request.body.countries)}`);
    const countries = request.body.countries;
    if (!countries) {
        const msg = "missing countries";
        console.error(msg);
        return response.status(400).send(msg);
    }
    yield writeCountries();
    return null;
    function writeCountries() {
        return __awaiter(this, void 0, void 0, function* () {
            const results = [];
            try {
                for (const country of countries) {
                    const result = yield country_helper_1.CountryHelper.writeCountry(country);
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
//# sourceMappingURL=add-countries.js.map