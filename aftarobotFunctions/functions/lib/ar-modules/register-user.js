"use strict";
// ######################################################################
// Add User to Firestore
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
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation
exports.registerUser = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
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
    }
    catch (e) { }
    console.log(`##### Incoming user ${JSON.stringify(request.body.user)}`);
    ;
    const user = new aftarobot_1.UserDTO();
    let userRecord;
    user.instance(request.body.user);
    if (request.body.userRecord) {
        userRecord = request.body.userRecord;
    }
    else {
        userRecord = yield createAuthUser();
    }
    yield writeUser();
    return null;
    function createAuthUser() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const ur = yield admin.auth().createUser({
                    email: user.email,
                    emailVerified: false,
                    phoneNumber: user.cellphone,
                    password: user.password,
                    displayName: user.name,
                    disabled: false
                });
                console.log("Successfully created new user:", ur.uid);
                return ur;
            }
            catch (e) {
                console.log("Error creating new user:", e);
                throw e;
            }
        });
    }
    function writeUser() {
        return __awaiter(this, void 0, void 0, function* () {
            try {
                const userData = user.toFirestoreMap();
                userData.uid = userRecord.uid;
                const ref = yield fs.collection("users").add(userData);
                console.log(`user added to Firestore: ${ref.path}`);
                userData.path = ref.path;
                yield ref.set(userData);
                console.log(`user updated with path ${ref.path}`);
                yield sendMessageToTopic();
                return response.status(200).send(userData);
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
                yield admin.messaging().sendToTopic(topic, payload);
            }
            catch (e) {
                console.error(e);
            }
            return null;
        });
    }
}));
//# sourceMappingURL=register-user.js.map