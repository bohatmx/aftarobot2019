// ######################################################################
// Add User to Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AdminDTO, AssociationDTO, UserDTO } from '../models/aftarobot';
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation

export const registerUser = functions.https.onRequest(
  async (request, response) => {
    console.log(request.body);
    if (!request.body.user) {
      console.log("ERROR - request has no user");
      return response
        .status(400)
        .send("Request has no user json object");
    }
    
    const fs = admin.firestore();
    try {
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      fs.settings(settings);
    } catch (e) {}

    console.log(
      `##### Incoming user ${JSON.stringify(
        request.body.user
      )}`
    );

    ;
    const user: UserDTO = new UserDTO()
    let userRecord
    user.instance(request.body.user)

    if (request.body.userRecord) {
      userRecord = request.body.userRecord
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
          phoneNumber: user.cellphone,
          password: user.password,
          displayName: user.name,
          disabled: false
        });
        console.log("Successfully created new user:", ur.uid);
        return ur;
      } catch (e) {
        console.log("Error creating new user:", e);
        throw e;
      }
    }
    async function writeUser() {
      try {
        const userData = user.toFirestoreMap();
        userData.uid = userRecord.uid
        const ref = await fs.collection("users").add(userData);
        console.log(`user added to Firestore: ${ref.path}`);

        userData.path = ref.path;
        await ref.set(userData);
        console.log(`user updated with path ${ref.path}`);
        await sendMessageToTopic();
        return response.status(200).send(userData);
      } catch (e) {
        console.log(e);
        response.status(400).send(e);
        return null;
      }
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
