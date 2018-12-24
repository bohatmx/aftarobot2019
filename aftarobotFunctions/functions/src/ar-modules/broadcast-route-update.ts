// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AdminDTO } from "../models/aftarobot";

export const broadcastRouteUpdate = functions.https.onRequest(
  async (request, response) => {
    if (!request.body) {
      console.log("ERROR - request has no body");
      return response.sendStatus(400);
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
