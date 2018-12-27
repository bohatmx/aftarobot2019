// ######################################################################
// Add cities to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { CityHelper } from './city-helper';

export const addCities = functions.https.onRequest(
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

    console.log(`##### Incoming body; ${request.body}`);
    console.log(
      `##### Incoming cities: ${JSON.stringify(request.body.cities)}`
    );

    const cities = request.body.cities;
    if (!cities) {
      const msg = "missing cities";
      console.error(msg);
      return response.status(400).send(msg);
    }

    await writeCities();
    return null;

    async function writeCities() {
      const results = [];
      try {
        for (const city of cities) {
          const result = await CityHelper.writeCity(city)
          results.push(result);
        }
        return response.status(200).send(results);
      } catch (e) {
        console.error(e);
        return response.status(400).send(e);
      }
    }
  }
);
