
/*
####### Generated by JavaToDart Wed Dec 19 22:12:26 SAST 2018
####### rigged up by AM Esq.
*/

class SafetyAggregateRatingDTO {
	double aggregate;
	double count;
	double total;
	String path;

SafetyAggregateRatingDTO({
	this.aggregate,
	this.count,
	this.total,
});

SafetyAggregateRatingDTO.fromJson(Map data) {
	this.aggregate = data['aggregate'];
	this.count = data['count'];
	this.total = data['total'];
	this.path = data['path'];
}

Map<String, dynamic> toJson() => <String, dynamic>{
	'aggregate': aggregate,
	'count': count,
	'total': total,
	'path': path,
	
};

}