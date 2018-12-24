// ######################################################################
// Add Country to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export const addCountry = functions.https.onRequest(
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
      `##### Incoming country: ${JSON.stringify(request.body.country)}`
    );

    const country = request.body.country;
    if (!country) {
      const msg = "missing country";
      console.error(msg);
      return response.status(400).send(msg);
    }

    await writeCountry();
    return null;

    async function writeCountry() {
      try {
        country.countryID = uuid();
        const qs0 = await fs
          .collection(constants.Constants.FS_COUNTRIES)
          .where("countryName", "==", country.countryName)
          .get();
        if (qs0.docs.length > 0) {
          const msg = `country already exists: ${country.countryName}`;
          console.error(msg);
          throw new Error(msg);
        }

        const ref = await fs
          .collection(constants.Constants.FS_COUNTRIES)
          .add(country);
        country.path = ref.path;
        await ref.set(country);

        console.log(`country written to Firestore ${ref.path}`);
        return response.status(200).send(country);
      } catch (e) {
        console.error(e);
        return response.status(400).send(e);
      }
    }
  }
);
