#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var commander = require("commander");
var colors = require("colors");
var process = require("process");
var fs = require("fs");
var export_1 = require("../lib/export");
var firestore_helpers_1 = require("../lib/firestore-helpers");
var packageInfo = require('../../package.json');
var accountCredentialsEnvironmentKey = 'GOOGLE_APPLICATION_CREDENTIALS';
var accountCredentialsPathParamKey = 'accountCredentials';
var accountCredentialsPathParamDescription = 'path to Google Cloud account credentials JSON file. If missing, will look ' +
    ("at the " + accountCredentialsEnvironmentKey + " environment variable for the path.");
var defaultBackupFilename = 'firebase-export.json';
var backupFileParamKey = 'backupFile';
var backupFileParamDescription = "Filename to store backup. (e.g. backups/full-backup.json). " +
    ("Defaults to '" + defaultBackupFilename + "' if missing.");
var nodePathParamKey = 'nodePath';
var nodePathParamDescription = 'Path to database node to start (e.g. collectionA/docB/collectionC). ' +
    'Backs up entire database from the root if missing.';
var prettyPrintParamKey = 'prettyPrint';
var prettyPrintParamDescription = 'JSON backups done with pretty-printing.';
commander.version(packageInfo.version)
    .option("-a, --" + accountCredentialsPathParamKey + " <path>", accountCredentialsPathParamDescription)
    .option("-b, --" + backupFileParamKey + " <path>", backupFileParamDescription)
    .option("-n, --" + nodePathParamKey + " <path>", nodePathParamDescription)
    .option("-p, --" + prettyPrintParamKey, prettyPrintParamDescription)
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
var backupPath = commander[backupFileParamKey] || defaultBackupFilename;
if (!backupPath) {
    console.log(colors.bold(colors.red('Missing: ')) + colors.bold(backupFileParamKey) + ' - ' + backupFileParamDescription);
    commander.help();
    process.exit(1);
}
var writeResults = function (results, filename) {
    return new Promise(function (resolve, reject) {
        fs.writeFile(filename, results, 'utf8', function (err) {
            if (err) {
                reject(err);
            }
            else {
                resolve(filename);
            }
        });
    });
};
var prettyPrint = commander[prettyPrintParamKey] !== undefined && commander[prettyPrintParamKey] !== null;
var nodePath = commander[nodePathParamKey];
firestore_helpers_1.getCredentialsFromFile(accountCredentialsPath)
    .then(function (credentials) {
    var db = firestore_helpers_1.getFirestoreDBReference(credentials);
    var pathReference = firestore_helpers_1.getDBReferenceFromPath(db, nodePath);
    return pathReference;
})
    .then(function (pathReference) { return export_1.default(pathReference); })
    .then(function (results) {
    var stringResults;
    if (prettyPrint) {
        stringResults = JSON.stringify(results, null, 2);
    }
    else {
        stringResults = JSON.stringify(results);
    }
    return stringResults;
})
    .then(function (dataToWrite) { return writeResults(dataToWrite, backupPath); })
    .then(function (filename) {
    console.log(colors.yellow("Results were saved to " + filename));
    return;
})
    .then(function () {
    console.log(colors.bold(colors.green('All done 🎉')));
})
    .catch(function (error) {
    if (error instanceof Error) {
        console.log(colors.red(error.message));
        process.exit(1);
    }
    else {
        console.log(colors.red(error));
    }
});
