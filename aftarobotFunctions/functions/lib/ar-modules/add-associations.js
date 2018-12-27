"use strict";
// ######################################################################
// Aad Associations to BFN and Firestore
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
const association_helper_1 = require("./association-helper");
//curl --header "Content-Type: application/json"   --request POST   --data '{"adminID": "32a26a20-bd30-11e8-84f5-63a97aaac795","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/addAssociation
exports.addAssociations = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    console.log(request.body);
    if (!request.body.associations) {
        console.log("ERROR - request has no associations");
        return response
            .status(400)
            .send("Request has no associations json object");
    }
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
    console.log(`##### Incoming associations ${JSON.stringify(request.body.associations)}`);
    const users = request.body.users;
    const assocs = request.body.associations;
    yield writeAssociations();
    return null;
    function writeAssociations() {
        return __awaiter(this, void 0, void 0, function* () {
            console.log(`starting to write associations`);
            const results = [];
            let index = 0;
            try {
                for (const assoc of assocs) {
                    const result = yield association_helper_1.AssociationHelper.writeAssociation(assoc, users[index], null);
                    index++;
                    results.push(result);
                    console.log(results);
                }
                response.status(200).send(results);
            }
            catch (e) {
                console.log(`Problem writing associations: ${e}`);
                return response.status(400).send(`Problems, Harry, problems!! `);
            }
            return null;
        });
    }
}));
//# sourceMappingURL=add-associations.js.map