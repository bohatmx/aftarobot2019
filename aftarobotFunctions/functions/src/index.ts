import * as admin from "firebase-admin";

import * as AddAssociation from "./ar-modules/add-association";
import * as AddVehicleOwner from "./ar-modules/add-vehicle-owner";
import * as AddVehicleType from "./ar-modules/add-vehicle.type";
import * as CheckLogs from "./ar-modules/check-logs";

import * as AddLandmark from "./ar-modules/add-landmark";
import * as AddRoute from "./ar-modules/add-route";
import * as AddCountry from "./ar-modules/add-country";

import * as AddVehicle from "./ar-modules/add-vehicle";
import * as RegisterUser from "./ar-modules/register-user";
import * as RegisterCommuter from "./ar-modules/register-commuter";

import * as UpdateAssociation from "./ar-modules/update-association";
import * as BroadcastRouteUpdate from "./ar-modules/broadcast-route-update";

admin.initializeApp();
export const addLandmark = AddLandmark.addLandmark;
export const addRoute = AddRoute.addRoute;
export const addCountry = AddCountry.addCountry;

export const addAssociation = AddAssociation.addAssociation;
export const checkLogs = CheckLogs.checkLogs;
export const addVehicleOwner = AddVehicleOwner.addVehicleOwner;
export const addVehicle = AddVehicle.addVehicle;
export const addVehicleType = AddVehicleType.addVehicleType;
export const registerUser = RegisterUser.registerUser;
export const registerCommuter = RegisterCommuter.registerCommuter;
export const updateAssociation = UpdateAssociation.updateAssociation;
export const broadcastRouteUpdate = BroadcastRouteUpdate.broadcastRouteUpdate;
