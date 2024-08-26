-- Люблю маму никсера
-- Кто нибудь вставьте или напишите эту либу сюда
-- я не знаю нуу вроде вот, добавьте нужные методы, если их тут нет
-- upd: БАНАН НАПИШИ ТАЙПИНГИ, ОНО ПОЧЕМУ-ТО НЕ ВИДИТ ТО ЧТО У ЕБУЧЕГО vec3_t ПОЯВИЛСЯ :length() и т.д.

-- region vector2

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

--endregion

-- region vector3

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

function vec3_t:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
end;

function vec3_t:to_angle()
    local pitch = math.deg(math.atan2(-self.z, math.sqrt(self.x * self.x + self.y * self.y)));
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

function vec3_t.angles(pitch, yaw)
    pitch = pitch or 0;
    yaw = yaw or 0;

    local rx, ry = math.rad(pitch), math.rad(yaw);
    local cp, sp = math.cos(rx), math.sin(rx);
    local cy, sy = math.cos(ry), math.sin(ry);

    return vec3_t.new(cp * cy, cp * sy, -sp);
end;

function vec3_t:distance_to(vector)
    return (self - vector):length();
end;

-- endregion
