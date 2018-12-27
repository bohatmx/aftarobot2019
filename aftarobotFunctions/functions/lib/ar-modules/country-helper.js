"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const admin = require("firebase-admin");
const constants = require("../models/constants");
const uuid = require("uuid/v1");
class CountryHelper {
    static writeCountry(country) {
        return __awaiter(this, void 0, void 0, function* () {
            const fs = admin.firestore();
            console.log(`CountryHelper ... Start Helping ... add country`);
            try {
                country.countryID = uuid();
                const qs0 = yield fs
                    .collection(constants.Constants.FS_COUNTRIES)
                    .where("name", "==", country.name)
                    .get();
                if (qs0.docs.length > 0) {
                    const msg = `Country already exists: ${country.name}`;
                    console.error(msg);
                    throw new Error(msg);
                }
                const ref = yield fs
                    .collection(constants.Constants.FS_COUNTRIES)
                    .add(country);
                country.path = ref.path;
                yield ref.set(country);
                console.log(`country written to Firestore ${ref.path}`);
                return country;
            }
            catch (e) {
                console.error(e);
                throw e;
            }
        });
    }
}
exports.CountryHelper = CountryHelper;
//# sourceMappingURL=country-helper.js.map