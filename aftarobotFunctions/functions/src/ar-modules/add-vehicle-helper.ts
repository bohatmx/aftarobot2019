import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export class VehicleHelper {
  static async writeVehicle(vehicle) {
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
      const qs = await fs
        .doc(vehicle.assocPath)
        .collection(constants.Constants.FS_VEHICLES)
        .where("vehicleReg", "==", vehicle.vehicleReg)
        .get();
      if (qs.docs.length > 0) {
        const msg = `Vehicle already exists: ${vehicle.vehicleReg}`;
        console.error(msg);
        return vehicle;
      }
      const ref = await fs
        .doc(vehicle.assocPath)
        .collection(constants.Constants.FS_VEHICLES)
        .add(vehicle);
      vehicle.path = ref.path;
      await ref.set(vehicle);
      if (vehicle.ownerPath) {
        const ref2 = await fs
          .doc(vehicle.ownerPath)
          .collection(constants.Constants.FS_VEHICLES)
          .add(vehicle);
        vehicle.path = ref2.path;
        await ref.set(vehicle);
      } else {
        console.error(
          `car has no owner path, please check: ${vehicle.vehicleReg}`
        );
      }
      console.log(`car written to Firestore ${ref.path}`);
      return vehicle;
    } catch (e) {
      console.log(e);
      throw e;
    }
  }
}
