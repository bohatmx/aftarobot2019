// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
const uuid = require("uuid/v1");

export const addVehicle = functions.https.onRequest(
  async (request, response) => {
    if (!request.body) {
      console.log("ERROR - request has no body");
      return response.sendStatus(400);
    }
    
    try {
      const firestore = admin.firestore();
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      firestore.settings(settings);
      console.log(
        "Firebase settings completed. Should be free of annoying messages from Google"
      );
    } catch (e) {
      console.log(e);
    }


    console.log(`##### Incoming debug ${request.body.debug}`);
    console.log(`##### Incoming data ${JSON.stringify(request.body.data)}`);

    const debug = request.body.debug;
    const data = request.body.data;
    const fs = admin.firestore()
    const apiSuffix = "AcceptInvoice";

    if (validate()) {
      await writeToBFN();
    }

    return null;
    function validate() {
      if (!request.body) {
        console.log("ERROR - request has no body");
        return response.status(400).send("request has no body");
      }
      if (!request.body.debug) {
        console.log("ERROR - request has no debug flag");
        return response.status(400).send(" request has no debug flag");
      }
      if (!request.body.data) {
        console.log("ERROR - request has no data");
        return response.status(400).send(" request has no data");
      }
      return true;
    }
    async function writeToBFN() {
      console.log('')
    }

    async function writeToFirestore(mdata) {
      console.log('')
    }
    async function sendMessageToTopic(mdata) {
      console.log('')
    }


    function handleError(message) {
      console.error("--- ERROR !!! --- sending error payload: msg:" + message);
      throw new Error(message)
    }
  }
);
