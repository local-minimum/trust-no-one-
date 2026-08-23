extends MeshInstance3D
class_name Line3D

@export var _points: Array[Vector3] = []
## Will remove points from the beginning when exceeding this threshold
@export var max_points: int = 60
@export var start_thickness: float = 0.1
@export var end_thickness: float = 0.1
## Smoothing steps on corners, 0 means no smoothing
@export var corner_smooth: int = 5
## Smoothing steps on caps, 0 means no smoothing
@export var cap_smooth: int = 5
## This does not apply to corners
@export var constant_scale_texture: bool = true

var _dirty: bool = false

func _ready() -> void:
    if !mesh:
        mesh = ImmediateMesh.new()

func add_global_point(pt: Vector3) -> void:
    if _points.size() >= max_points:
        _points = _points.slice(1, max_points - 1)
    _points.append(to_local(pt))
    _dirty = true

func clear_points() -> void:
    _points.clear()
    mesh.clear_surfaces()
    _dirty = true

func is_showing() -> bool:
    return _points.size() > 1

func _process(_delta: float) -> void:
    if !_dirty || _points.size() < 2:
        return

    var camera: Camera3D = get_viewport().get_camera_3d()
    if camera == null:
        return

    var draw_caps: bool = cap_smooth > 0
    var draw_corners: bool = corner_smooth > 0
    var constant_thickness: bool = start_thickness == end_thickness

    var camera_origin: Vector3 = to_local(camera.get_global_transform().origin)

    var progress_step: float = 1.0 / _points.size()
    var progress: float = 0

    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

    for i: int in range(_points.size() - 1):
        var thickness: float = start_thickness if constant_thickness else lerp(start_thickness, end_thickness, progress)
        var next_thickness: float = start_thickness if constant_thickness else lerp(start_thickness, end_thickness, progress + progress_step)
        var start: Vector3 = _points[i]
        var end: Vector3 = _points[i + 1]
        var mid: Vector3 = (start + end) * 0.5

        var delta: Vector3 = end - start
        var camera_vector: Vector3 = camera_origin - mid
        var orthogonal_start: Vector3 = camera_vector.cross(delta).normalized() * thickness * 0.5
        var orthogonal_end: Vector3 = camera_vector.cross(delta).normalized() * next_thickness * 0.5

        var start_right: Vector3 = start + orthogonal_start
        var start_left: Vector3 = start - orthogonal_start
        var end_right: Vector3 = end + orthogonal_end
        var end_left: Vector3 = end - orthogonal_end

        if i == 0 && draw_caps:
            cap(start, end, thickness, camera_origin)

        if constant_scale_texture:
            var segment_length: float = delta.length()
            var segment_units: float = floor(segment_length)
            var segment_frac: float = segment_length - segment_units
            _make_segment(start_right, start_left, end_right, end_left, segment_units, segment_frac)

        else:
            _make_segment(start_right, start_left, end_right, end_left)

        if i == _points.size() - 2:
            if draw_caps:
                cap(end, start, next_thickness, camera_origin)

        elif draw_corners:
            var next_end: Vector3 = _points[i + 2]

            var next_delta: Vector3 = next_end - end
            var next_mid_ortho: Vector3 = (camera_origin - ((end + next_end) * 0.5)).cross(next_delta).normalized() * next_thickness * 0.5

            if delta.dot(next_mid_ortho) > 0:
                corner(end, end_right, end + next_mid_ortho)
            else:
                corner(end, end - next_mid_ortho, end_left)

        progress += progress_step

    mesh.surface_end()
    _dirty = false

func cap(center: Vector3, pivot: Vector3, thickness: float, camera_origin: Vector3) -> void:
    var orthogonal: Vector3 = (camera_origin - center).cross(center - pivot).normalized() * thickness * 0.5
    var axis: Vector3 = (center - camera_origin).normalized()

    var array: Array[Vector3] = []
    array.resize(cap_smooth + 1)
    array.fill(Vector3.ZERO)
    array[0] = center + orthogonal
    array[cap_smooth] = center - orthogonal

    for i: int in range(1, cap_smooth):
        array[i] = center + (orthogonal.rotated(axis, lerp(0.0, PI, float(i) / cap_smooth)))

    _smooth(array, center, cap_smooth)

func corner(center: Vector3, start: Vector3, end: Vector3) -> void:
    var array: Array[Vector3] = []
    array.resize(corner_smooth + 1)
    array.fill(Vector3.ZERO)
    array[0] = start
    array[corner_smooth] = end

    var axis: Vector3 = start.cross(end).normalized()
    var offset: Vector3 = start - center

    var angle: float = offset.angle_to(end - center)
    var rounded: bool = axis != Vector3.ZERO

    for i: int in range(1, corner_smooth + 1):
        if rounded:
            array[i] = center + offset.rotated(axis, lerp(0.0, angle, float(i) / corner_smooth))
        else:
            array[i] = start.lerp(end, float(i) / corner_smooth)

    _smooth(array, center, corner_smooth)

func _smooth(array: Array[Vector3], center: Vector3, smoothing: int) -> void:
    for i: int in range(1, smoothing + 1):
        var prev_smooth: float = (i - 1) / float(smoothing)
        mesh.surface_set_uv(Vector2(0.0, prev_smooth))
        mesh.surface_add_vertex(array[i - 1])
        mesh.surface_set_uv(Vector2(0.0, prev_smooth))
        mesh.surface_add_vertex(array[i])
        mesh.surface_set_uv(Vector2(0.5, 0.5))
        mesh.surface_add_vertex(center)

func _make_segment(start_right: Vector3, start_left: Vector3, end_right: Vector3, end_left: Vector3, units: float = 1.0, frac: float = 0.0) -> void:
    mesh.surface_set_uv(Vector2(units, 0.0))
    mesh.surface_add_vertex(start_right)
    mesh.surface_set_uv(Vector2(-frac, 0.0))
    mesh.surface_add_vertex(end_right)
    mesh.surface_set_uv(Vector2(units, 1.0))
    mesh.surface_add_vertex(start_left)
    mesh.surface_set_uv(Vector2(-frac, 0.0))
    mesh.surface_add_vertex(end_right)
    mesh.surface_set_uv(Vector2(-frac, 1.0))
    mesh.surface_add_vertex(end_left)
    mesh.surface_set_uv(Vector2(units, 1.0))
    mesh.surface_add_vertex(start_left)
