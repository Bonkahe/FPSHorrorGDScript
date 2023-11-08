shader_type spatial;
render_mode depth_draw_opaque;
//render_mode unshaded;
// Raymarching constants
uniform float SURFACE_DST = .01;

uniform int MAX_STEPS: hint_range(1,64) = 64;
instance uniform float maxsteps_instancecontrol = 64;
uniform float MAX_DISTANCE = 256.0;
uniform float NORMAL_STEP = 0.5;


uniform float noise_scale = 1.0;
uniform vec3 noise_transform;
uniform float density_threshold = 0.5;
uniform float deformation = 0.0;
uniform float anim_speed = 0.0;

instance uniform float emission_power = 0.0;
uniform float max_mandelbrot_dist = 1.5;
uniform int mandelbrot_steps: hint_range(1,128) = 64;
instance uniform float madelbrot_scale : hint_range(0.001,2) = 0.848;
uniform float madelbrot_originscale = 1;

uniform float MARCHINGSTEP = 0.1;

uniform vec4 mandelbrot_color : source_color = vec4(0.3,0.5,0.1,1.0);
uniform vec4 mandelbrot_a_color  : source_color =  vec4(0.5,0.5,0.5, 1.0);
uniform vec4 mandelbrot_noisecontrol_color : source_color = vec4(0.01,0.01,0.01, 1.0);
//
//uniform vec4 albedo : source_color;
//uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
//uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
//uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
//uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
//uniform float normal_scale : hint_range(-16,16);
//
//varying vec3 uv1_triplanar_pos;
//uniform float uv1_blend_sharpness;
//varying vec3 uv1_power_normal;
//uniform vec3 uv1_scale;
//uniform vec3 uv1_offset;

//uniform float time_scale;
//varying float time;
instance uniform float time;

