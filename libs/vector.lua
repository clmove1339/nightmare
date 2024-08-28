-- Люблю маму никсера
-- Кто нибудь вставьте или напишите эту либу сюда
-- я не знаю нуу вроде вот, добавьте нужные методы, если их тут нет
-- upd #1: БАНАН НАПИШИ ТАЙПИНГИ, ОНО ПОЧЕМУ-ТО НЕ ВИДИТ ТО ЧТО У ЕБУЧЕГО vec3_t ПОЯВИЛСЯ :length() и т.д.
-- upd #2: ГОТОВО БОСС
-- upd #3: ЕЩЕ РАЗ ТЫ ТРОНЕШЬ МОЕГО ЕНОТА
-- upd #4: Я ТРОНУЛ

--#region: vec2_t
---@diagnostic disable-next-line: circle-doc-class
---@class vec2_t: vec2_t
---@operator add: vec2_t
---@operator sub: vec2_t
---@operator mul: vec2_t
---@operator div: vec2_t
---@operator unm: vec2_t
---@operator concat: string

function vec2_t:unpack()
    return self.x, self.y;
end;

function vec2_t:__tostring()
    return string.format('vec2_t(%s, %s)', self:unpack());
end;

function vec2_t:__concat()
    return string.format('vec2_t(%s, %s)', self:unpack());
end;

function vec2_t:__add(vector)
    if typeof(vector) == 'number' then
        vector = vec2_t.new(vector, vector);
    end;

    return vec2_t.new(self.x + vector.x, self.y + vector.y);
end;

function vec2_t:__sub(vector)
    if typeof(vector) == 'number' then
        vector = vec2_t.new(vector, vector);
    end;

    return vec2_t.new(self.x - vector.x, self.y - vector.y);
end;

function vec2_t:__mul(vector)
    if typeof(vector) == 'number' then
        vector = vec2_t.new(vector, vector);
    end;

    return vec2_t.new(self.x * vector.x, self.y * vector.y);
end;

function vec2_t:__div(vector)
    if typeof(vector) == 'number' then
        vector = vec2_t.new(vector, vector);
    end;

    return vec2_t.new(self.x / vector.x, self.y / vector.y);
end;

function vec2_t:__unm()
    return self * -1;
end;

--#endregion

--#region: vec3_t
---@diagnostic disable-next-line: circle-doc-class
---@class vec3_t: vec3_t
---@operator add: vec3_t
---@operator sub: vec3_t
---@operator mul: vec3_t
---@operator div: vec3_t
---@operator unm: vec3_t
---@operator concat: string
---@field normalize fun(self: vec3_t): vec3_t Returns the normalized vector (a vector with the same direction but a length of 1)
---@field length2d fun(self: vec3_t): number Returns the length of the vector in 2D (using only the X and Y components).
---@field length fun(self: vec3_t): number  Returns the length of the vector in 3D (considering all three components: X, Y, Z).
---@field to_angle fun(self: vec3_t): angle_t  Converts the vector into an angle (useful for systems dealing with rotations).
---@field angle_to fun(self: vec3_t, vector: vec3_t): angle_t Returns the angle between this vector and another vector.
---@field forward fun(self: vec3_t): vec3_t Returns the normalized vector representing the direction of this vector.
---@field angles fun(pitch: number, yaw: number): vec3_t Creates a vector from the given angles (pitch - vertical angle, yaw - horizontal angle).
---@field dist fun(self: vec3_t, vector: vec3_t): number Returns the distance between this vector and another vector.
---@field length2d_sqr fun(self: vec3_t): number
---@field dot fun(self: vec3_t): number
---@field transform fun(self: vec3_t, matrix: table)

function vec3_t:unpack()
    return self.x, self.y, self.z;
end;

function vec3_t:__tostring()
    return string.format('vec3_t(%s, %s, %s)', self:unpack());
end;

function vec3_t:__concat()
    return string.format('vec3_t(%s, %s, %s)', self:unpack());
