// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AdminDTO, AssociationDTO } from "../models/aftarobot";
const uuid = require("uuid/v1");
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation

export const addAssociation = functions.https.onRequest(
  async (request, response) => {
    if (!request.body.data.association) {
      console.log("ERROR - request has no association");
      return response
        .status(400)
        .send(
          "Request has no association json object"
        );
    }
    if (!request.body.data.administrator) {
      console.log("ERROR - request has no administrator");
      return response
        .status(400)
        .send(
          "Request has no administrator json object"
        );
    }

    try {
      const firestore = admin.firestore();
      const settings = { /* your settings... */ timestampsInSnapshots: true };
      firestore.settings(settings);
    } catch (e) {
      console.log(e);
    }

    console.log(`##### Incoming administrator ${request.body.administrator}`);
    console.log(
      `##### Incoming association ${JSON.stringify(request.body.association)}`
    );

    const administrator: AdminDTO = new AdminDTO();
    administrator.instance(request.body.administrator);
    const association: AssociationDTO = new AssociationDTO();
    association.instance(request.body.association);

    const fs = admin.firestore();

    await writeAssociation();
    return null;

    async function writeAssociation() {
      console.log("writeToFirestore");
      try {
        const ref = await fs.collection('associations').add(association);
        association.path = ref.path
        await ref.set(association)
        console.log(`association added to Firestore`)
        const ref2 = await ref.collection('administrators').add(administrator);
        administrator.path = ref2.path
        await ref2.set(administrator)
        console.log(`administrator added to Firestore`)
        await sendMessageToTopic()
        const result = {
          association: association,
          administrator: administrator
        }
        return response.status(200).send(result);
      } catch (e) {
        console.log(e);
        response.status(400).send(e);
        return null;
      }
    }
    async function sendMessageToTopic() {
      const topic = 'associationsAdded'
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

      console.log(
        "sending data to topic: " + topic);
      try {
        await admin.messaging().sendToTopic(topic,payload);
      } catch (e) {
        console.error(e);
      }
      return null;
    }

  }
);
