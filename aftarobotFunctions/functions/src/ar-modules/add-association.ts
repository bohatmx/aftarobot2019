// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from '../models/constants'
const uuid = require("uuid/v1");

import { AdminDTO, AssociationDTO } from "../models/aftarobot";
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
    if (!request.body.administrator) {
      console.log("ERROR - request has no administrator");
      return response
        .status(400)
        .send("Request has no administrator json object");
    }
    const fs = admin.firestore();
    try {
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      fs.settings(settings);
    } catch (e) {}

    console.log(
      `##### Incoming administrator ${JSON.stringify(
        request.body.administrator
      )}`
    );
    console.log(
      `##### Incoming association ${JSON.stringify(request.body.association)}`
    );

    const administrator: AdminDTO = new AdminDTO();
    administrator.instance(request.body.administrator);
    const association: AssociationDTO = new AssociationDTO();
    association.instance(request.body.association);
    const incomingUserRecord = request.body.userRecord; //will be present if user already authenticated, ie, via Google means ...

    let userRecord;
    if (incomingUserRecord) {
      userRecord = incomingUserRecord;
    } else {
      userRecord = await createAuthUser();
    }

    await writeAssociation();
    return null;

    async function createAuthUser() {
      try {
        const ur = await admin.auth().createUser({
          email: administrator.email,
          emailVerified: false,
          phoneNumber: administrator.phone,
          password: administrator.password,
          displayName: administrator.name,
          disabled: false
        });
        console.log("Successfully created new user:", ur.uid);
        return ur;
      } catch (e) {
        console.error("Error creating new user:", e);
        throw e;
      }
    }
    async function writeAssociation() {
      try {
        const assocData = association.toFirestoreMap();
        assocData.associationID = uuid()
        const qs = await fs
          .collection(constants.Constants.FS_ASSOCIATIONS)
          .where("associationName", "==", association.associationName)
          .get();
        if (qs.docs.length === 0) {
          const msg = "Association already exists";
          console.error(msg);
          throw new Error(msg)
        }
        const ref = await fs
          .collection(constants.Constants.FS_ASSOCIATIONS)
          .add(assocData);
        console.log(`association added to Firestore: ${ref.path}`);

        assocData.path = ref.path;
        await ref.set(assocData);
        console.log(`association updated with path ${ref.path}`);

        const adminData = administrator.toFirestoreMap();
        adminData.uid = userRecord.uid;
        const ref2 = await ref.collection(constants.Constants.FS_ADMINISTRATORS).add(adminData);
        console.log(`administrator added to Firestore ${ref2.path}`);

        adminData.path = ref2.path;
        await ref2.set(adminData);
        console.log(`administrator added to Firestore`);

        await sendMessageToTopic();
        const result = {
          association: assocData,
          administrator: adminData,
        };
        return response.status(200).send(result);
      } catch (e) {
        console.log(e);
        response.status(400).send(e);
        return null;
      }
    }
    async function sendMessageToTopic() {
      const topic = "associationsAdded";
      console.log(`...sending message to topic ${topic}`);
      const payload = {
        data: {
          messageType: "ASSOCIATION_ADDED",
          json: JSON.stringify(association)
        },
        notification: {
          title: "Association Added",
          body: `${association.associationName}`
        }
      };

      console.log("sending data to topic: " + topic);
      try {
        await admin.messaging().sendToTopic(topic, payload);
      } catch (e) {
        console.error(e);
      }
      return null;
    }
  }
);
