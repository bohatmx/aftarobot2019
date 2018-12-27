import * as admin from "firebase-admin";
import * as constants from "../models/constants";
const uuid = require("uuid/v1");

export class AssociationHelper {
  static async writeAssociation(association, user, incomingUserRecord) {
    const fs = admin.firestore();
    console.log(`AssociationHelper ... Start Helping ... add association`);

    let userRecord;
    if (incomingUserRecord) {
      userRecord = incomingUserRecord;
    } else {
      userRecord = await createAuthUser();
    }
    const result = await writeAssociation();
    return result;

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
        const msg = "Error creating new Firebase auth user";
        console.error(msg);
        throw new Error(msg);
      }
    }
    async function writeAssociation() {
      try {
        const assocData = association;
        if (!assocData.associationID) {
          assocData.associationID = uuid();
        }
        const qs = await fs
          .collection(constants.Constants.FS_ASSOCIATIONS)
          .where("associationName", "==", association.associationName)
          .get();
        if (qs.docs.length > 0) {
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

        const adminData = user;
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
        const data = { association: assocData, user: adminData };
        console.log(`result in helper, returnning: ${data}`);
        return data;
      } catch (e) {
        console.log(e);
        throw e;
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
}
