import { IFirebaseCredentials } from "../interfaces/IFirebaseCredentials";
declare const getCredentialsFromFile: (credentialsFilename: string) => Promise<IFirebaseCredentials>;
declare const getFirestoreDBReference: (credentials: IFirebaseCredentials) => FirebaseFirestore.Firestore;
declare const getDBReferenceFromPath: (db: FirebaseFirestore.Firestore, dataPath?: string | undefined) => FirebaseFirestore.Firestore | FirebaseFirestore.CollectionReference | FirebaseFirestore.DocumentReference;
declare const isLikeDocument: (ref: FirebaseFirestore.Firestore | FirebaseFirestore.CollectionReference | FirebaseFirestore.DocumentReference) => ref is FirebaseFirestore.DocumentReference;
declare const isRootOfDatabase: (ref: FirebaseFirestore.Firestore | FirebaseFirestore.CollectionReference | FirebaseFirestore.DocumentReference) => ref is FirebaseFirestore.Firestore;
declare const sleep: (timeInMS: number) => Promise<void>;
export { getCredentialsFromFile, getFirestoreDBReference, getDBReferenceFromPath, isLikeDocument, isRootOfDatabase, sleep };
