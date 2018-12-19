import * as admin from 'firebase-admin'

import * as AddAssociation from './ar-modules/add-association'
import * as AddOwner from './ar-modules/add-owner'
import * as AddVehicle from './ar-modules/add-vehicle'
import * as RegisterUser from './ar-modules/register-user'
import * as RegisterCommuter from './ar-modules/register-commuter'
import * as UpdateAssociation from './ar-modules/update-association'
import * as BroadcastRouteUpdate from './ar-modules/broadcast-route-update'


admin.initializeApp();

export const addAssociation = AddAssociation.addAssociation;
export const addOwner = AddOwner.addOwner;
export const addVehicle = AddVehicle.addVehicle;
export const registerUser = RegisterUser.registerUser;
export const registerCommuter = RegisterCommuter.registerCommuter;
export const updateAssociation = UpdateAssociation.updateAssociation;
export const broadcastRouteUpdate = BroadcastRouteUpdate.broadcastRouteUpdate;

