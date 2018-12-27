"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const admin = require("firebase-admin");
const constants = require("../models/constants");
const uuid = require("uuid/v1");
class AssociationHelper {
    static writeAssociation(association, user, incomingUserRecord) {
        return __awaiter(this, void 0, void 0, function* () {
            const fs = admin.firestore();
            console.log(`AssociationHelper ... Start Helping ... add association`);
            let userRecord;
            if (incomingUserRecord) {
                userRecord = incomingUserRecord;
            }
            else {
                userRecord = yield createAuthUser();
            }
            const result = yield writeAssociation();
            return result;
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
                        const msg = "Error creating new Firebase auth user";
                        console.error(msg);
                        throw new Error(msg);
                    }
                });
            }
            function writeAssociation() {
                return __awaiter(this, void 0, void 0, function* () {
                    try {
                        const assocData = association;
                        if (!assocData.associationID) {
                            assocData.associationID = uuid();
                        }
                        const qs = yield fs
                            .collection(constants.Constants.FS_ASSOCIATIONS)
                            .where("associationName", "==", association.associationName)
                            .get();
                        if (qs.docs.length > 0) {
                            const msg = "Association already exists";
                            console.error(msg);
                            throw new Error(msg);
                        }
                        const ref = yield fs
                            .collection(constants.Constants.FS_ASSOCIATIONS)
                            .add(assocData);
                        console.log(`association added to Firestore: ${ref.path}`);
                        assocData.path = ref.path;
                        yield ref.set(assocData);
                        console.log(`association updated with path ${ref.path}`);
                        const adminData = user;
                        adminData.uid = userRecord.uid;
                        adminData.userID = uuid();
                        adminData.associationID = assocData.associationID;
                        adminData.userType = constants.Constants.ASSOC_ADMIN;
                        adminData.userDescription = constants.Constants.ASSOC_ADMIN_DESC;
                        const ref2 = yield ref
                            .collection(constants.Constants.FS_USERS)
                            .add(adminData);
                        console.log(`user added to Firestore ${ref2.path}`);
                        adminData.path = ref2.path;
                        yield ref2.set(adminData);
                        console.log(`user added to Firestore`);
                        yield sendMessageToTopic();
                        const data = { association: assocData, user: adminData };
                        console.log(`result in helper, returnning: ${data}`);
                        return data;
                    }
                    catch (e) {
                        console.log(e);
                        throw e;
                    }
                });
            }
            function sendMessageToTopic() {
                return __awaiter(this, void 0, void 0, function* () {
                    const topic = "associationsAdded";
                    console.log(`...sending message to topic ${topic}`);
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
        });
    }
}
exports.AssociationHelper = AssociationHelper;
//# sourceMappingURL=association-helper.js.map