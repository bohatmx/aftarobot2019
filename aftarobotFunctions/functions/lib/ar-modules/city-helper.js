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
class CityHelper {
    static writeCity(city) {
        return __awaiter(this, void 0, void 0, function* () {
            const fs = admin.firestore();
            try {
                const qs = yield fs.doc(city.countryPath).collection('cities')
                    .where('name', '==', city.name).get();
                if (qs.docs.length > 0) {
                    console.error(`City seems to be a duplicate: ${city}`);
                    return city;
                }
                city.cityID = uuid();
                const ref = yield fs
                    .doc(city.countryPath)
                    .collection(constants.Constants.FS_CITIES)
                    .add(city);
                city.path = ref.path;
                yield ref.set(city);
                console.log(`city written to Firestore ${ref.path}`);
                return city;
            }
            catch (e) {
                console.error(e);
                throw e;
            }
        });
    }
}
exports.CityHelper = CityHelper;
//# sourceMappingURL=city-helper.js.map