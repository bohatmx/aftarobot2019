"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const admin = require("firebase-admin");
const AddAssociation = require("./ar-modules/add-association");
const AddOwner = require("./ar-modules/add-owner");
const AddVehicle = require("./ar-modules/add-vehicle");
const RegisterUser = require("./ar-modules/register-user");
const RegisterCommuter = require("./ar-modules/register-commuter");
const UpdateAssociation = require("./ar-modules/update-association");
const BroadcastRouteUpdate = require("./ar-modules/broadcast-route-update");
admin.initializeApp();
exports.addAssociation = AddAssociation.addAssociation;
exports.addOwner = AddOwner.addOwner;
exports.addVehicle = AddVehicle.addVehicle;
exports.registerUser = RegisterUser.registerUser;
exports.registerCommuter = RegisterCommuter.registerCommuter;
exports.updateAssociation = UpdateAssociation.updateAssociation;
exports.broadcastRouteUpdate = BroadcastRouteUpdate.broadcastRouteUpdate;
//# sourceMappingURL=index.js.map