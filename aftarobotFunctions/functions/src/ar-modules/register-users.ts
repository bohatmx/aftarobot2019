// ######################################################################
// Add Users to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { UserHelper } from "./register-user-helper";
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation

export const registerUsers = functions.https.onRequest(
  async (request, response) => {
    console.log(request.body);
    if (!request.body.users) {
      console.log("ERROR - request has no users");
      return response.status(400).send("Request has no users json object");
    }

    const fs = admin.firestore();
    try {
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      fs.settings(settings);
    } catch (e) {}

    console.log(`##### Incoming users ${JSON.stringify(request.body.users)}`);
    const users = request.body.users
    const resultUsers = []
    try {
      for (const user of users) {
        const result = await UserHelper.writeUser(
          user,
          null
        );
        resultUsers.push(result);
      }
      response.status(200).send(resultUsers);
    } catch (e) {
      response.status(400).send(`Unable to add users ${e}`);
    }
    return null;
  }
);
