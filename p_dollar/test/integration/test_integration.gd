extends GutTest

const p_dollar = preload("res://p_dollar/core/p_dollar.gd")

## Add one predefined point-cloud for each gesture.
var predefined_point_cloud: Dictionary = {
	"T":
	[
		p_dollar.RecognizerPoint.new(30, 7, str(1)),
		p_dollar.RecognizerPoint.new(103, 7, str(1)),
		p_dollar.RecognizerPoint.new(66, 7, str(2)),
		p_dollar.RecognizerPoint.new(66, 87, str(2))
	],
	"N":
	[
		p_dollar.RecognizerPoint.new(177, 92, 1),
		p_dollar.RecognizerPoint.new(177, 2, 1),
		p_dollar.RecognizerPoint.new(182, 1, 2),
		p_dollar.RecognizerPoint.new(246, 95, 2),
		p_dollar.RecognizerPoint.new(247, 87, 3),
		p_dollar.RecognizerPoint.new(247, 1, 3)
	],
	"D":
	[
		p_dollar.RecognizerPoint.new(345, 9, 1),
		p_dollar.RecognizerPoint.new(345, 87, 1),
		p_dollar.RecognizerPoint.new(351, 8, 2),
		p_dollar.RecognizerPoint.new(363, 8, 2),
		p_dollar.RecognizerPoint.new(372, 9, 2),
		p_dollar.RecognizerPoint.new(380, 11, 2),
		p_dollar.RecognizerPoint.new(386, 14, 2),
		p_dollar.RecognizerPoint.new(391, 17, 2),
		p_dollar.RecognizerPoint.new(394, 22, 2),
		p_dollar.RecognizerPoint.new(397, 28, 2),
		p_dollar.RecognizerPoint.new(399, 34, 2),
		p_dollar.RecognizerPoint.new(400, 42, 2),
		p_dollar.RecognizerPoint.new(400, 50, 2),
		p_dollar.RecognizerPoint.new(400, 56, 2),
		p_dollar.RecognizerPoint.new(399, 61, 2),
		p_dollar.RecognizerPoint.new(397, 66, 2),
		p_dollar.RecognizerPoint.new(394, 70, 2),
		p_dollar.RecognizerPoint.new(391, 74, 2),
		p_dollar.RecognizerPoint.new(386, 78, 2),
		p_dollar.RecognizerPoint.new(382, 81, 2),
		p_dollar.RecognizerPoint.new(377, 83, 2),
		p_dollar.RecognizerPoint.new(372, 85, 2),
		p_dollar.RecognizerPoint.new(367, 86, 2),
		p_dollar.RecognizerPoint.new(360, 87, 2),
		p_dollar.RecognizerPoint.new(355, 87, 2),
		p_dollar.RecognizerPoint.new(349, 86, 2)
	],
	"P":
	[
		p_dollar.RecognizerPoint.new(507, 8, 1),
		p_dollar.RecognizerPoint.new(507, 87, 1),
		p_dollar.RecognizerPoint.new(513, 7, 2),
		p_dollar.RecognizerPoint.new(528, 7, 2),
		p_dollar.RecognizerPoint.new(537, 8, 2),
		p_dollar.RecognizerPoint.new(544, 10, 2),
		p_dollar.RecognizerPoint.new(550, 12, 2),
		p_dollar.RecognizerPoint.new(555, 15, 2),
		p_dollar.RecognizerPoint.new(558, 18, 2),
		p_dollar.RecognizerPoint.new(560, 22, 2),
		p_dollar.RecognizerPoint.new(561, 27, 2),
		p_dollar.RecognizerPoint.new(562, 33, 2),
		p_dollar.RecognizerPoint.new(561, 37, 2),
		p_dollar.RecognizerPoint.new(559, 42, 2),
		p_dollar.RecognizerPoint.new(556, 45, 2),
		p_dollar.RecognizerPoint.new(550, 48, 2),
		p_dollar.RecognizerPoint.new(544, 51, 2),
		p_dollar.RecognizerPoint.new(538, 53, 2),
		p_dollar.RecognizerPoint.new(532, 54, 2),
		p_dollar.RecognizerPoint.new(525, 55, 2),
		p_dollar.RecognizerPoint.new(519, 55, 2),
		p_dollar.RecognizerPoint.new(513, 55, 2),
		p_dollar.RecognizerPoint.new(510, 55, 2)
	],
	"X":
	[
		p_dollar.RecognizerPoint.new(30, 146, 1),
		p_dollar.RecognizerPoint.new(106, 222, 1),
		p_dollar.RecognizerPoint.new(30, 225, 2),
		p_dollar.RecognizerPoint.new(106, 146, 2)
	],
	"H":
	[
		p_dollar.RecognizerPoint.new(188, 137, 1),
		p_dollar.RecognizerPoint.new(188, 225, 1),
		p_dollar.RecognizerPoint.new(188, 180, 2),
		p_dollar.RecognizerPoint.new(241, 180, 2),
		p_dollar.RecognizerPoint.new(241, 137, 3),
		p_dollar.RecognizerPoint.new(241, 225, 3)
	],
	"I":
	[
		p_dollar.RecognizerPoint.new(371, 149, 1),
		p_dollar.RecognizerPoint.new(371, 221, 1),
		p_dollar.RecognizerPoint.new(341, 149, 2),
		p_dollar.RecognizerPoint.new(401, 149, 2),
		p_dollar.RecognizerPoint.new(341, 221, 3),
		p_dollar.RecognizerPoint.new(401, 221, 3)
	],
	"exclamation":
	[
		p_dollar.RecognizerPoint.new(526, 142, 1),
		p_dollar.RecognizerPoint.new(526, 204, 1),
		p_dollar.RecognizerPoint.new(526, 221, 2)
	],
	"line": [p_dollar.RecognizerPoint.new(12, 347, 1), p_dollar.RecognizerPoint.new(119, 347, 1)],
	"five-point star":
	[
		p_dollar.RecognizerPoint.new(177, 396, 1),
		p_dollar.RecognizerPoint.new(223, 299, 1),
		p_dollar.RecognizerPoint.new(262, 396, 1),
		p_dollar.RecognizerPoint.new(168, 332, 1),
		p_dollar.RecognizerPoint.new(278, 332, 1),
		p_dollar.RecognizerPoint.new(184, 397, 1)
	],
	"null":
	[
		p_dollar.RecognizerPoint.new(382, 310, 1),
		p_dollar.RecognizerPoint.new(377, 308, 1),
		p_dollar.RecognizerPoint.new(373, 307, 1),
		p_dollar.RecognizerPoint.new(366, 307, 1),
		p_dollar.RecognizerPoint.new(360, 310, 1),
		p_dollar.RecognizerPoint.new(356, 313, 1),
		p_dollar.RecognizerPoint.new(353, 316, 1),
		p_dollar.RecognizerPoint.new(349, 321, 1),
		p_dollar.RecognizerPoint.new(347, 326, 1),
		p_dollar.RecognizerPoint.new(344, 331, 1),
		p_dollar.RecognizerPoint.new(342, 337, 1),
		p_dollar.RecognizerPoint.new(341, 343, 1),
		p_dollar.RecognizerPoint.new(341, 350, 1),
		p_dollar.RecognizerPoint.new(341, 358, 1),
		p_dollar.RecognizerPoint.new(342, 362, 1),
		p_dollar.RecognizerPoint.new(344, 366, 1),
		p_dollar.RecognizerPoint.new(347, 370, 1),
		p_dollar.RecognizerPoint.new(351, 374, 1),
		p_dollar.RecognizerPoint.new(356, 379, 1),
		p_dollar.RecognizerPoint.new(361, 382, 1),
		p_dollar.RecognizerPoint.new(368, 385, 1),
		p_dollar.RecognizerPoint.new(374, 387, 1),
		p_dollar.RecognizerPoint.new(381, 387, 1),
		p_dollar.RecognizerPoint.new(390, 387, 1),
		p_dollar.RecognizerPoint.new(397, 385, 1),
		p_dollar.RecognizerPoint.new(404, 382, 1),
		p_dollar.RecognizerPoint.new(408, 378, 1),
		p_dollar.RecognizerPoint.new(412, 373, 1),
		p_dollar.RecognizerPoint.new(416, 367, 1),
		p_dollar.RecognizerPoint.new(418, 361, 1),
		p_dollar.RecognizerPoint.new(419, 353, 1),
		p_dollar.RecognizerPoint.new(418, 346, 1),
		p_dollar.RecognizerPoint.new(417, 341, 1),
		p_dollar.RecognizerPoint.new(416, 336, 1),
		p_dollar.RecognizerPoint.new(413, 331, 1),
		p_dollar.RecognizerPoint.new(410, 326, 1),
		p_dollar.RecognizerPoint.new(404, 320, 1),
		p_dollar.RecognizerPoint.new(400, 317, 1),
		p_dollar.RecognizerPoint.new(393, 313, 1),
		p_dollar.RecognizerPoint.new(392, 312, 1),
		p_dollar.RecognizerPoint.new(418, 309, 2),
		p_dollar.RecognizerPoint.new(337, 390, 2)
	],
	"arrowhead":
	[
		p_dollar.RecognizerPoint.new(506, 349, 1),
		p_dollar.RecognizerPoint.new(574, 349, 1),
		p_dollar.RecognizerPoint.new(525, 306, 2),
		p_dollar.RecognizerPoint.new(584, 349, 2),
		p_dollar.RecognizerPoint.new(525, 388, 2)
	],
	"pitchfork":
	[
		p_dollar.RecognizerPoint.new(38, 470, 1),
		p_dollar.RecognizerPoint.new(36, 476, 1),
		p_dollar.RecognizerPoint.new(36, 482, 1),
		p_dollar.RecognizerPoint.new(37, 489, 1),
		p_dollar.RecognizerPoint.new(39, 496, 1),
		p_dollar.RecognizerPoint.new(42, 500, 1),
		p_dollar.RecognizerPoint.new(46, 503, 1),
		p_dollar.RecognizerPoint.new(50, 507, 1),
		p_dollar.RecognizerPoint.new(56, 509, 1),
		p_dollar.RecognizerPoint.new(63, 509, 1),
		p_dollar.RecognizerPoint.new(70, 508, 1),
		p_dollar.RecognizerPoint.new(75, 506, 1),
		p_dollar.RecognizerPoint.new(79, 503, 1),
		p_dollar.RecognizerPoint.new(82, 499, 1),
		p_dollar.RecognizerPoint.new(85, 493, 1),
		p_dollar.RecognizerPoint.new(87, 487, 1),
		p_dollar.RecognizerPoint.new(88, 480, 1),
		p_dollar.RecognizerPoint.new(88, 474, 1),
		p_dollar.RecognizerPoint.new(87, 468, 1),
		p_dollar.RecognizerPoint.new(62, 464, 2),
		p_dollar.RecognizerPoint.new(62, 571, 2)
	],
	"six-point star":
	[
		p_dollar.RecognizerPoint.new(177, 554, 1),
		p_dollar.RecognizerPoint.new(223, 476, 1),
		p_dollar.RecognizerPoint.new(268, 554, 1),
		p_dollar.RecognizerPoint.new(183, 554, 1),
		p_dollar.RecognizerPoint.new(177, 490, 2),
		p_dollar.RecognizerPoint.new(223, 568, 2),
		p_dollar.RecognizerPoint.new(268, 490, 2),
		p_dollar.RecognizerPoint.new(183, 490, 2)
	],
	"asterisk":
	[
		p_dollar.RecognizerPoint.new(325, 499, 1),
		p_dollar.RecognizerPoint.new(417, 557, 1),
		p_dollar.RecognizerPoint.new(417, 499, 2),
		p_dollar.RecognizerPoint.new(325, 557, 2),
		p_dollar.RecognizerPoint.new(371, 486, 3),
		p_dollar.RecognizerPoint.new(371, 571, 3)
	],
	"half-note":
	[
		p_dollar.RecognizerPoint.new(546, 465, 1),
		p_dollar.RecognizerPoint.new(546, 531, 1),
		p_dollar.RecognizerPoint.new(540, 530, 2),
		p_dollar.RecognizerPoint.new(536, 529, 2),
		p_dollar.RecognizerPoint.new(533, 528, 2),
		p_dollar.RecognizerPoint.new(529, 529, 2),
		p_dollar.RecognizerPoint.new(524, 530, 2),
		p_dollar.RecognizerPoint.new(520, 532, 2),
		p_dollar.RecognizerPoint.new(515, 535, 2),
		p_dollar.RecognizerPoint.new(511, 539, 2),
		p_dollar.RecognizerPoint.new(508, 545, 2),
		p_dollar.RecognizerPoint.new(506, 548, 2),
		p_dollar.RecognizerPoint.new(506, 554, 2),
		p_dollar.RecognizerPoint.new(509, 558, 2),
		p_dollar.RecognizerPoint.new(512, 561, 2),
		p_dollar.RecognizerPoint.new(517, 564, 2),
		p_dollar.RecognizerPoint.new(521, 564, 2),
		p_dollar.RecognizerPoint.new(527, 563, 2),
		p_dollar.RecognizerPoint.new(531, 560, 2),
		p_dollar.RecognizerPoint.new(535, 557, 2),
		p_dollar.RecognizerPoint.new(538, 553, 2),
		p_dollar.RecognizerPoint.new(542, 548, 2),
		p_dollar.RecognizerPoint.new(544, 544, 2),
		p_dollar.RecognizerPoint.new(546, 540, 2),
		p_dollar.RecognizerPoint.new(546, 536, 2)
	]
}

