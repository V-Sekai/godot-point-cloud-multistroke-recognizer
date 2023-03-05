extends Node

#/**
# * The $Q Super-Quick Recognizer (JavaScript version)
# *
# * Javascript version:
# *
# *  Nathan Magrofuoco
# *  Universite Catholique de Louvain
# *  Louvain-la-Neuve, Belgium
# *  nathan.magrofuoco@uclouvain.be
# *
# * Original $Q authors (C# version):
# *
# *  Radu-Daniel Vatavu, Ph.D.
# *  University Stefan cel Mare of Suceava
# *  Suceava 720229, Romania
# *  radu.vatavu@usm.ro
# *
# *  Lisa Anthony, Ph.D.
# *  Department of CISE
# *  University of Florida
# *  Gainesville, FL, USA 32611
# *  lanthony@cise.ufl.edu
# *
# *  Jacob O. Wobbrock, Ph.D.
# *  The Information School | DUB Group
# *  University of Washington
# *  Seattle, WA, USA 98195-2840
# *  wobbrock@uw.edu
# *
# * The academic publication for the $Q recognizer, and what should be
# * used to cite it, is:
# *
# *    Vatavu, R.-D., Anthony, L. and Wobbrock, J.O. (2018). $Q: A super-quick,
# *    articulation-invariant stroke-gesture recognizer for low-resource devices.
# *    Proceedings of the ACM Conference on Human-Computer Interaction with Mobile
# *    Devices and Services (MobileHCI '18). Barcelona, Spain (September 3-6, 2018).
# *    New York: ACM Press. Article No. 23.
# *    https://dl.acm.org/citation.cfm?id=3229434.3229465
# *
# * This software is distributed under the "New BSD License" agreement:
# *
# * Copyright (c) 2018-2019, Nathan Magrofuoco, Jacob O. Wobbrock, Radu-Daniel Vatavu,
# * and Lisa Anthony. All rights reserved.
# *
# * Redistribution and use in source and binary forms, with or without
# * modification, are permitted provided that the following conditions are met:
# *    * Redistributions of source code must retain the above copyright
# *      notice, this list of conditions and the following disclaimer.
# *    * Redistributions in binary form must reproduce the above copyright
# *      notice, this list of conditions and the following disclaimer in the
# *      documentation and/or other materials provided with the distribution.
# *    * Neither the names of the University Stefan cel Mare of Suceava,
# *      University of Washington, nor University of Florida, nor the names of its
# *      contributors may be used to endorse or promote products derived from this
# *      software without specific prior written permission.
# *
# * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Radu-Daniel Vatavu OR Lisa Anthony
# * OR Jacob O. Wobbrock BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# * SUCH DAMAGE.
#**/


class RecognizerPoint:
	var x: float = 0
	var y: float = 0
	var id: StringName
	var int_x = 0; # for indexing into the LUT
	var int_y = 0; # for indexing into the LUT

	func _init(p_x, p_y, p_id):
		x = p_x
		y = p_y
		id = str(p_id)  # stroke ID to which this point belongs (1,2,3,etc.)


class RecognizerResult:
	var name: StringName
	var score: float = 0.0
	var time: float = 0.0

	func _init(p_name: StringName, p_score: float, p_ms: float):
		name = p_name
		score = p_score
		time = p_ms


