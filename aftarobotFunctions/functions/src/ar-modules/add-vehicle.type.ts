// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from '../models/constants'
const uuid = require("uuid/v1");

export const addVehicleType = functions.https.onRequest(
  async (request, response) => {
    if (!request.body) {
      console.log("ERROR - request has no body");
      return response.sendStatus(400);
    }
    
    try {
      const firestore = admin.firestore();
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      firestore.settings(settings);
    } catch (e) {
    }


    console.log(`##### Incoming debug ${request.body.debug}`);
    console.log(`##### Incoming vehicleType ${JSON.stringify(request.body.vehicleType)}`);

    const vehicleType = request.body.vehicleType;
    const fs = admin.firestore()
    await writeType()
    return null;

    async function writeType() {
      try {
        if (!vehicleType.countryID) {
          const msg = "Missing countryID";
          console.error(msg);
          throw new Error(msg);
        }
        const qs = await fs.collection(constants.Constants.FS_VEHICLE_TYPES).where('make', '==', vehicleType.make)
          .where('model', '==', vehicleType.model)
          .where('countryID','==', vehicleType.countryID)
          .get()
        if (qs.docs.length === 0) {
          const msg = 'Vehicle Type already exists in country'
          console.error(msg);
          throw new Error(msg)
        }

        vehicleType.vehicleTypeID = uuid()
        const ref = await fs.collection(constants.Constants.FS_VEHICLE_TYPES).add(vehicleType);
        vehicleType.path = ref.path;
        await ref.set(vehicleType);
        console.log(`car type written to Firestore ${ref.path}`)
        return response.status(200).send(vehicleType)
      } catch (e) {
        console.error(e);
        return response.status(400).send(e);
      }
    }
  }
);
