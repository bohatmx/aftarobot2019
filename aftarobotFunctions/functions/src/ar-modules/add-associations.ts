// ######################################################################
// Aad Associations to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AssociationHelper } from "./association-helper";
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation

export const addAssociations = functions.https.onRequest(
  async (request, response) => {
    console.log(request.body);
    if (!request.body.associations) {
      console.log("ERROR - request has no associations");
      return response
        .status(400)
        .send("Request has no associations json object");
    }
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
    console.log(
      `##### Incoming associations ${JSON.stringify(request.body.associations)}`
    );

    const users = request.body.users;
    const assocs = request.body.associations;

    await writeAssociations();
    return null;

    async function writeAssociations() {
      console.log(`starting to write associations`);
      const results = [];
      let index = 0;
      try {
        for (const assoc of assocs) {
          const result = await AssociationHelper.writeAssociation(
            assoc,
            users[index],
            null
          );
          index++;
          results.push(result);
          console.log(results);
        }
        response.status(200).send(results);
      } catch (e) {
        console.log(`Problem writing associations: ${e}`);
        return response.status(400).send(`Problems, Harry, problems!! `);
      }
      return null;
    }
  }
);