end;

function vec3_t:__add(vector)
    if typeof(vector) == 'number' then
        vector = self.new(vector, vector, vector);
    end;

    return vec3_t.new(self.x + vector.x, self.y + vector.y, self.z + vector.z);
end;

function vec3_t:__sub(vector)
    if typeof(vector) == 'number' then
        vector = self.new(vector, vector, vector);
    end;

    return vec3_t.new(self.x - vector.x, self.y - vector.y, self.z - vector.z);
end;

function vec3_t:__mul(vector)
    if typeof(vector) == 'number' then
        vector = self.new(vector, vector, vector);
    end;

    return vec3_t.new(self.x * vector.x, self.y * vector.y, self.z * vector.z);
end;

function vec3_t:__div(vector)
    if typeof(vector) == 'number' then
        vector = self.new(vector, vector, vector);
    end;

    return vec3_t.new(self.x / vector.x, self.y / vector.y, self.z / vector.z);
end;

function vec3_t:__unm()
    return self * -1;
end;

function vec3_t:length2d()
    return math.sqrt(self.x * self.x + self.y * self.y);
end;

function vec3_t:length2d_sqr()
    return self.x * self.x + self.y * self.y;
end;

function vec3_t:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
end;

function vec3_t:length_sqr()
    return self.x * self.x + self.y * self.y + self.z * self.z;
end;

function vec3_t:normalize()
    return self / self:length();
end;

function vec3_t:to_angle()
    local hyp2d = math.sqrt(self.x * self.x + self.y * self.y);

    local pitch = math.deg(math.atan2(-self.z, hyp2d));
    local yaw = math.deg(math.atan2(self.y, self.x));

    yaw = normalize_yaw(yaw);

    return angle_t.new(pitch, yaw, 0);
end;

function vec3_t:angle_to(vector)
    local direction = vec3_t.new(vector.x - self.x, vector.y - self.y, vector.z - self.z);
    local length = direction:length();

    local pitch = -math.deg(math.asin(direction.z / length));
    local yaw = math.deg(math.atan2(direction.y, direction.x));

    yaw = normalize_yaw(yaw);

    return angle_t.new(pitch, yaw, 0);
end;

function vec3_t:forward()
    local rx, ry = math.rad(self.x), math.rad(self.y);
    local cp, sp = math.cos(rx), math.sin(rx);
    local cy, sy = math.cos(ry), math.sin(ry);

    return vec3_t.new(cp * cy, cp * sy, -sp);
end;

function vec3_t:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z;
end;

function vec3_t.angles(pitch, yaw)
    pitch = pitch or 0;
    yaw = yaw or 0;

    local rx, ry = math.rad(pitch), math.rad(yaw);
    local cp, sp = math.cos(rx), math.sin(rx);
    local cy, sy = math.cos(ry), math.sin(ry);

    return vec3_t.new(cp * cy, cp * sy, -sp);
end;

function vec3_t:transform(matrix)
    return vec3_t.new(
        self.x * matrix[0] + self.y * matrix[1] + self.z * matrix[2] + matrix[3],
        self.x * matrix[4] + self.y * matrix[5] + self.z * matrix[6] + matrix[7],
        self.x * matrix[8] + self.y * matrix[9] + self.z * matrix[10] + matrix[11]
    );
end;

function vec3_t:dist(vector)
    return (self - vector):length();
end;

--#endregion

--#region: angle_t
---@diagnostic disable-next-line: circle-doc-class
---@class angle_t: angle_t
---@field forward fun(self: angle_t): vec3_t Returns the normalized vector representing the direction of this vector.

function angle_t:forward()
    local pitch_rad = math.rad(self.pitch);
    local yaw_rad = math.rad(self.yaw);

    return vec3_t.new(math.cos(pitch_rad) * math.cos(yaw_rad), math.cos(pitch_rad) * math.sin(yaw_rad), -math.sin(pitch_rad));
end;

--#endregion
