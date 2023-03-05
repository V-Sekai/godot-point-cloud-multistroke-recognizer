extends Node

##
## The $P Point-Cloud Recognizer
##
##  Radu-Daniel Vatavu, Ph.D.
##  University Stefan cel Mare of Suceava
##  Suceava 720229, Romania
##  vatavu@eed.usv.ro
##
##  Lisa Anthony, Ph.D.
##  UMBC
##  Information Systems Department
##  1000 Hilltop Circle
##  Baltimore, MD 21250
##  lanthony@umbc.edu
##
##  Jacob O. Wobbrock, Ph.D.
##  The Information School
##  University of Washington
##  Seattle, WA 98195-2840
##  wobbrock@uw.edu
##
## The academic publication for the $P recognizer, and what should be
## used to cite it, is:
##
##     Vatavu, R.-D., Anthony, L. and Wobbrock, J.O. (2012).
##     Gestures as point clouds: A $P recognizer for user interface
##     prototypes. Proceedings of the ACM Int'l Conference on
##     Multimodal Interfaces (ICMI '12). Santa Monica, California
##     (October 22-26, 2012). New York: ACM Press, pp. 273-280.
##     https://dl.acm.org/citation.cfm?id=2388732
##
## This software is distributed under the "New BSD License" agreement:
##
## Copyright (C) 2012, Radu-Daniel Vatavu, Lisa Anthony, and
## Jacob O. Wobbrock. All rights reserved. Last updated July 14, 2018.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##    * Redistributions of source code must retain the above copyright
##      notice, this list of conditions and the following disclaimer.
##    * Redistributions in binary form must reproduce the above copyright
##      notice, this list of conditions and the following disclaimer in the
##      documentation and/or other materials provided with the distribution.
##    * Neither the names of the University Stefan cel Mare of Suceava,
##	University of Washington, nor UMBC, nor the names of its contributors
##	may be used to endorse or promote products derived from this software
##	without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
## IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
## THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
## PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Radu-Daniel Vatavu OR Lisa Anthony
## OR Jacob O. Wobbrock BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
## OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
## STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
## OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
## SUCH DAMAGE.

class RecognizerPoint:
	var x: float = 0
	var y: float = 0
	var id: StringName
	func _init(p_x, p_y, p_id):
		x = p_x
		y = p_y
		id = str(p_id) # stroke ID to which this point belongs (1,2,3,etc.)

class RecognizerResult:
	var name : StringName
	var score: float = 0
	var time: float = 0
	func _init(p_name : StringName, p_score: float, p_ms: float):	
		name = p_name
		score = p_score
		time = p_ms

## A point-cloud template
class PointCloud:
	var _name: StringName = ""
	var _points: Array[RecognizerPoint] = []

	const number_point_clouds = 16
	const number_points = 32
	var _origin : RecognizerPoint = RecognizerPoint.new(0,0,0)
 
	func Scale(points: Array[RecognizerPoint]) -> Array[RecognizerPoint]:
		var minX = INF
		var maxX = -INF
		var minY = INF
		var maxY = -INF
		for point in points:
			minX = min(minX, point.x);
			minY = min(minY, point.y);
			maxX = max(maxX, point.x);
			maxY = max(maxY, point.y);
		var size: float = max(maxX - minX, maxY - minY)
		var newpoints: Array[RecognizerPoint];
		for point in points:
			var qx = (point.x - minX) / size
			var qy = (point.y - minY) / size
			newpoints.push_back(RecognizerPoint.new(qx, qy, point.id))
		return newpoints;

	func Centroid(points):
		var x = 0.0
		var y = 0.0
		for point in points:
			x += point.x
			y += point.y
		x /= points.size()
		y /= points.size()
		return RecognizerPoint.new(x, y, 0)
		
	func TranslateTo(points: Array[RecognizerPoint], pt: RecognizerPoint): # translates points' centroid to points
		var c = Centroid(points)
		var newpoints: Array[RecognizerPoint]
		newpoints.resize(points.size())
		for point_i in range(points.size()):
			var point = points[point_i]
			var qx = point.x + pt.x - c.x;
			var qy = point.y + pt.y - c.y;
			newpoints[point_i] = RecognizerPoint.new(qx, qy, point.id)
		return newpoints

	func path_length(points : Array[RecognizerPoint]) -> float: # length traversed by a point path
		var d : float = 0.0;
		for point_i in range(1, points.size()):
			if (points[point_i].id == points[point_i-1].id):
				d += Vector2(points[point_i-1].x, points[point_i-1].y).distance_to(Vector2(points[point_i].x, points[point_i].y))
		return d;
		
	func resample(p_points: Array[RecognizerPoint], n: int):
		var I = path_length(p_points) / (n - 1); # interval length
		var D = 0.0;
		var newpoints: Array[RecognizerPoint] = [p_points[0]]
		for point_i in range(1, p_points.size()):
			if (p_points[point_i].id == p_points[point_i-1].id):
				var d = Vector2(p_points[point_i-1].x, p_points[point_i-1].y).distance_to(Vector2(p_points[point_i].x, p_points[point_i].y))
				if ((D + d) >= I):
					var qx = p_points[point_i-1].x + ((I - D) / d) * (p_points[point_i].x - p_points[point_i-1].x);
					var qy = p_points[point_i-1].y + ((I - D) / d) * (p_points[point_i].y - p_points[point_i-1].y);
					var q = RecognizerPoint.new(qx, qy, p_points[point_i].id);
					newpoints.push_back(q); # append new point 'q'
					p_points.insert(point_i, q); # insert 'q' at position i in points s.t. 'q' will be the next i
					D = 0.0;
				else:
					D += d
		if (newpoints.size() == n - 1): # sometimes we fall a rounding-error short of adding the last point, so add it if so
			newpoints.push_back(RecognizerPoint.new(p_points[p_points.size() - 1].x, p_points[p_points.size() - 1].y, p_points[p_points.size() - 1].id))
		return newpoints;

	func _init(p_name: StringName, p_points: Array[RecognizerPoint]):
		_name = p_name
		if not p_points.size():
			return
		_points = p_points
		_points = resample(_points, number_points);
		_points = Scale(_points)
		_points = TranslateTo(_points, _origin);


