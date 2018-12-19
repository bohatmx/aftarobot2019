#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var commander = require("commander");
var prompt = require("prompt");
var colors = require("colors");
var process = require("process");
var fs = require("fs");
var import_1 = require("../lib/import");
var firestore_helpers_1 = require("../lib/firestore-helpers");
var load_json_file_1 = require("load-json-file");
var packageInfo = require('../../package.json');
var accountCredentialsEnvironmentKey = 'GOOGLE_APPLICATION_CREDENTIALS';
var accountCredentialsPathParamKey = 'accountCredentials';
var accountCredentialsPathParamDescription = 'path to Google Cloud account credentials JSON file. If missing, will look ' +
    ("at the " + accountCredentialsEnvironmentKey + " environment variable for the path.");
var backupFileParamKey = 'backupFile';
var backupFileParamDescription = 'Filename to store backup. (e.g. backups/full-backup.json).';
var nodePathParamKey = 'nodePath';
var nodePathParamDescription = 'Path to database node (has to be a collection) where import will to start (e.g. collectionA/docB/collectionC).' +
    ' Imports at root level if missing.';
var yesToImportParamKey = 'yes';
var yesToImportParamDescription = 'Unattended import without confirmation (like hitting "y" from the command line).';
commander.version(packageInfo.version)
    .option("-a, --" + accountCredentialsPathParamKey + " <path>", accountCredentialsPathParamDescription)
    .option("-b, --" + backupFileParamKey + " <path>", backupFileParamDescription)
    .option("-n, --" + nodePathParamKey + " <path>", nodePathParamDescription)
    .option("-y, --" + yesToImportParamKey, yesToImportParamDescription)
    .parse(process.argv);
var accountCredentialsPath = commander[accountCredentialsPathParamKey] || process.env[accountCredentialsEnvironmentKey];
if (!accountCredentialsPath) {
    console.log(colors.bold(colors.red('Missing: ')) + colors.bold(accountCredentialsPathParamKey) + ' - ' + accountCredentialsPathParamDescription);
    commander.help();
    process.exit(1);
}
if (!fs.existsSync(accountCredentialsPath)) {
    console.log(colors.bold(colors.red('Account credentials file does not exist: ')) + colors.bold(accountCredentialsPath));
    commander.help();
    process.exit(1);
}
var backupFile = commander[backupFileParamKey];
if (!backupFile) {
    console.log(colors.bold(colors.red('Missing: ')) + colors.bold(backupFileParamKey) + ' - ' + backupFileParamDescription);
    commander.help();
    process.exit(1);
}
if (!fs.existsSync(backupFile)) {
    console.log(colors.bold(colors.red('Backup file does not exist: ')) + colors.bold(backupFile));
    commander.help();
    process.exit(1);
}
var nodePath = commander[nodePathParamKey];
var importPathPromise = firestore_helpers_1.getCredentialsFromFile(accountCredentialsPath)
    .then(function (credentials) {
    var db = firestore_helpers_1.getFirestoreDBReference(credentials);
    return firestore_helpers_1.getDBReferenceFromPath(db, nodePath);
});
var unattendedConfirmation = commander[yesToImportParamKey];
Promise.all([load_json_file_1.default(backupFile), importPathPromise, firestore_helpers_1.getCredentialsFromFile(accountCredentialsPath)])
    .then(function (res) {
    if (unattendedConfirmation) {
        return res;
    }
    var data = res[0], pathReference = res[1], credentials = res[2];
    var nodeLocation = pathReference
        .path || '[database root]';
    var projectID = credentials.project_id;
    var importText = "About to import data '" + backupFile + "' to the '" + projectID + "' firestore at '" + nodeLocation + "'.";
    console.log("\n\n" + colors.bold(colors.blue(importText)));
    console.log(colors.bgYellow(colors.blue(' === Warning: This will overwrite existing data. Do you want to proceed? === ')));
    return new Promise(function (resolve, reject) {
        prompt.message = 'firestore-import';
        prompt.start();
        prompt.get({
            properties: {
                response: {
                    description: colors.red("Proceed with import? [y/N] ")
                }
            }
        }, function (err, result) {
            if (err) {
                return reject(err);
            }
            switch (result.response.trim().toLowerCase()) {
                case 'y':
                    resolve(res);
                    break;
                default:
                    reject('Import aborted.');
            }
        });
    });
})
    .then(function (res) {
    var data = res[0], pathReference = res[1];
    return import_1.default(data, pathReference);
})
    .then(function () {
    console.log(colors.bold(colors.green('All done 🎉')));
})
    .catch(function (error) {
    if (error instanceof Error) {
        console.log(colors.red(error.name + ": " + error.message));
        console.log(colors.red(error.stack));
        process.exit(1);
    }
    else {
        console.log(colors.red(error));
    }
});
