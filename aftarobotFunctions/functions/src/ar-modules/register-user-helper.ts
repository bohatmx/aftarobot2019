import * as admin from "firebase-admin";
import * as constants from "../models/constants";
import { UserDTO } from '../models/aftarobot';
const uuid = require("uuid/v1");

export class UserHelper {
  static async writeUser(user, userRecord) {
    const fs = admin.firestore();
    console.log(`UserHelper ... Start Helping ... add user`);
    const mUser: UserDTO = new UserDTO();
    mUser.instance(user);
    let aUserRec;
    if (!userRecord) {
      aUserRec = await createAuthUser();
    } else {
      aUserRec = userRecord
    }
    const resultUser = await writeUser()
    return resultUser;

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
        const msg = "Error creating new Firebase auth user:";
        throw new Error(msg);
      }
    }
    async function writeUser() {
      try {
        const userData = mUser.toFirestoreMap();
        userData.uid = aUserRec.uid;
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
        throw e;
      }
      return null;
    }
    async function finishUp(userData, ref) {
      console.log(`user added to Firestore: ${ref.path}`);
      userData.path = ref.path;
      await ref.set(userData);
      console.log(`user updated with path ${ref.path}`);
      return await sendMessageToTopic();
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
}
