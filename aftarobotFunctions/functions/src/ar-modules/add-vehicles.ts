// ######################################################################
// Add Vehicles to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
import { VehicleHelper } from "./add-vehicle-helper";
const uuid = require("uuid/v1");

export const addVehicles = functions.https.onRequest(
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
      `##### Incoming vehicles: ${JSON.stringify(request.body.vehicles)}`
    );

    const vehicles = request.body.vehicles;
    if (!vehicles) {
      response.status(400).send(`Missing vehicle batch`);
    } else {
      await writeVehicles();
    }
    return null;

    async function writeVehicles() {
      console.log(`adding ${vehicles.length} vehicles to Firestore`);
      const results = [];
      try {
        for (const vehicle of vehicles) {
          const resultVehicle = await VehicleHelper.writeVehicle(vehicle);
          results.push(resultVehicle);
        }
        console.log(
          `${
            vehicles.length
          } batched vehicles added to Firestore. complete. cool.`
        );
        return response.status(200).send(results);
      } catch (e) {
        console.log(e);
        return response.status(400).send(e);
      }
    }
  }
);
