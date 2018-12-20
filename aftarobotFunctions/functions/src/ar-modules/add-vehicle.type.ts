// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

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
        const ref = await fs.collection('vehicleTypes').add(vehicleType);
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
