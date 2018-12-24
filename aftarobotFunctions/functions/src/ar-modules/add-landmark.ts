// ######################################################################
// Add Landmark to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export const addLandmark = functions.https.onRequest(
  async (request, response) => {
    if (!request.body) {
      const msg = "ERROR - request has no body";
      console.error(msg);
      return response.status(400).send(msg);
    }
    const fs = admin.firestore();
    try {
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      fs.settings(settings);
    } catch (e) {}

    console.log(`##### Incoming debug; ${request.body.debug}`);
    console.log(
      `##### Incoming landmark: ${JSON.stringify(request.body.landmark)}`
    );

    const landmark = request.body.landmark;
    if (!landmark) {
      const msg = "missing landmark";
      console.error(msg);
      return response.status(400).send(msg);
    }

    await writeLandmark();
    return null;

    async function writeLandmark() {
      try {
        if (!landmark.landmarkID) {
          landmark.landmarkID = uuid();
        }
        if (!landmark.routeID) {
          const msg = `missing routeID for ${landmark.landmarkName}`;
          console.error(msg);
          return response.status(400).send(msg);
        }
        if (!landmark.latitude) {
          const msg = `missing latitude ${landmark.latitude}`;
          console.error(msg);
          return response.status(400).send(msg);
        }
        if (!landmark.longitude) {
          const msg = `missing longitude`;
          console.error(msg);
          return response.status(400).send(msg);
        }
        const qs0 = await fs
          .collection(constants.Constants.FS_LANDMARKS)
          .where("routeID", "==", landmark.routeID)
          .where("landmarkName", "==", landmark.landmarkName)
          .get();
        if (qs0.docs.length > 0) {
          const msg = `Landmark already exists on this route: ${
            landmark.landmarkName
          } routeID: ${landmark.routeID}`;
          console.error(msg);
          throw new Error(msg);
        }
        const qs = await fs
          .collection(constants.Constants.FS_LANDMARKS)
          .where("latitude", "==", landmark.latitude)
          .where("longitude", "==", landmark.longitude)
          .where("routeID", "==", landmark.routeID)
          .get();
        if (qs.docs.length > 0) {
          const msg = `Landmark already exists: ${
            landmark.landmarkName
          } routeID: ${landmark.routeID}`;
          console.error(msg);
          throw new Error(msg);
        }
        const ref = await fs
          .collection(constants.Constants.FS_LANDMARKS)
          .add(landmark);
        landmark.path = ref.path;
        await ref.set(landmark);

        console.log(`Landmark written to Firestore ${ref.path}`);
        return response.status(200).send(landmark);
      } catch (e) {
        console.error(e);
        return response.status(400).send(e);
      }
    }
  }
);
