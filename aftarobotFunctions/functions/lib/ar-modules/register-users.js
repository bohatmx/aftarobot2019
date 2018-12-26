"use strict";
// ######################################################################
// Add Users to Firestore
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
exports.registerUsers = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    console.log(request.body);
    if (!request.body.users) {
        console.log("ERROR - request has no users");
        return response.status(400).send("Request has no users json object");
    }
    const fs = admin.firestore();
    try {
        const settings = { /* your settings... */ timestampsInSnapshots: true };
        fs.settings(settings);
    }
    catch (e) { }
    console.log(`##### Incoming users ${JSON.stringify(request.body.users)}`);
    const users = request.body.users;
    const resultUsers = [];
    try {
        for (const user of users) {
            const result = yield register_user_helper_1.UserHelper.writeUser(user, null);
            resultUsers.push(result);
        }
        response.status(200).send(resultUsers);
    }
    catch (e) {
        response.status(400).send(`Unable to add users ${e}`);
    }
    return null;
}));
//# sourceMappingURL=register-users.js.map