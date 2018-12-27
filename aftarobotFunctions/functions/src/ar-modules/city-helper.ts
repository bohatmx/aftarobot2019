import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export class CityHelper {
  static async writeCity(city) {
    const fs = admin.firestore();
    try {
      const qs = await fs.doc(city.countryPath).collection('cities')
        .where('name', '==', city.name).get()
      if (qs.docs.length > 0) {
        console.error(`City seems to be a duplicate: ${city}`)
        return city;
      }
      city.cityID = uuid();
      const ref = await fs
        .doc(city.countryPath)
        .collection(constants.Constants.FS_CITIES)
        .add(city);
      city.path = ref.path;
      await ref.set(city);
      console.log(`city written to Firestore ${ref.path}`);
      return city;
    } catch (e) {
      console.error(e);
      throw e;
    }
  }
}
