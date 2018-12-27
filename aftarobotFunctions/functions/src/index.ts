import * as admin from "firebase-admin";

import * as AddAssociation from "./ar-modules/add-association";
import * as AddAssociations from "./ar-modules/add-associations";
import * as AddVehicleOwner from "./ar-modules/add-vehicle-owner";
import * as AddVehicleType from "./ar-modules/add-vehicle.type";
import * as CheckLogs from "./ar-modules/check-logs";

import * as AddLandmark from "./ar-modules/add-landmark";
import * as AddLandmarks from "./ar-modules/add-landmarks";
import * as AddRoute from "./ar-modules/add-route";
import * as AddCountry from "./ar-modules/add-country";

import * as AddCities from "./ar-modules/add-cities";
import * as AddCountries from "./ar-modules/add-countries";

import * as AddVehicle from "./ar-modules/add-vehicle";
import * as AddVehicles from "./ar-modules/add-vehicles";
import * as RegisterUser from "./ar-modules/register-user";
import * as RegisterUsers from "./ar-modules/register-users";
import * as RegisterCommuter from "./ar-modules/register-commuter";

import * as UpdateAssociation from "./ar-modules/update-association";
import * as BroadcastRouteUpdate from "./ar-modules/broadcast-route-update";

admin.initializeApp();

export const addCities = AddCities.addCities;
export const addLandmark = AddLandmark.addLandmark;
export const addLandmarks = AddLandmarks.addLandmarks;
export const addRoute = AddRoute.addRoute;
export const addCountry = AddCountry.addCountry;
export const addCountries = AddCountries.addCountries;
export const addAssociation = AddAssociation.addAssociation;
export const addAssociations = AddAssociations.addAssociations;
export const checkLogs = CheckLogs.checkLogs;
export const addVehicleOwner = AddVehicleOwner.addVehicleOwner;
export const addVehicle = AddVehicle.addVehicle;
export const addVehicles = AddVehicles.addVehicles;
export const addVehicleType = AddVehicleType.addVehicleType;
export const registerUser = RegisterUser.registerUser;
export const registerUsers = RegisterUsers.registerUsers;
export const registerCommuter = RegisterCommuter.registerCommuter;
export const updateAssociation = UpdateAssociation.updateAssociation;
export const broadcastRouteUpdate = BroadcastRouteUpdate.broadcastRouteUpdate;
