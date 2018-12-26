"use strict";
// ######################################################################
// Add Vehicle to Firestore or not!
// ######################################################################
//curl --header "Content-Type: application/json"   --request POST   --data '{"auth": "tigerKills","debug":"true"}'  https://us-central1-aftarobot2019-dev1.cloudfunctions.net/checkLogs
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
exports.checkLogs = functions.https.onRequest((request, response) => __awaiter(this, void 0, void 0, function* () {
    const fs = admin.auth();
    console.log(`##### Starting auth user delete`);
    const debug = request.body.debug;
    const secret = request.body.auth;
    console.log(`incoming debug: ${debug}`);
    console.log(`incoming secret: ${secret}`);
    if (debug) {
        yield findAuth();
    }
    else {
        return response.status(400).send("You are not authorized, Fool!");
    }
    return null;
    function findAuth() {
        return __awaiter(this, void 0, void 0, function* () {
            if (secret) {
                if (secret === "tigerKills") {
                    return yield reallyCheckLogs();
                }
            }
            else {
                return response
                    .status(400)
                    .send("Failed miserably! you are not allowed in here, child!");
            }
            return null;
        });
    }
    function reallyCheckLogs() {
        return __awaiter(this, void 0, void 0, function* () {
            let count = 0;
            try {
                const listResult = yield fs.listUsers(300);
                for (const userRecord of listResult.users) {
                    console.log(`User found: ${userRecord.displayName} ${userRecord.phoneNumber}`);
                    yield fs.deleteUser(userRecord.uid);
                    count++;
                    console.log(`Auth user deleted: #${count} ${userRecord.uid} - ${userRecord.email}`);
                }
                console.log(`... are we done here now? ... taking forever!!`);
                return response
                    .status(200)
                    .send(`\n\n########### ${count} Auth users deleted.\n\n`);
            }
            catch (e) {
                console.log(e);
                return response.status(400).send(e);
            }
        });
    }
}));
//# sourceMappingURL=check-logs.js.map