// ######################################################################
// Add User to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");
import { AdminDTO, AssociationDTO, UserDTO } from "../models/aftarobot";
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation

export const registerUser = functions.https.onRequest(
  async (request, response) => {
    console.log(request.body);
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

    const user: UserDTO = new UserDTO();
    let userRecord;
    user.instance(request.body.user);
    user.userID = uuid();

    if (request.body.userRecord) {
      userRecord = request.body.userRecord;
    } else {
      userRecord = await createAuthUser();
    }

    await writeUser();
    return null;

    async function createAuthUser() {
      try {
        const ur = await admin.auth().createUser({
          email: user.email,
          emailVerified: false,
          // phoneNumber: user.cellphone,
          password: user.password,
          displayName: user.name,
          disabled: false
        });
        console.log("Successfully created new user:", ur.uid);
        return ur;
      } catch (e) {
        console.error("Error creating new Firebase auth user:", e);
        throw e;
      }
    }
    async function writeUser() {
      try {
        const userData = user.toFirestoreMap();
        userData.uid = userRecord.uid;
        userData.userID = uuid();
        if (userData.associationID) {
          const qs = await fs
            .collection(constants.Constants.FS_ASSOCIATIONS)
            .where("associationID", "==", userData.associationID)
            .get();
          if (qs.docs.length === 0) {
            const msg = "Association does not exist";
            console.error(msg);
            throw new Error(msg);
          }
          const ref = await qs.docs[0].ref
            .collection(constants.Constants.FS_USERS)
            .add(userData);
          return finishUp(userData, ref);
        } else {
          if (userData.userType === constants.Constants.COMMUTER) {
            const ref = await fs
              .collection(constants.Constants.FS_COMMUTERS)
              .add(userData);
            return finishUp(userData, ref);
          } else {
            if (userData.userType === constants.Constants.AFTAROBOT_STAFF) {
              const ref = await fs
                .collection(constants.Constants.FS_STAFF)
                .add(userData);
              return finishUp(userData, ref);
            }
          }
        }
      } catch (e) {
        console.log(e);
        response.status(400).send(e);
      }
      return null;
    }
    async function finishUp(userData, ref) {
      console.log(`user added to Firestore: ${ref.path}`);
      userData.path = ref.path;
      await ref.set(userData);
      console.log(`user updated with path ${ref.path}`);
      await sendMessageToTopic();
      return response.status(200).send(userData);
    }
    async function sendMessageToTopic() {
      const topic = "usersAdded";
      console.log(`...sending message to topic ${topic}`);
      const payload = {
        data: {
          messageType: "USER_ADDED",
          json: JSON.stringify(user)
        },
        notification: {
          title: "User Added",
          body: `${user.name} - ${user.email}`
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
