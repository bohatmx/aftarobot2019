"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var admin = require("firebase-admin");
var DocumentReference = admin.firestore.DocumentReference;
var GeoPoint = admin.firestore.GeoPoint;
// From https://stackoverflow.com/questions/8495687/split-array-into-chunks
var array_chunks = function (array, chunk_size) {
    return Array(Math.ceil(array.length / chunk_size))
        .fill(null)
        .map(function (_, index) { return index * chunk_size; })
        .map(function (begin) { return array.slice(begin, begin + chunk_size); });
};
exports.array_chunks = array_chunks;
var serializeSpecialTypes = function (data) {
    var cleaned = {};
    Object.keys(data).map(function (key) {
        var rawValue = data[key];
        if (rawValue instanceof admin.firestore.Timestamp) {
            rawValue = {
                __datatype__: 'timestamp',
                value: {
                    _seconds: rawValue.seconds,
                    _nanoseconds: rawValue.nanoseconds
                }
            };
        }
        else if (rawValue instanceof GeoPoint) {
            rawValue = {
                __datatype__: 'geopoint',
                value: {
                    _latitude: rawValue.latitude,
                    _longitude: rawValue.longitude
                }
            };
        }
        else if (rawValue instanceof DocumentReference) {
            rawValue = {
                __datatype__: 'documentReference',
                value: rawValue.path
            };
        }
        else if (rawValue === Object(rawValue)) {
            var isArray = Array.isArray(rawValue);
            rawValue = serializeSpecialTypes(rawValue);
            if (isArray) {
                rawValue = Object.keys(rawValue).map(function (key) { return rawValue[key]; });
            }
        }
        cleaned[key] = rawValue;
    });
    return cleaned;
};
exports.serializeSpecialTypes = serializeSpecialTypes;
var unserializeSpecialTypes = function (data, fs) {
    var cleaned = {};
    Object.keys(data).map(function (key) {
        var rawValue = data[key];
        var cleanedValue;
        if (rawValue instanceof Object) {
            if ('__datatype__' in rawValue && 'value' in rawValue) {
                switch (rawValue.__datatype__) {
                    case 'timestamp':
                        rawValue = rawValue;
                        if (rawValue.value instanceof String) {
                            var millis = Date.parse(rawValue.value);
                            cleanedValue = new admin.firestore.Timestamp(millis / 1000, 0);
                        }
                        else {
                            cleanedValue = new admin.firestore.Timestamp(rawValue.value._seconds, rawValue.value._nanoseconds);
                        }
                        break;
                    case 'geopoint':
                        rawValue = rawValue;
                        cleanedValue = new admin.firestore.GeoPoint(rawValue.value._latitude, rawValue.value._longitude);
                        break;
                    case 'documentReference':
                        rawValue = rawValue;
                        rawValue = fs.doc(rawValue.value);
                        break;
                }
            }
            else {
                var isArray = Array.isArray(rawValue);
                cleanedValue = unserializeSpecialTypes(rawValue, fs);
                if (isArray) {
                    cleanedValue = Object.keys(rawValue).map(function (key) { return rawValue[key]; });
                }
            }
        }
        else if (typeof rawValue === 'boolean') {
            cleanedValue = rawValue;
        }
        else if (typeof rawValue === 'string') {
            cleanedValue = rawValue;
        }
        else if (typeof rawValue === 'number') {
            cleanedValue = rawValue;
        }
        else { //still does not handle Maps
            console.error("UNKNOWN TYPE: " + rawValue);
            throw new Error("UNKNOWN TYPE: " + rawValue + ", possibly a Map or some new type added to Firestore?");
        }
        cleaned[key] = cleanedValue;
    });
    return cleaned;
};
exports.unserializeSpecialTypes = unserializeSpecialTypes;
