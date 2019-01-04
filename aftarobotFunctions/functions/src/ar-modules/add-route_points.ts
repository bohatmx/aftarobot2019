// ######################################################################
// Add Route points to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const addRoutePoints = functions.https.onRequest(
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

    const locations = request.body.locations;
    const routePath = request.body.routePath;
    if (!locations || !routePath) {
      response.status(400).send(`Missing snapped locations or routePath`);
    } else {
      await writePoints();
    }
    return null;

    async function writePoints() {
      console.log(`adding ${locations.length} location points to Firestore`);
      let ref;
      ref = await fs.doc(routePath).get();
      const results = [];
      try {
        for (const location of locations) {
          const result = await ref.("snappedPoints").add(location);
          results.push(result);
        }
        console.log(
          `${
            locations.length
          } batched snapped locations added to Firestore. complete. cool.`
        );
        return response.status(200).send(results);
      } catch (e) {
        console.log(e);
        return response.status(400).send(e);
      }
    }
  }
);
