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
const register_user_helper_1 = require("./register-user-helper");
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation
exports.registerUser = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    console.log(request.body);
    if (!request.body.user) {
        console.log("ERROR - request has no user");
        return response.status(400).send("Request has no user json object");
    }
    const fs = admin.firestore();
    try {
        const settings = { /* your settings... */ timestampsInSnapshots: true };
        fs.settings(settings);
    }
    catch (e) { }
    console.log(`##### Incoming user ${JSON.stringify(request.body.user)}`);
    console.log(`##### Incoming Firebase Auth userRecord ${JSON.stringify(request.body.userRecord)}`);
    try {
        const result = yield register_user_helper_1.UserHelper.writeUser(request.body.user, request.body.userRecord);
        response.status(200).send(result);
    }
    catch (e) {
        response.status(400).send(`Unable to add user ${e}`);
    }
    return null;
}));
//# sourceMappingURL=register-user.js.map