class QDollarRecognizer:
	var _point_clouds: Array[PointCloud]

	## A point-cloud template
	class PointCloud:
		const NUMBER_POINTS = 32
		const MaxIntCoord = 1024; # (IntX, IntY) range from [0, MaxIntCoord - 1]
		const LUTSize = 64; # default size of the lookup table is 64 x 64
		const LUTScaleFactor = MaxIntCoord / LUTSize; # used to scale from (IntX, IntY) to LUT
		var _name: StringName = ""
		var _points: Array[RecognizerPoint] = []
		var _origin: RecognizerPoint = RecognizerPoint.new(0, 0, 0)
		var LUT: Array

		func scale(points: Array[RecognizerPoint]) -> Array[RecognizerPoint]:
			var minX = INF
			var maxX = -INF
			var minY = INF
			var maxY = -INF
			for point in points:
				minX = min(minX, point.x)
				minY = min(minY, point.y)
				maxX = max(maxX, point.x)
				maxY = max(maxY, point.y)
			var size: float = max(maxX - minX, maxY - minY)
			var newpoints: Array[RecognizerPoint]
			for point in points:
				var qx = (point.x - minX) / size
				var qy = (point.y - minY) / size
				newpoints.push_back(RecognizerPoint.new(qx, qy, point.id))
			return newpoints

		func centroid(points):
			var x = 0.0
			var y = 0.0
			for point in points:
				x += point.x
				y += point.y
			x /= points.size()
			y /= points.size()
			return RecognizerPoint.new(x, y, 0)

		func translate_to(points: Array[RecognizerPoint], pt: RecognizerPoint):  # translates points' centroid to points
			var c = centroid(points)
			var newpoints: Array[RecognizerPoint]
			newpoints.resize(points.size())
			for point_i in range(points.size()):
				var point = points[point_i]
				var qx = point.x + pt.x - c.x
				var qy = point.y + pt.y - c.y
				newpoints[point_i] = RecognizerPoint.new(qx, qy, point.id)
			return newpoints

		func path_length(points: Array[RecognizerPoint]) -> float:  # length traversed by a point path
			if points.size() < 2:
				return 0.0
			var d: float = 0.0
			for point_i in range(1, points.size()):
				if points[point_i].id == points[point_i - 1].id:
					d += Vector2(points[point_i - 1].x, points[point_i - 1].y).distance_to(
						Vector2(points[point_i].x, points[point_i].y)
					)
			return d

		func resample(p_points: Array[RecognizerPoint], n: int):
			var I = path_length(p_points) / (n - 1)  # interval length
			var D = 0.0
			var new_points: Array[RecognizerPoint]
			new_points.resize(n)
			new_points.fill(p_points[0])
			for point_i in range(1, n):
				if p_points[point_i].id == p_points[point_i - 1].id:
					var d = Vector2(p_points[point_i - 1].x, p_points[point_i - 1].y).distance_to(
						Vector2(p_points[point_i].x, p_points[point_i].y)
					)
					if (D + d) >= I:
						var qx = p_points[point_i - 1].x + ((I - D) / d) * (p_points[point_i].x - p_points[point_i - 1].x)
						var qy = p_points[point_i - 1].y + ((I - D) / d) * (p_points[point_i].y - p_points[point_i - 1].y)
						var q = RecognizerPoint.new(qx, qy, p_points[point_i].id)
						new_points[point_i] = q
						p_points.insert(point_i, q)  # insert 'q' at position i in points s.t. 'q' will be the next i
						D = 0.0
					else:
						D += d
			if new_points.size() == n - 1:  # Sometimes we fall a rounding-error short of adding the last point, so add it if so
				new_points.push_back(
					RecognizerPoint.new(
						p_points[p_points.size() - 1].x, p_points[p_points.size() - 1].y, p_points[p_points.size() - 1].id
					)
				)
			return new_points

		func MakeIntCoords(points: Array[RecognizerPoint]):
			for point in points:
				point.int_x = round((point.x + 1.0) / 2.0 * (MaxIntCoord - 1))
				point.int_y = round((point.y + 1.0) / 2.0 * (MaxIntCoord - 1))
			return points;
			
		func ComputeLUT(points) -> Array:
			var LUT: Array
			LUT.resize(LUTSize)
			for lut in LUTSize:
				var lut_array: Array
				lut_array.resize(LUTSize)
				LUT[lut] = lut_array

			for x in LUTSize:
				for y in LUTSize:
					var u = -1;
					var b = INF;
					for points_i in range(points.size()):
						var row = round(points[points_i].int_x / LUTScaleFactor);
						var col = round(points[points_i].int_y / LUTScaleFactor);
						var d = ((row - x) * (row - x)) + ((col - y) * (col - y));
						if (d < b):
							b = d
							u = points_i;
					LUT[x][y] = u;
			return LUT;
			
		func _init(p_name: StringName, p_points: Array[RecognizerPoint]):
			_name = p_name
			_points = p_points
			_points = resample(_points, NUMBER_POINTS)
			_points = scale(_points)
			_points = translate_to(_points, _origin)
			_points = MakeIntCoords(_points); # fills in (IntX, IntY) values
			LUT = ComputeLUT(_points);


	func ComputeLowerBound(pts1, pts2, step, LUT):
		var n = pts1.size();
		var LB: Array
		LB.resize(floor(n / step) + 1)
		var SAT: Array
		SAT.resize(n)
		LB[0] = 0.0;
		for i in n:
			var x: int = round(pts1[i].int_x / PointCloud.LUTScaleFactor);
			var y: int = round(pts1[i].int_y / PointCloud.LUTScaleFactor);
			var index: int = LUT[x][y];
			var d: float = Vector2(pts1[i].x, pts1[i].y).distance_squared_to(Vector2(pts2[index].x, pts2[index].y))
			if i == 0:
				SAT[i] = d
			else:
				SAT[i] = SAT[i - 1] + d;
			LB[0] += (n - i) * d;
		var j = 1
		for i in range(step, n, step):
			LB[j] = LB[0] + i * SAT[n-1] - n * SAT[i-1];
			j = j + 1
		return LB;

	func _cloud_match(candidate: PointCloud, template: PointCloud, minSoFar: float) -> float:
		var n: int = candidate._points.size()
		var step: int = floor(pow(n, 0.5))
		var LB1: Array = ComputeLowerBound(candidate._points, template._points, step, template.LUT)
		var LB2: Array = ComputeLowerBound(template._points, candidate._points, step, candidate.LUT)
		var j = 0
		for i in range(0, n, step):
			if LB1[j] < minSoFar:
				minSoFar = min(minSoFar, _cloud_distance(candidate._points, template._points, i, minSoFar))
			if LB2[j] < minSoFar:
				minSoFar = min(minSoFar, _cloud_distance(template._points, candidate._points, i, minSoFar))
			j = j + 1
		return minSoFar

	func _cloud_distance(pts1: Array[RecognizerPoint], pts2: Array[RecognizerPoint], start, minSoFar) -> float:
		var n: int = pts1.size();
		var unmatched: Array = Array(); # indices for pts2 that are not matched
		unmatched.resize(n)
		for j in n:
			unmatched[j] = j;
		var i: int = start;  # start matching with point 'start' from pts1
		var weight: float = n; # weights decrease from n to 1
		var sum: float = 0.0;  # sum distance between the two clouds
		while true:
			var u = -1;
			var b = INF;
			for j in range(unmatched.size()):
				var d = Vector2(pts1[i].x, pts1[i].y).distance_squared_to(Vector2(pts2[unmatched[j]].x, pts2[unmatched[j]].y))
				if (d < b):
					b = d
					u = j
			unmatched.insert(u, 1) # remove item at index 'u'
			sum += weight * b;
			if sum >= minSoFar:
				return sum; # early abandoning
			weight = weight - 1;
			i = (i + 1) % n;
			if i == start:
				break
		return sum;

	func recognize(p_points: Array[RecognizerPoint]) -> RecognizerResult:
		var t0: float = Time.get_ticks_msec()
		var candidate: PointCloud = PointCloud.new("", p_points)
		var u: int = -1
		var b: float = INF
		for cloud_i in range(_point_clouds.size()):  # for each point-cloud template
			var d: float = _cloud_match(candidate, _point_clouds[cloud_i], b)
			if d < b:
				b = d  # best (least) distance
				u = cloud_i  # point-cloud index
		var t1: float = Time.get_ticks_msec()
		if u == -1:
			return RecognizerResult.new("No match.", 0.0, (t1 - t0) / 1000)
		if b > 1.0:
			b = 1.0 / b
		else:
			b = 1.0
		return RecognizerResult.new(_point_clouds[u]._name, b, (t1 - t0) / 1000)

	func add_gesture(p_name: StringName, p_points: Array[RecognizerPoint]) -> int:
		if not p_points.size():
			return 0
		var new_point_cloud: PointCloud = PointCloud.new(p_name, p_points)
		_point_clouds.push_back(new_point_cloud)
		var num: int = 0
		for cloud in _point_clouds:
			if cloud._name == p_name:
				num = num + 1
		return num

	func delete_user_gestures():
		_point_clouds.clear()
		return _point_clouds.size()
