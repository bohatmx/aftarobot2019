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
class VehicleHelper {
    static writeVehicle(vehicle) {
        return __awaiter(this, void 0, void 0, function* () {
            const fs = admin.firestore();
            console.log(`AddVehicleHelper ... Start Helping ... add vehicle`);
            try {
                if (!vehicle.assocPath) {
                    const msg = `Missing vehicle.assocPath`;
                    console.error(msg);
                    throw new Error(msg);
                }
                if (!vehicle.associationID) {
                    const msg = `Missing vehicle associationID`;
                    console.error(msg);
                    throw new Error(msg);
                }
                if (!vehicle.vehicleType) {
                    const msg = `Missing vehicle type`;
                    console.error(msg);
                    throw new Error(msg);
                }
                if (!vehicle.vehicleID) {
                    const msg = `Missing vehicle ID, fixed it.`;
                    console.error(msg);
                    vehicle.vehicleID = uuid();
                }
                const qs = yield fs
                    .doc(vehicle.assocPath)
                    .collection(constants.Constants.FS_VEHICLES)
                    .where("vehicleReg", "==", vehicle.vehicleReg)
                    .get();
                if (qs.docs.length > 0) {
                    const msg = `Vehicle already exists: ${vehicle.vehicleReg}`;
                    console.error(msg);
                    return vehicle;
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
                // } else {
                //   console.error(
                //     `car has no owner path, please check: ${vehicle.vehicleReg}`
                //   );
                // }
                console.log(`car written to Firestore ${ref.path}`);
                return vehicle;
            }
            catch (e) {
                console.log(e);
                throw e;
            }
        });
    }
}
exports.VehicleHelper = VehicleHelper;
//# sourceMappingURL=add-vehicle-helper.js.map