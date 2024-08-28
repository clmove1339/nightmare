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
