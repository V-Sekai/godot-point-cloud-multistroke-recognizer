@uid("uid://c1hfwsya7pb38") # Generated automatically, do not modify.
extends RefCounted

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
	var int_x: int = 0; # for indexing into the LUT
	var int_y: int = 0; # for indexing into the LUT

	func _to_string() -> String:
		return "RecognizerPoint(x: %d y: %d id: %s)" % [x, y, id]

	func _init(p_x: float, p_y: float, p_id: StringName):
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
		const NUMBER_POINTS = 64
		const MAX_INTEGER_COORDINATE = 1024; # (IntX, IntY) range from [0, MAX_INTEGER_COORDINATE - 1]
		const LUT_SIZE = 64; # default size of the lookup table is 64 x 64
		const LUT_SCALE_FACTOR = MAX_INTEGER_COORDINATE / LUT_SIZE; # used to scale from (IntX, IntY) to LUT
		var _name: StringName = ""
		var _points: Array[RecognizerPoint] = []
		var _origin: RecognizerPoint = RecognizerPoint.new(0, 0, str(0))
		var _lut: Array

		func scale(points: Array[RecognizerPoint]) -> Array[RecognizerPoint]:
			var minX: float = INF
			var maxX: float = -INF
			var minY: float = INF
			var maxY: float = -INF
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


		func centroid(points) -> RecognizerPoint:
			var x: float = 0.0
			var y: float = 0.0
			var count: int = 0
			for point in points:
				if not is_nan(point.x) and not is_nan(point.y):
					x += point.x
					y += point.y
					count += 1
			if count > 0:
				x /= count
				y /= count
			return RecognizerPoint.new(x, y, str(0))


		func translate_to(points: Array[RecognizerPoint], pt: RecognizerPoint) -> Array[RecognizerPoint]:
			var c: RecognizerPoint = centroid(points)
			var newpoints: Array[RecognizerPoint] = []
			for point_i in range(points.size()):
				var point = points[point_i]
				var qx = point.x - c.x + pt.x
				var qy = point.y - c.y + pt.y
				newpoints.append(RecognizerPoint.new(qx, qy, point.id))
			return newpoints


		func euclidean_distance(p1: RecognizerPoint, p2: RecognizerPoint) -> float:
			return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))

		# Function to calculate the path length of a set of points
		func path_length(points: Array) -> float:
			var d: float = 0.0
			for i in range(1, points.size()):
				d += euclidean_distance(points[i-1], points[i])
			return d

		# Function to resample a set of points into n evenly spaced points
		func resample(points: Array[RecognizerPoint], n: int) -> Array[RecognizerPoint]:
			var I: float = path_length(points) / (n - 1) # Interval length
			var D: float = 0.0
			if points.is_empty():
				return []
			var new_points: Array[RecognizerPoint] = [points[0]] # Start with a copy of the first point

			var i: int = 1 # The index of the original point to look ahead in the array

			while new_points.size() < n and i < points.size():
				var prev_point: RecognizerPoint = points[i - 1]
				var current_point: RecognizerPoint = points[i]
				var d: float = euclidean_distance(prev_point, current_point)

				if (D + d) >= I:
					while (D + d) >= I and new_points.size() < n:
						var ratio: float = (I - D) / d
						var qx: float = prev_point.x + ratio * (current_point.x - prev_point.x)
						var qy: float = prev_point.y + ratio * (current_point.y - prev_point.y)
						var q: RecognizerPoint = RecognizerPoint.new(qx, qy, current_point.id)

						new_points.append(q)
						D = 0 # Reset D as we've added a new point

				else:
					D += d # Increment D by the distance between prev_point and current_point

				i += 1
			if new_points.size() < n:
				new_points.append(points[points.size() - 1])

			return new_points


		func _make_integer_coordinates(points: Array[RecognizerPoint]) -> Array[RecognizerPoint]:
			for point in points:
				point.int_x = round((point.x + 1.0) / 2.0 * (MAX_INTEGER_COORDINATE - 1))
				point.int_y = round((point.y + 1.0) / 2.0 * (MAX_INTEGER_COORDINATE - 1))
			return points;

		func _compute_lut(points) -> Array:
			var _lut: Array
			_lut.resize(LUT_SIZE)
			for lut in LUT_SIZE:
				var lut_array: PackedFloat32Array
				lut_array.resize(LUT_SIZE)
				_lut[lut] = lut_array

			for x in LUT_SIZE:
				for y in LUT_SIZE:
					var u = -1;
					var b = INF;
					for points_i in range(points.size()):
						var row = round(points[points_i].int_x / LUT_SCALE_FACTOR);
						var col = round(points[points_i].int_y / LUT_SCALE_FACTOR);
						var d = ((row - x) * (row - x)) + ((col - y) * (col - y));
						if (d < b):
							b = d
							u = points_i;
					_lut[x][y] = u;
			return _lut;

		func _init(p_name: StringName, p_points: Array[RecognizerPoint]):
			_name = p_name
			_points = p_points
			_points = resample(_points, NUMBER_POINTS)
			_points = scale(_points)
			_points = translate_to(_points, _origin)
			_points = _make_integer_coordinates(_points); # fills in (IntX, IntY) values
			_lut = _compute_lut(_points);


	func _compute_lower_bound(pts1: Array[RecognizerPoint], pts2: Array[RecognizerPoint], step: int, _lut: Array) -> Array:
		var n = pts1.size()
		var LB: PackedFloat32Array
		LB.resize(floor(n / step) + 1)
		var SAT: PackedFloat32Array
		SAT.resize(n)
		LB[0] = 0.0

		for i in range(n):
			var x: int = round(pts1[i].int_x / PointCloud.LUT_SCALE_FACTOR)
			if x < 0 or x >= PointCloud.LUT_SIZE:
				return []
			var y: int = round(pts1[i].int_y / PointCloud.LUT_SCALE_FACTOR)
			if y < 0 or y > PointCloud.LUT_SIZE:
				return []
			var index: int = _lut[x][y]
			var d: float = Vector2(pts1[i].x, pts1[i].y).distance_squared_to(Vector2(pts2[index].x, pts2[index].y))

			if i == 0:
				SAT[i] = d
			else:
				SAT[i] = SAT[i - 1] + d

			LB[0] += (n - i) * d

		var j = 1
		for i in range(step, n, step):
			# Prevent negative index access with proper bounds checking
			LB[j] = LB[0] + i * SAT[n-1] - n * SAT[max(i-1, 0)]
			j += 1

		return LB

	func _cloud_match(candidate: PointCloud, template: PointCloud, minimum_so_far: float) -> float:
		var n: int = candidate._points.size()
		if n == 0:
			return INF
		var step: int = floor(pow(n, 0.5))
		var LB1: Array = _compute_lower_bound(candidate._points, template._points, step, template._lut)
		if LB1.is_empty():
			return INF
		var LB2: Array = _compute_lower_bound(template._points, candidate._points, step, candidate._lut)
		if LB2.is_empty():
			return INF
		var j = 0
		for i in range(0, n, step):
			if LB1[j] < minimum_so_far:
				minimum_so_far = min(minimum_so_far, _cloud_distance(candidate._points, template._points, i, minimum_so_far))
			if LB2[j] < minimum_so_far:
				minimum_so_far = min(minimum_so_far, _cloud_distance(template._points, candidate._points, i, minimum_so_far))
			j = j + 1
		return minimum_so_far

	func _cloud_distance(pts1: Array[RecognizerPoint], pts2: Array[RecognizerPoint], start: int, minimum_so_far: float) -> float:
		var n: int = pts1.size();
		if n == 0:
			return INF
		var unmatched: Array = Array(); # indices for pts2 that are not matched
		unmatched.resize(n)
		for j in range(n):
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
			unmatched.remove_at(u) # remove item at index 'u'
			sum += weight * b;
			if sum >= minimum_so_far:
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