class PDollarRecognizer:
	var PointClouds : Array[PointCloud]
	
	func GreedyCloudMatch(points: Array[RecognizerPoint], P: PointCloud):
		var min = INF;
		if not points.size():
			return min
		var e = 0.50;
		var step = floor(pow(points.size(), 1.0 - e));
		for i in range(0, points.size(), step):
			var point = points[i]
			var d1 = CloudDistance(points, P._points, i);
			var d2 = CloudDistance(P._points, points, i);
			min = min(min, min(d1, d2)) # min3
		return min;
		
	func CloudDistance(pts1, pts2, start):
		var matched: Array
		matched.resize(max(pts1.size(), pts2.size()));
		for k in pts1.size():
			matched[k] = false;
		var sum = 0;
		var matched_i = start;
		while true:
			var index = -1;
			var min = INF;
			for matched_j in (matched.size()):
				if matched_i < -1 or matched_i >= pts1.size():
					continue
				if matched_j < -1 or matched_j >= pts2.size():
					continue
				if pts1[matched_i] == null and pts2[matched_j] == null:
					continue
				if !matched_i:
					var d = Vector2(pts1[matched_i].x, pts1[matched_i].y).distance_to(Vector2(pts2[matched_j].x, pts2[matched_j].y));
					if (d < min):
						min = d;
						index = matched_j;
			matched[index] = true;
			var weight = 1 - ((matched_i - start + pts1.size()) % pts1.size()) / pts1.size();
			sum += weight * min;
			matched_i = (matched_i + 1) % pts1.size();
			if (matched_i != start):
				break
		return sum;

	func _init():
		# Add one predefined point-cloud for each gesture.
		PointClouds.push_back(PointCloud.new("T", 	[RecognizerPoint.new(30,7,str(1)),
			RecognizerPoint.new(103,7,str(1)),
			RecognizerPoint.new(66,7,str(2)),
			RecognizerPoint.new(66,87,str(2))]))
		PointClouds.push_back(PointCloud.new("N", [
		RecognizerPoint.new(177,92,1),RecognizerPoint.new(177,2,1),
		RecognizerPoint.new(182,1,2),RecognizerPoint.new(246,95,2),
		RecognizerPoint.new(247,87,3),RecognizerPoint.new(247,1,3)
		]))
		PointClouds.push_back(PointCloud.new("D", [
			RecognizerPoint.new(345,9,1),RecognizerPoint.new(345,87,1),
			RecognizerPoint.new(351,8,2),RecognizerPoint.new(363,8,2),RecognizerPoint.new(372,9,2),RecognizerPoint.new(380,11,2),RecognizerPoint.new(386,14,2),RecognizerPoint.new(391,17,2),RecognizerPoint.new(394,22,2),RecognizerPoint.new(397,28,2),RecognizerPoint.new(399,34,2),RecognizerPoint.new(400,42,2),RecognizerPoint.new(400,50,2),RecognizerPoint.new(400,56,2),RecognizerPoint.new(399,61,2),RecognizerPoint.new(397,66,2),RecognizerPoint.new(394,70,2),RecognizerPoint.new(391,74,2),RecognizerPoint.new(386,78,2),RecognizerPoint.new(382,81,2),RecognizerPoint.new(377,83,2),RecognizerPoint.new(372,85,2),RecognizerPoint.new(367,86,2),RecognizerPoint.new(360,87,2),RecognizerPoint.new(355,87,2),RecognizerPoint.new(349,86,2)
		]))
		PointClouds.push_back(PointCloud.new("P", [
			RecognizerPoint.new(507,8,1),RecognizerPoint.new(507,87,1),
			RecognizerPoint.new(513,7,2),RecognizerPoint.new(528,7,2),RecognizerPoint.new(537,8,2),RecognizerPoint.new(544,10,2),RecognizerPoint.new(550,12,2),RecognizerPoint.new(555,15,2),RecognizerPoint.new(558,18,2),RecognizerPoint.new(560,22,2),RecognizerPoint.new(561,27,2),RecognizerPoint.new(562,33,2),RecognizerPoint.new(561,37,2),RecognizerPoint.new(559,42,2),RecognizerPoint.new(556,45,2),RecognizerPoint.new(550,48,2),RecognizerPoint.new(544,51,2),RecognizerPoint.new(538,53,2),RecognizerPoint.new(532,54,2),RecognizerPoint.new(525,55,2),RecognizerPoint.new(519,55,2),RecognizerPoint.new(513,55,2),RecognizerPoint.new(510,55,2)
		]))
		PointClouds.push_back(PointCloud.new("X", [
			RecognizerPoint.new(30,146,1),RecognizerPoint.new(106,222,1),
			RecognizerPoint.new(30,225,2),RecognizerPoint.new(106,146,2)
		]))
		PointClouds.push_back(PointCloud.new("H", [
			RecognizerPoint.new(188,137,1),RecognizerPoint.new(188,225,1),
			RecognizerPoint.new(188,180,2),RecognizerPoint.new(241,180,2),
			RecognizerPoint.new(241,137,3),RecognizerPoint.new(241,225,3)
		]))
		PointClouds.push_back(PointCloud.new("I", [
			RecognizerPoint.new(371,149,1),RecognizerPoint.new(371,221,1),
			RecognizerPoint.new(341,149,2),RecognizerPoint.new(401,149,2),
			RecognizerPoint.new(341,221,3),RecognizerPoint.new(401,221,3)
		]))
		PointClouds.push_back(PointCloud.new("exclamation", [
			RecognizerPoint.new(526,142,1),RecognizerPoint.new(526,204,1),
			RecognizerPoint.new(526,221,2)
		]))
		PointClouds.push_back(PointCloud.new("line", [
			RecognizerPoint.new(12,347,1),RecognizerPoint.new(119,347,1)
		]))
		PointClouds.push_back(PointCloud.new("five-point star", [
			RecognizerPoint.new(177,396,1),RecognizerPoint.new(223,299,1),RecognizerPoint.new(262,396,1),RecognizerPoint.new(168,332,1),RecognizerPoint.new(278,332,1),RecognizerPoint.new(184,397,1)
		]))
		PointClouds.push_back(PointCloud.new("null", [
			RecognizerPoint.new(382,310,1),RecognizerPoint.new(377,308,1),RecognizerPoint.new(373,307,1),RecognizerPoint.new(366,307,1),RecognizerPoint.new(360,310,1),RecognizerPoint.new(356,313,1),RecognizerPoint.new(353,316,1),RecognizerPoint.new(349,321,1),RecognizerPoint.new(347,326,1),RecognizerPoint.new(344,331,1),RecognizerPoint.new(342,337,1),RecognizerPoint.new(341,343,1),RecognizerPoint.new(341,350,1),RecognizerPoint.new(341,358,1),RecognizerPoint.new(342,362,1),RecognizerPoint.new(344,366,1),RecognizerPoint.new(347,370,1),RecognizerPoint.new(351,374,1),RecognizerPoint.new(356,379,1),RecognizerPoint.new(361,382,1),RecognizerPoint.new(368,385,1),RecognizerPoint.new(374,387,1),RecognizerPoint.new(381,387,1),RecognizerPoint.new(390,387,1),RecognizerPoint.new(397,385,1),RecognizerPoint.new(404,382,1),RecognizerPoint.new(408,378,1),RecognizerPoint.new(412,373,1),RecognizerPoint.new(416,367,1),RecognizerPoint.new(418,361,1),RecognizerPoint.new(419,353,1),RecognizerPoint.new(418,346,1),RecognizerPoint.new(417,341,1),RecognizerPoint.new(416,336,1),RecognizerPoint.new(413,331,1),RecognizerPoint.new(410,326,1),RecognizerPoint.new(404,320,1),RecognizerPoint.new(400,317,1),RecognizerPoint.new(393,313,1),RecognizerPoint.new(392,312,1),
			RecognizerPoint.new(418,309,2),RecognizerPoint.new(337,390,2)
		]))
		PointClouds.push_back(PointCloud.new("arrowhead", [
			RecognizerPoint.new(506,349,1),RecognizerPoint.new(574,349,1),
			RecognizerPoint.new(525,306,2),RecognizerPoint.new(584,349,2),RecognizerPoint.new(525,388,2)
		]))
		PointClouds.push_back(PointCloud.new("pitchfork", [
			RecognizerPoint.new(38,470,1),RecognizerPoint.new(36,476,1),RecognizerPoint.new(36,482,1),RecognizerPoint.new(37,489,1),RecognizerPoint.new(39,496,1),RecognizerPoint.new(42,500,1),RecognizerPoint.new(46,503,1),RecognizerPoint.new(50,507,1),RecognizerPoint.new(56,509,1),RecognizerPoint.new(63,509,1),RecognizerPoint.new(70,508,1),RecognizerPoint.new(75,506,1),RecognizerPoint.new(79,503,1),RecognizerPoint.new(82,499,1),RecognizerPoint.new(85,493,1),RecognizerPoint.new(87,487,1),RecognizerPoint.new(88,480,1),RecognizerPoint.new(88,474,1),RecognizerPoint.new(87,468,1),
			RecognizerPoint.new(62,464,2),RecognizerPoint.new(62,571,2)
		]))
		PointClouds.push_back(PointCloud.new("six-point star", [
			RecognizerPoint.new(177,554,1),RecognizerPoint.new(223,476,1),RecognizerPoint.new(268,554,1),RecognizerPoint.new(183,554,1),
			RecognizerPoint.new(177,490,2),RecognizerPoint.new(223,568,2),RecognizerPoint.new(268,490,2),RecognizerPoint.new(183,490,2)
		]))
		PointClouds.push_back(PointCloud.new("asterisk", [
			RecognizerPoint.new(325,499,1),RecognizerPoint.new(417,557,1),
			RecognizerPoint.new(417,499,2),RecognizerPoint.new(325,557,2),
			RecognizerPoint.new(371,486,3),RecognizerPoint.new(371,571,3)
		]))
		PointClouds.push_back(PointCloud.new("half-note", [
			RecognizerPoint.new(546,465,1),RecognizerPoint.new(546,531,1),
			RecognizerPoint.new(540,530,2),RecognizerPoint.new(536,529,2),RecognizerPoint.new(533,528,2),RecognizerPoint.new(529,529,2),RecognizerPoint.new(524,530,2),RecognizerPoint.new(520,532,2),RecognizerPoint.new(515,535,2),RecognizerPoint.new(511,539,2),RecognizerPoint.new(508,545,2),RecognizerPoint.new(506,548,2),RecognizerPoint.new(506,554,2),RecognizerPoint.new(509,558,2),RecognizerPoint.new(512,561,2),RecognizerPoint.new(517,564,2),RecognizerPoint.new(521,564,2),RecognizerPoint.new(527,563,2),RecognizerPoint.new(531,560,2),RecognizerPoint.new(535,557,2),RecognizerPoint.new(538,553,2),RecognizerPoint.new(542,548,2),RecognizerPoint.new(544,544,2),RecognizerPoint.new(546,540,2),RecognizerPoint.new(546,536,2)
		]))

	# The $P Point-Cloud Recognizer API begins here
	func recognize(points: Array[RecognizerPoint])-> RecognizerResult:
		var t0 = Time.get_ticks_msec()
		var candidate: PointCloud = PointCloud.new("", points);
		var u = -1;
		var b = INF;
		for cloud_i in range(PointClouds.size()): # for each point-cloud template
			var d = GreedyCloudMatch(candidate._points, PointClouds[cloud_i]);
			if (d < b):
				b = d; # best (least) distance
				u = cloud_i; # point-cloud index
		var t1 = Time.get_ticks_msec()
		if (u == -1):
			return RecognizerResult.new("No match.", 0.0, t1-t0)
		return RecognizerResult.new(PointClouds[u]._name, b > 1.0 if 1.0 / b else 1.0, t1-t0)

	func AddGesture(p_name, p_points):
		PointClouds.push_back(PointCloud.new(p_name, p_points))
		var num = 0;
		for cloud in PointClouds:
			if cloud._name == p_name:
				num = num + 1;
		return num;

	func DeleteUserGestures():
		PointClouds.clear()
		PointClouds.resize(PointCloud.number_point_clouds); # clears any beyond the original set
		return PointCloud.number_point_clouds;

func _ready():
	var recognizer = PDollarRecognizer.new()
	# Test the d shape.
	var result : RecognizerResult = recognizer.recognize([
			RecognizerPoint.new(325,499,1),RecognizerPoint.new(417,557,1),
			RecognizerPoint.new(417,499,2),RecognizerPoint.new(325,557,2),
			RecognizerPoint.new(371,486,3),RecognizerPoint.new(371,571,3)
		])
	print(result.name)
	print(result.score)
	print(result.time)

