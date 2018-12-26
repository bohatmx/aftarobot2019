// ######################################################################
// Add Vehicle to Firestore or not!
// ######################################################################
//curl --header "Content-Type: application/json"   --request POST   --data '{"auth": "tigerKills","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/checkLogs

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const checkLogs = functions.https.onRequest(
  async (request, response) => {
    const fs = admin.auth();
    console.log(`##### Starting auth user delete`);
    const debug = request.body.debug;
    const secret = request.body.auth;
    if (debug === true) {
      await findAuth();
    } else {
      return response.status(400).send("You are not authorized, Fool!");
    }
    return null;

    async function findAuth() {
      if (secret) {
        if (secret === "tigerKills") {
          return await reallyCheckLogs();
        }
      } else {
        return response
          .status(400)
          .send("Failed miserably! you are not allowed in here, child!");
      }
      return null;
    }
    async function reallyCheckLogs() {
      let count = 0;
      try {
        const listResult = await fs.listUsers(300);
        for (const userRecord of listResult.users) {
          console.log(
            `User found: ${userRecord.displayName} ${userRecord.phoneNumber}`
          );
          await fs.deleteUser(userRecord.uid);
          count++;
          console.log(
            `Auth user deleted: #${count} ${userRecord.uid} - ${
              userRecord.email
            }`
          );
        }
        return response
          .status(200)
          .send(`\n\n########### ${count} Auth users deleted.\n\n`);
      } catch (e) {
        console.log(e);
        return response.status(400).send(e);
      }
    }
  }
);
