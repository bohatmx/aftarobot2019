// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

import { AdminDTO, AssociationDTO, UserDTO } from "../models/aftarobot";
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

    const user: UserDTO = new UserDTO();
    user.instance(request.body.user);
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
          email: user.email,
          emailVerified: false,
          phoneNumber: user.cellphone,
          password: user.password,
          displayName: user.name,
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
        if (!assocData.associationID) {
          assocData.associationID = uuid();
        }
        const qs = await fs
          .collection(constants.Constants.FS_ASSOCIATIONS)
          .where("associationName", "==", association.associationName)
          .get();
        if (qs.docs.length === 0) {
          const msg = "Association already exists";
          console.error(msg);
          throw new Error(msg);
        }
        const ref = await fs
          .collection(constants.Constants.FS_ASSOCIATIONS)
          .add(assocData);
        console.log(`association added to Firestore: ${ref.path}`);

        assocData.path = ref.path;
        await ref.set(assocData);
        console.log(`association updated with path ${ref.path}`);

        const adminData = user.toFirestoreMap();
        adminData.uid = userRecord.uid;
        adminData.userID = uuid();
        adminData.associationID = assocData.associationID;
        adminData.userType = constants.Constants.ASSOC_ADMIN;
        adminData.userDescription = constants.Constants.ASSOC_ADMIN_DESC;

        const ref2 = await ref
          .collection(constants.Constants.FS_USERS)
          .add(adminData);
        console.log(`user added to Firestore ${ref2.path}`);

        adminData.path = ref2.path;
        await ref2.set(adminData);
        console.log(`user added to Firestore`);

        await sendMessageToTopic();
        const result = {
          association: assocData,
          user: adminData
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
