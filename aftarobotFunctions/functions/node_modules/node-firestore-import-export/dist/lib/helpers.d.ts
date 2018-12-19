import Firestore = FirebaseFirestore.Firestore;
declare const array_chunks: (array: any[], chunk_size: number) => any[][];
declare const serializeSpecialTypes: (data: any) => any;
declare const unserializeSpecialTypes: (data: any, fs: Firestore) => any;
export { array_chunks, serializeSpecialTypes, unserializeSpecialTypes };
