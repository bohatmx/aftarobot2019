"use strict";
// ######################################################################
// Accept Invoice to BFN and Firestore
// ######################################################################
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const aftarobot_1 = require("../models/aftarobot");
const uuid = require("uuid/v1");
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation
exports.addAssociation = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    if (!request.body.data.association) {
        console.log("ERROR - request has no association");
        return response
            .status(400)
            .send("Request has no association json object");
    }
    if (!request.body.data.administrator) {
        console.log("ERROR - request has no administrator");
        return response
            .status(400)
            .send("Request has no administrator json object");
    }
    try {
        const firestore = admin.firestore();
        const settings = { /* your settings... */ timestampsInSnapshots: true };
        firestore.settings(settings);
    }
    catch (e) {
        console.log(e);
    }
    console.log(`##### Incoming administrator ${request.body.administrator}`);
    console.log(`##### Incoming association ${JSON.stringify(request.body.association)}`);
    const administrator = new aftarobot_1.AdminDTO();
    administrator.instance(request.body.administrator);
    const association = new aftarobot_1.AssociationDTO();
    association.instance(request.body.association);
    const fs = admin.firestore();
    yield writeAssociation();
    return null;
    function writeAssociation() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log("writeToFirestore");
            try {
                const ref = yield fs.collection('associations').add(association);
                association.path = ref.path;
                yield ref.set(association);
                console.log(`association added to Firestore`);
                const ref2 = yield ref.collection('administrators').add(administrator);
                administrator.path = ref2.path;
                yield ref2.set(administrator);
                console.log(`administrator added to Firestore`);
                yield sendMessageToTopic();
                const result = {
                    association: association,
                    administrator: administrator
                };
                return response.status(200).send(result);
            }
            catch (e) {
                console.log(e);
                response.status(400).send(e);
                return null;
            }
        });
    }
    function sendMessageToTopic() {
        return __awaiter(this, void 0, void 0, function* () {
            const topic = 'associationsAdded';
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
                yield admin.messaging().sendToTopic(topic, payload);
            }
            catch (e) {
                console.error(e);
            }
            return null;
        });
    }
}));
//# sourceMappingURL=add-association.js.map