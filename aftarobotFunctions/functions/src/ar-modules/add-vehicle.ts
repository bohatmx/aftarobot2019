// ######################################################################
// Add Vehicle to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from '../models/constants'
const uuid = require("uuid/v1");

export const addVehicle = functions.https.onRequest(
  async (request, response) => {
    if (!request.body) {
      console.log("ERROR - request has no body");
      return response.sendStatus(400);
    }
    const fs = admin.firestore();
    try {
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      fs.settings(settings);
    } catch (e) {}

    console.log(`##### Incoming debug; ${request.body.debug}`);
    console.log(
      `##### Incoming vehicle: ${JSON.stringify(request.body.vehicle)}`
    );

    const vehicle = request.body.vehicle;
    if (!vehicle.vehicleType) {
      console.error("Vehicle has no type");
      return response.status(400).send("Vehicle does not have a type");
    }

    await writeVehicle();
    return null;

    async function writeVehicle() {
      try {
        if (!vehicle.assocPath) {
          const msg = `Missing vehicle.assocPath`;
          console.error(msg);
          return response.status(400).send(msg);
        }
        if (!vehicle.vehicleType) {
          const msg = `Missing vehicleType`;
          console.error(msg);
          return response.status(400).send(msg);
        }
        const qs = await fs
          .doc(vehicle.assocPath)
          .collection(constants.Constants.FS_VEHICLES)
          .where("vehicleReg", "==", vehicle.vehicleReg)
          .get();
        if (qs.docs.length === 0) {
          const msg = `Vehicle already exists: ${vehicle.vehicleReg}`;
          console.error(msg);
          throw new Error(msg);
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
          console.log(
            `car has no owner path, please check: ${vehicle.vehicleReg}`
          );
        }
        console.log(`car written to Firestore ${ref.path}`);
        return response.status(200).send(vehicle);
      } catch (e) {
        console.log(e);
        return response.status(400).send(e);
      }
    }
  }
);
