// ######################################################################
// Add route to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export const addRoute = functions.https.onRequest(async (request, response) => {
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
  console.log(`##### Incoming route: ${JSON.stringify(request.body.route)}`);

  const route = request.body.route;
  if (!route) {
    const msg = "missing route";
    console.error(msg);
    return response.status(400).send(msg);
  }

  await writeRoute();
  return null;

  async function writeRoute() {
    console.log("############## writeRoute");
    try {
      if (!route.routeID) {
        route.routeID = uuid();
      }
      const qs0 = await fs
        .collection(constants.Constants.FS_ROUTES)
        .where("associationID", "==", route.associationID)
        .where("name", "==", route.name)
        .get();
      if (qs0.docs.length > 0) {
        const msg = `Route already exists: ${route.name}`;
        console.error(msg);
        return response.status(201).send(route);
      }
      const ref = await fs.collection(constants.Constants.FS_ROUTES).add(route);
      route.path = ref.path;
      await ref.set(route);

      console.log(`*** route written to Firestore ${route.path}`);
      return response.status(200).send(route);
    } catch (e) {
      console.error(e);
      return response.status(400).send(e);
    }
  }
});
