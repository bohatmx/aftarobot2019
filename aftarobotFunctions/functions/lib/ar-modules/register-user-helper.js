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
const aftarobot_1 = require("../models/aftarobot");
const uuid = require("uuid/v1");
class UserHelper {
    static writeUser(user, userRecord) {
        return __awaiter(this, void 0, void 0, function* () {
            const fs = admin.firestore();
            const mUser = new aftarobot_1.UserDTO();
            mUser.instance(user);
            let aUserRec;
            if (!userRecord) {
                aUserRec = yield createAuthUser();
            }
            else {
                aUserRec = userRecord;
            }
            const resultUser = yield writeUser();
            return resultUser;
            function createAuthUser() {
                return __awaiter(this, void 0, void 0, function* () {
                    try {
                        const ur = yield admin.auth().createUser({
                            email: user.email,
                            emailVerified: false,
                            password: user.password,
                            displayName: user.name,
                            disabled: false
                        });
                        console.log("Successfully created new user:", ur.uid);
                        return ur;
                    }
                    catch (e) {
                        const msg = "Error creating new Firebase auth user:";
                        throw new Error(msg);
                    }
                });
            }
            function writeUser() {
                return __awaiter(this, void 0, void 0, function* () {
                    try {
                        const userData = mUser.toFirestoreMap();
                        userData.uid = aUserRec.uid;
                        userData.userID = uuid();
                        if (userData.associationID) {
                            const qs = yield fs
                                .collection(constants.Constants.FS_ASSOCIATIONS)
                                .where("associationID", "==", userData.associationID)
                                .get();
                            if (qs.docs.length === 0) {
                                const msg = "Association does not exist";
                                console.error(msg);
                                throw new Error(msg);
                            }
                            const ref = yield qs.docs[0].ref
                                .collection(constants.Constants.FS_USERS)
                                .add(userData);
                            return finishUp(userData, ref);
                        }
                        else {
                            if (userData.userType === constants.Constants.COMMUTER) {
                                const ref = yield fs
                                    .collection(constants.Constants.FS_COMMUTERS)
                                    .add(userData);
                                return finishUp(userData, ref);
                            }
                            else {
                                if (userData.userType === constants.Constants.AFTAROBOT_STAFF) {
                                    const ref = yield fs
                                        .collection(constants.Constants.FS_STAFF)
                                        .add(userData);
                                    return finishUp(userData, ref);
                                }
                            }
                        }
                    }
                    catch (e) {
                        console.log(e);
                        throw e;
                    }
                    return null;
                });
            }
            function finishUp(userData, ref) {
                return __awaiter(this, void 0, void 0, function* () {
                    userData.path = ref.path;
                    yield ref.set(userData);
                    console.log(`user updated with path ${ref.path}`);
                    yield sendMessageToTopic();
                    return userData;
                });
            }
            function sendMessageToTopic() {
                return __awaiter(this, void 0, void 0, function* () {
                    const topic = "usersAdded";
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
        });
    }
}
exports.UserHelper = UserHelper;
//# sourceMappingURL=register-user-helper.js.map