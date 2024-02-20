varying vec3 fragmentNormal;

#ifdef VERTEX

uniform mat4 modelToScreen;

attribute vec3 VertexNormal;

vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
	fragmentNormal = VertexNormal;
	vec4 ret = modelToScreen * homogenVertexPosition;
	ret.y *= -1.0;
	return ret;
}

#endif

#ifdef PIXEL

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	return vec4(fragmentNormal / 2.0 + 0.5, 1.0);
}

#endif
