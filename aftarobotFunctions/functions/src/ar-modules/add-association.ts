// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

import { AssociationDTO, UserDTO } from "../models/aftarobot";
import { AssociationHelper } from "./association-helper";
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation

export const addAssociation = functions.https.onRequest(
  async (request, response) => {
    console.log(request.body);
    if (!request.body.association) {
      console.log("ERROR - request has no association");
      return response
        .status(400)
        .send("Request has no association json object");
    }
    if (!request.body.user) {
      console.log("ERROR - request has no user");
      return response.status(400).send("Request has no user json object");
    }
    const fs = admin.firestore();
    try {
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      fs.settings(settings);
    } catch (e) {}

    console.log(`##### Incoming user ${JSON.stringify(request.body.user)}`);
    console.log(
      `##### Incoming association ${JSON.stringify(request.body.association)}`
    );
    const incomingUserRecord = request.body.userRecord; //will be present if user already authenticated, ie, via Google means ...
    await writeAssociation();
    return null;

    async function writeAssociation() {
      console.log(`starting to write associations`);
      try {
        const result = await AssociationHelper.writeAssociation(
          request.body.association,
          request.body.user,
          request.body.userRecord
        );
        response.status(200).send(result);
      } catch (e) {
        console.log(`Problem writing associations`);
        return response.status(400).send(`Problems, Harry, problems!! ${e}`);
      }
      return null;
    }
  }
);