void vertex() {
	//time = TIME * time_scale;
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

// distance estimator to a mandelbulb set
// returns the distance to the set on the x coordinate 
// and the color on the y coordinate
vec2 DE(vec3 pos) {
    float Power = 3.0+4.0*(sin(time/20.0)+1.5);
	vec3 z = pos * madelbrot_scale;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < mandelbrot_steps ; i++) {
		r = length(z);
		if (r>max_mandelbrot_dist) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow(r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return vec2(0.5*log(r)*r/dr,50.0*pow(dr,0.128/float(MAX_STEPS)));
}

// MAPPING FUNCTION ... 
// returns the distance of the nearest object in the direction p on the x coordinate 
// and the color on the y coordinate
vec2 mapMandel(vec3 pos )
{
    //p = fract(p); 
   	vec2 d = DE(pos);
	//d = min(d, noise);
   	return d;
}
//vec3 palette (float t) {
//    return cosineColor( t, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(0.01,0.01,0.01),vec3(0.00, 0.15, 0.20) );
//}

vec2 RayMarchMadelBrot(vec3 ro, vec3 rd) {
	float d = 0.0;
	float c = 0.0;
	int curSteps = int(maxsteps_instancecontrol);
	if (curSteps % 2 == 1){
		curSteps = curSteps + 1;
	}
	
	for (int i = 0; i < curSteps; i++) {
		vec3 pos = (ro * madelbrot_originscale) + rd * d;
		//float sceneDst = Scene(pos, objectpos);
		vec2 dist = mapMandel(pos);
		//dist.x = max(dist.x, noise3D(pos - objectpos) * density_threshold);
		//d += sceneDst.x;
		
		// Only stop if distance is higher than MAX_DISTANCE or sampled distance
		// is less that surface threshold
		//if (d > MAX_DISTANCE || abs(sceneDst.y) <= SURFACE_DST) break;		
        d += dist.x;
        c += dist.y;
        if (d > MAX_DISTANCE || abs(dist.y) < SURFACE_DST) break;
	}
	return vec2(d,c);
}

// Sample the world normal in the contact position
vec3 Normal(vec3 pos) {
	float d = mapMandel(pos).x;
	vec2 e = vec2(NORMAL_STEP, 0.0);
	vec3 n = d - vec3(
		mapMandel(pos - e.xyy).x,
		mapMandel(pos - e.yxy).x,
		mapMandel(pos - e.yyx).x);
	return normalize(n);
}

vec3 cosineColor( float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

//// Rotation matrix from angle
//mat3 rotateY(float theta) {
//    float c = cos(theta);
//    float s = sin(theta);
//    return mat3(
//        vec3(c, 0, s),
//        vec3(0, 1, 0),
//        vec3(-s, 0, c)
//    );
//}
//
//float spaceWarp(vec3 p) {
//	return pow(2.0 * length(p), deformation)/ 2.0;
//}
//
//vec3 random3D(vec3 uvw){
//
//    uvw = vec3( dot(uvw, vec3(127.1,311.7, 513.7) ),
//               dot(uvw, vec3(269.5,183.3, 396.5) ),
//			   dot(uvw, vec3(421.3,314.1, 119.7) ) );
//
//    return -1.0 + 2.0 * fract(sin(uvw) * 43758.5453123);
//}
//
//float noise3D(vec3 uvw){
//	uvw *= spaceWarp(uvw) * noise_scale;
//	uvw += vec3(noise_transform.x + sin(TIME * anim_speed),
//				noise_transform.y + sin(TIME * anim_speed + 0.5),
//				noise_transform.z + sin(TIME * anim_speed + 1.5));
//
//	vec3 gridIndex = floor(uvw); 
//	vec3 gridFract = fract(uvw);
//
//	vec3 blur = smoothstep(0.0, 1.0, gridFract);
//
//	vec3 blb = gridIndex + vec3(0.0, 0.0, 0.0);
//	vec3 brb = gridIndex + vec3(1.0, 0.0, 0.0);
//	vec3 tlb = gridIndex + vec3(0.0, 1.0, 0.0);
//	vec3 trb = gridIndex + vec3(1.0, 1.0, 0.0);
//	vec3 blf = gridIndex + vec3(0.0, 0.0, 1.0);
//	vec3 brf = gridIndex + vec3(1.0, 0.0, 1.0);
//	vec3 tlf = gridIndex + vec3(0.0, 1.0, 1.0);
//	vec3 trf = gridIndex + vec3(1.0, 1.0, 1.0);
//
//	vec3 gradBLB = random3D(blb); 
//	vec3 gradBRB = random3D(brb);
//	vec3 gradTLB = random3D(tlb);
//	vec3 gradTRB = random3D(trb);
//	vec3 gradBLF = random3D(blf);
//	vec3 gradBRF = random3D(brf);
//	vec3 gradTLF = random3D(tlf);
//	vec3 gradTRF = random3D(trf);
//
//
//	vec3 distToPixelFromBLB = gridFract - vec3(0.0, 0.0, 0.0);
//	vec3 distToPixelFromBRB = gridFract - vec3(1.0, 0.0, 0.0);
//	vec3 distToPixelFromTLB = gridFract - vec3(0.0, 1.0, 0.0);
//	vec3 distToPixelFromTRB = gridFract - vec3(1.0, 1.0, 0.0);
//	vec3 distToPixelFromBLF = gridFract - vec3(0.0, 0.0, 1.0);
//	vec3 distToPixelFromBRF = gridFract - vec3(1.0, 0.0, 1.0);
//	vec3 distToPixelFromTLF = gridFract - vec3(0.0, 1.0, 1.0);
//	vec3 distToPixelFromTRF = gridFract - vec3(1.0, 1.0, 1.0);
//
//	float dotBLB = dot(gradBLB, distToPixelFromBLB);
//	float dotBRB = dot(gradBRB, distToPixelFromBRB);
//	float dotTLB = dot(gradTLB, distToPixelFromTLB);
//	float dotTRB = dot(gradTRB, distToPixelFromTRB);
//	float dotBLF = dot(gradBLF, distToPixelFromBLF);
//	float dotBRF = dot(gradBRF, distToPixelFromBRF);
//	float dotTLF = dot(gradTLF, distToPixelFromTLF);
//	float dotTRF = dot(gradTRF, distToPixelFromTRF);
//
//
//	return mix(
//		mix(
//			mix(dotBLB, dotBRB, blur.x),
//			mix(dotTLB, dotTRB, blur.x), blur.y
//		),
//		mix(
//			mix(dotBLF, dotBRF, blur.x),
//			mix(dotTLF, dotTRF, blur.x), blur.y
//		), blur.z
//	) + 0.5;
//}
//
//// Torus signed distance field function
//float SDFTorus(vec3 p, float innerRadius, float radius) {
//	vec2 q = vec2(length(p.xz) - radius, p.y);
//	return length(q) - innerRadius;
//}
//
//// Sphere signed distance field function
//float SDFSphere(vec3 p, float radius) {
//	//return mapMandel(p);
//	//return min(mapMandel(p), length(p) - radius);
//	return length(p) - radius;
//}
//
//// Box signed distance field function
//float SDFBox(vec3 p, vec3 size) {
//	vec3 d = abs(p) - size;
//	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
//}
//
//
//// Sample the whole scene, you can mix multiple shapes here
//float Scene(vec3 pos, vec3 objectpos) {
//	// Torus
//	float dst = SDFTorus(pos - objectpos, 0.5, 3.0);
//
//	// Rotating spheres
//	vec3 spOff1 = vec3(cos(time * 3.1415), 0.0, sin(time * 3.1415)) * 3.0;
//	vec3 spOff2 = vec3(cos((time + 1.0) * 3.1415), 0.0, sin((time + 1.0) * 3.1415)) * 3.0;
//	dst = min(dst, SDFSphere(pos + spOff1 - objectpos, 1.0));
//	dst = min(dst, SDFSphere(pos + spOff2 - objectpos, 1.0));
//
//	// Warping box
//	vec3 boxPos = pos - objectpos;
//	//boxPos.z += cos(boxPos.y * 3.1415 * 0.5) * 0.5 - 1.0;
//	boxPos = rotateY(boxPos.y * 3.1415 * 0.2) * boxPos;
//	dst = min(dst, SDFBox(boxPos, vec3(1.0, 4.0, 1.0)));
//
//	dst = dst - noise3D(pos - objectpos);
//	//return dst;
//	return mapMandel(pos- objectpos).x;
//}
//
//// The actual raymarching function
//float RayMarch(vec3 ro, vec3 rd, vec3 objectpos) {
//	float d = 0.0;
//	for (int i = 0; i < MAX_STEPS; i++) {
//		vec3 pos = ro + rd * d;
//		//float sceneDst = Scene(pos, objectpos);
//		vec2 sceneDst = mapMandel(pos- objectpos);
//
//		d += sceneDst.x;
//
//		// Only stop if distance is higher than MAX_DISTANCE or sampled distance
//		// is less that surface threshold
//		if (d > MAX_DISTANCE || abs(sceneDst.y) <= SURFACE_DST) break;		
//	}
//	return d;
//}

//vec2 trace  (vec3 origin, vec3 ray) {
//
//    //t is the point at which we are in the measuring of the distance
//    float t =0.0;
//    float c = 0.0;
//
//    for (int i=0; i<MAX_STEPS; i++) {
//    	vec3 path = origin + ray * t;	
//    	vec2 dist = mapMandel(path);
//    	// we want t to be as large as possible at each step but not too big to induce artifacts
//        t += MARCHINGSTEP * dist.x;
//        c += dist.y;
//        if (dist.y < SURFACE_DST) break;
//    }
//
//    return vec2(t,c);
//}



void fragment() {
	// Get the pixel world coordinates
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Get the camera position
	vec3 camera = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	
	// Raymarching direction
	vec3 dir = normalize(world - camera);
	
	// Starts just a bit off the mesh surface
	//vec3 ro = MODEL_MATRIX  ;
	//vec3 rd = dir;
	vec3 ro = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	vec3 rd = (transpose(MODEL_MATRIX) * vec4(dir, 1.0)).xyz;
	//vec3 ro = (vec4(world, 1.0) * ((MODEL_MATRIX))).xyz;
	//vec3 rd = dir * (mat3(MODEL_MATRIX));
	vec3 objecttransform = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	//vec3 objecttransform = vec3(0,0,0);
	//vec3 objecttransform = ((MODEL_MATRIX) * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	// Raymarch
	//float d = RayMarch(ro, rd, objecttransform);
	vec2 depth = RayMarchMadelBrot(ro, rd);
	
	if (depth.x >= MAX_DISTANCE) discard;
	
	// Set the world position from the raymarching output
	//world = (ro + rd * (depth.x - length(dir)));
	//world = (MODEL_MATRIX * vec4(world, 1.0)).xyz;
	// Samples world normal
	world = (inverse(MODEL_MATRIX) * vec4(world + dir * depth.x, 1.0)).xyz;
	vec3 n = Normal(world);
	// Set the local normal relative to the view
	NORMAL = (VIEW_MATRIX * vec4(n, 0.0)).xyz;

	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	
//	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
//	uv1_triplanar_pos = world * uv1_scale + uv1_offset;
//	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
//	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	//vec4 albedo_tex = triplanar_texture(texture_albedo,uv1_power_normal,uv1_triplanar_pos);
	//ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	float fog = 1.0 / (1.0 + depth.x * depth.y * 0.1);
	vec3 fc =vec3(fog);
	//vec3 cosine = vec3( depth.y / (max_mandelbrot_dist / SURFACE_DST));
	vec3 cosine = cosineColor( depth.y, mandelbrot_color.xyz,mandelbrot_a_color.xyz,mandelbrot_noisecontrol_color.xyz,vec3(0.00, 0.15, 0.20));

	vec3 fragColor = vec3(cosine * fog);
	ALBEDO = fragColor;
	EMISSION = fragColor * emission_power;
	//vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	//float roughness_tex = dot(triplanar_texture(texture_roughness,uv1_power_normal,uv1_triplanar_pos),roughness_texture_channel);
	ROUGHNESS = roughness;
	SPECULAR = specular;
	//NORMAL_MAP = triplanar_texture(texture_normal,uv1_power_normal,uv1_triplanar_pos).rgb;
	//NORMAL_MAP_DEPTH = normal_scale;
	// Depth calculation, this makes possible for other meshes intersect
	// properly with the geometry
//	vec4 ndc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
//	float depthfinal = (ndc.z / ndc.w);
//	DEPTH = depthfinal;
}