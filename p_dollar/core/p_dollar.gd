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
		id = str(p_id)  # stroke ID to which this point belongs (1,2,3,etc.)


class RecognizerResult:
	var name: StringName
	var score: float = 0
	var time: float = 0

	func _init(p_name: StringName, p_score: float, p_ms: float):
		name = p_name
		score = p_score
		time = p_ms


## A point-cloud template
class PointCloud:
	var _name: StringName = ""
	var _points: Array[RecognizerPoint] = []

	const number_point_clouds = 16
	const number_points = 32
	var _origin: RecognizerPoint = RecognizerPoint.new(0, 0, 0)

	func Scale(points: Array[RecognizerPoint]) -> Array[RecognizerPoint]:
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

	func Centroid(points):
		var x = 0.0
		var y = 0.0
		for point in points:
			x += point.x
			y += point.y
		x /= points.size()
		y /= points.size()
		return RecognizerPoint.new(x, y, 0)

	func TranslateTo(points: Array[RecognizerPoint], pt: RecognizerPoint):  # translates points' centroid to points
		var c = Centroid(points)
		var newpoints: Array[RecognizerPoint]
		newpoints.resize(points.size())
		for point_i in range(points.size()):
			var point = points[point_i]
			var qx = point.x + pt.x - c.x
			var qy = point.y + pt.y - c.y
			newpoints[point_i] = RecognizerPoint.new(qx, qy, point.id)
		return newpoints

	func path_length(points: Array[RecognizerPoint]) -> float:  # length traversed by a point path
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
		var newpoints: Array[RecognizerPoint] = [p_points[0]]
		for point_i in range(1, p_points.size()):
			if p_points[point_i].id == p_points[point_i - 1].id:
				var d = Vector2(p_points[point_i - 1].x, p_points[point_i - 1].y).distance_to(
					Vector2(p_points[point_i].x, p_points[point_i].y)
				)
				if (D + d) >= I:
					var qx = p_points[point_i - 1].x + ((I - D) / d) * (p_points[point_i].x - p_points[point_i - 1].x)
					var qy = p_points[point_i - 1].y + ((I - D) / d) * (p_points[point_i].y - p_points[point_i - 1].y)
					var q = RecognizerPoint.new(qx, qy, p_points[point_i].id)
					newpoints.push_back(q)  # append new point 'q'
					p_points.insert(point_i, q)  # insert 'q' at position i in points s.t. 'q' will be the next i
					D = 0.0
				else:
					D += d
		if newpoints.size() == n - 1:  # sometimes we fall a rounding-error short of adding the last point, so add it if so
			newpoints.push_back(
				RecognizerPoint.new(
					p_points[p_points.size() - 1].x, p_points[p_points.size() - 1].y, p_points[p_points.size() - 1].id
				)
			)
		return newpoints

	func _init(p_name: StringName, p_points: Array[RecognizerPoint]):
		_name = p_name
		if not p_points.size():
			return
		_points = p_points
		_points = resample(_points, number_points)
		_points = Scale(_points)
		_points = TranslateTo(_points, _origin)


class PDollarRecognizer:
	var PointClouds: Array[PointCloud]

	func GreedyCloudMatch(points: Array[RecognizerPoint], P: PointCloud):
		var min = INF
		if not points.size():
			return min
		var e = 0.50
		var step = floor(pow(points.size(), 1.0 - e))
		for i in range(0, points.size(), step):
			var point = points[i]
			var d1 = CloudDistance(points, P._points, i)
			var d2 = CloudDistance(P._points, points, i)
			min = min(min, min(d1, d2))  # min3
		return min

	func CloudDistance(pts1, pts2, start):
		var matched: Array
		matched.resize(max(pts1.size(), pts2.size()))
		for k in pts1.size():
			matched[k] = false
		var sum = 0
		var matched_i = start
		while true:
			var index = -1
			var min = INF
			for matched_j in matched.size():
				if matched_i < -1 or matched_i >= pts1.size():
					continue
				if matched_j < -1 or matched_j >= pts2.size():
					continue
				if pts1[matched_i] == null and pts2[matched_j] == null:
					continue
				if !matched_i:
					var d = Vector2(pts1[matched_i].x, pts1[matched_i].y).distance_to(
						Vector2(pts2[matched_j].x, pts2[matched_j].y)
					)
					if d < min:
						min = d
						index = matched_j
			matched[index] = true
			var weight = 1 - ((matched_i - start + pts1.size()) % pts1.size()) / pts1.size()
			sum += weight * min
			matched_i = (matched_i + 1) % pts1.size()
			if matched_i != start:
				break
		return sum

	# The $P Point-Cloud Recognizer API begins here
	func recognize(points: Array[RecognizerPoint]) -> RecognizerResult:
		var t0 = Time.get_ticks_msec()
		var candidate: PointCloud = PointCloud.new("", points)
		var u = -1
		var b = INF
		for cloud_i in range(PointClouds.size()):  # for each point-cloud template
			var d = GreedyCloudMatch(candidate._points, PointClouds[cloud_i])
			if d < b:
				b = d  # best (least) distance
				u = cloud_i  # point-cloud index
		var t1 = Time.get_ticks_msec()
		if u == -1:
			return RecognizerResult.new("No match.", 0.0, t1 - t0)
		return RecognizerResult.new(PointClouds[u]._name, b > 1.0 if 1.0 / b else 1.0, t1 - t0)

	func AddGesture(p_name: StringName, p_points: Array[RecognizerPoint]) -> int:
		PointClouds.push_back(PointCloud.new(p_name, p_points))
		var num: int = 0
		for cloud in PointClouds:
			if cloud._name == p_name:
				num = num + 1
		return num

	func DeleteUserGestures():
		PointClouds.clear()
		PointClouds.resize(PointCloud.number_point_clouds)  # clears any beyond the original set
		return PointCloud.number_point_clouds
