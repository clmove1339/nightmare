function color_t:unpack()
    return self.r, self.g, self.b, self.a;
end;

function color_t:__tostring()
    return string.format('color_t(%s, %s, %s, %s)', self:unpack());
end;

function color_t:__concat(other)
    return string.format('%s%s', tostring(self), tostring(other));
end;

function color_t:__eq(other)
    return
        self.r == other.r and
        self.g == other.g and
        self.b == other.b and
        self.a == other.a;
end;

function color_t:lerp(other, speed)
    local r = math.lerp(self.r, other.r, speed);
    local g = math.lerp(self.g, other.g, speed);
    local b = math.lerp(self.b, other.b, speed);
    local a = math.lerp(self.a, other.a, speed);

    return color_t.new(r, g, b, a);
end;

function color_t:alpha_modulate(alpha)
    return color_t.new(self.r, self.g, self.b, alpha);
end;

function color_t:alpha_modulatef(weight)
    return color_t.new(self.r, self.g, self.b, self.a * weight);
end;
