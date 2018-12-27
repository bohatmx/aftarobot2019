import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export class CountryHelper {
  static async writeCountry(country) {
    const fs = admin.firestore();
    console.log(`CountryHelper ... Start Helping ... add country`);
    try {
      country.countryID = uuid();
      const qs0 = await fs
        .collection(constants.Constants.FS_COUNTRIES)
        .where("name", "==", country.name)
        .get();
      if (qs0.docs.length > 0) {
        const msg = `Country already exists: ${country.name}`;
        console.error(msg);
        throw new Error(msg);
      }

      const ref = await fs
        .collection(constants.Constants.FS_COUNTRIES)
        .add(country);
      country.path = ref.path;
      await ref.set(country);
      console.log(`country written to Firestore ${ref.path}`);
      return country;
    } catch (e) {
      console.error(e);
      throw e;
    }
  }
}