func test_assert_eq_integration_point_cloud_equal():
	var gesture = "half-note"
	var points = predefined_point_cloud[gesture]
	var new_points: Array[p_dollar.RecognizerPoint]
	for point in points:
		new_points.push_back(point)
	var point_cloud = p_dollar.PointCloud.new(gesture, new_points)
	assert_eq(p_dollar.PointCloud.NUMBER_POINTS, point_cloud._points.size(), "Should be equal.")
	

func test_assert_eq_integration_string_equal():
	var recognizer: p_dollar.PDollarRecognizer = p_dollar.PDollarRecognizer.new()
	for gesture in predefined_point_cloud.keys():
		var points = predefined_point_cloud[gesture]
		var new_points: Array[p_dollar.RecognizerPoint]
		for point in points:
			new_points.push_back(point)
		recognizer.add_gesture(gesture, new_points)

	for gesture in predefined_point_cloud.keys():
		var points = predefined_point_cloud[gesture]
		var new_points: Array[p_dollar.RecognizerPoint]
		new_points.resize(points.size())
		for point_i in range(points.size()):
			new_points[point_i] = points[point_i]
		var result: p_dollar.RecognizerResult = recognizer.recognize(new_points)
		assert_eq(gesture, result.name, "Test gesture %s: score: %f time: %f" %[result.name, result.score, result.time])

