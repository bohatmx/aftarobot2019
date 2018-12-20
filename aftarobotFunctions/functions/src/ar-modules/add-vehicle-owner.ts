// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const addVehicleOwner = functions.https.onRequest(
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

    // const debug = request.body.debug;
    // const data = request.body.data;
    // const fs = admin.firestore()
    // const apiSuffix = "AcceptInvoice";

    return null;
   
  }
);
