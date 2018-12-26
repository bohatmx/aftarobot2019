// ######################################################################
// Add Landmarks to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export const addLandmarks = functions.https.onRequest(
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
      `##### Incoming landmarks: ${JSON.stringify(request.body.landmarks)}`
    );

    const landmarks = request.body.landmarks;
    if (!landmarks) {
      const msg = "missing landmarks";
      console.error(msg);
      return response.status(400).send(msg);
    }

    await writeLandmarks();
    return null;

    async function writeLandmarks() {
      try {
        for (const mark of landmarks) {
          if (!mark.landmarkID) {
            mark.landmarkID = uuid();
          }
          if (!mark.routeID) {
            const msg = `missing routeID for ${mark.landmarkName}`;
            console.error(msg);
            return response.status(400).send(msg);
          }
          if (!mark.latitude) {
            const msg = `missing latitude ${mark.latitude}`;
            console.error(msg);
            return response.status(400).send(msg);
          }
          if (!mark.longitude) {
            const msg = `missing longitude`;
            console.error(msg);
            return response.status(400).send(msg);
          }
          const qs0 = await fs
            .collection(constants.Constants.FS_LANDMARKS)
            .where("routeID", "==", mark.routeID)
            .where("landmarkName", "==", mark.landmarkName)
            .get();
          if (qs0.docs.length > 0) {
            const msg = `Landmark already exists on this route: ${
              mark.landmarkName
            } routeID: ${mark.routeID}`;
            console.error(msg);
          } else {
            const qs = await fs
              .collection(constants.Constants.FS_LANDMARKS)
              .where("latitude", "==", mark.latitude)
              .where("longitude", "==", mark.longitude)
              .where("routeID", "==", mark.routeID)
              .get();
            if (qs.docs.length > 0) {
              const msg = `Landmark already exists: ${
                mark.landmarkName
              } routeID: ${mark.routeID}`;
              console.error(msg);
            } else {
              const ref = await fs
                .collection(constants.Constants.FS_LANDMARKS)
                .add(mark);
              mark.path = ref.path;
              await ref.set(mark);

              console.log(
                `Landmark written to Firestore ${ref.path} ${mark.landmarkName}`
              );
            }
          }
        }
        return response.status(200).send(landmarks);
      } catch (e) {
        console.error(e);
        return response
          .status(400)
          .send(`Batched landmarks addition failed. ${e}`);
      }
    }
  }
);
