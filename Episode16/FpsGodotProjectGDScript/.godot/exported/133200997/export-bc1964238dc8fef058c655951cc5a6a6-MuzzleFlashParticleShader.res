RSRC                    VisualShader            ��������                                            �      resource_local_to_scene    resource_name    output_port_for_preview    default_input_values    expanded_output_ports    input_name    script    size    expression    parameter_name 
   qualifier    default_value_enabled    default_value    op_type    billboard_type    keep_scale    source    texture    texture_type    color_default    texture_filter    texture_repeat    texture_source    interpolation_mode    interpolation_color_space    offsets    colors 	   gradient    width    height    use_hdr    fill 
   fill_from    fill_to    repeat    hint    min    max    step 	   operator 	   function    code    graph_offset    mode    modes/blend    modes/depth_draw    modes/cull    modes/diffuse    modes/specular    flags/depth_prepass_alpha    flags/depth_test_disabled    flags/sss_mode_skin    flags/unshaded    flags/wireframe    flags/skip_vertex_transform    flags/world_vertex_coords    flags/ensure_correct_normals    flags/shadows_disabled    flags/ambient_light_disabled    flags/shadow_to_opacity    flags/vertex_lighting    flags/particle_trails    flags/alpha_to_coverage     flags/alpha_to_coverage_and_one    flags/debug_shadow_splits    nodes/vertex/0/position    nodes/vertex/2/node    nodes/vertex/2/position    nodes/vertex/3/node    nodes/vertex/3/position    nodes/vertex/3/size    nodes/vertex/3/input_ports    nodes/vertex/3/output_ports    nodes/vertex/3/expression    nodes/vertex/4/node    nodes/vertex/4/position    nodes/vertex/4/size    nodes/vertex/4/input_ports    nodes/vertex/4/output_ports    nodes/vertex/4/expression    nodes/vertex/5/node    nodes/vertex/5/position    nodes/vertex/7/node    nodes/vertex/7/position    nodes/vertex/8/node    nodes/vertex/8/position    nodes/vertex/9/node    nodes/vertex/9/position    nodes/vertex/10/node    nodes/vertex/10/position    nodes/vertex/connections    nodes/fragment/0/position    nodes/fragment/2/node    nodes/fragment/2/position    nodes/fragment/3/node    nodes/fragment/3/position    nodes/fragment/4/node    nodes/fragment/4/position    nodes/fragment/5/node    nodes/fragment/5/position    nodes/fragment/6/node    nodes/fragment/6/position    nodes/fragment/8/node    nodes/fragment/8/position    nodes/fragment/9/node    nodes/fragment/9/position    nodes/fragment/10/node    nodes/fragment/10/position    nodes/fragment/11/node    nodes/fragment/11/position    nodes/fragment/12/node    nodes/fragment/12/position    nodes/fragment/13/node    nodes/fragment/13/position    nodes/fragment/14/node    nodes/fragment/14/position    nodes/fragment/15/node    nodes/fragment/15/position    nodes/fragment/16/node    nodes/fragment/16/position    nodes/fragment/17/node    nodes/fragment/17/position    nodes/fragment/18/node    nodes/fragment/18/position    nodes/fragment/19/node    nodes/fragment/19/position    nodes/fragment/20/node    nodes/fragment/20/position    nodes/fragment/21/node    nodes/fragment/21/position    nodes/fragment/connections    nodes/light/0/position    nodes/light/connections    nodes/start/0/position    nodes/start/connections    nodes/process/0/position    nodes/process/connections    nodes/collide/0/position    nodes/collide/connections    nodes/start_custom/0/position    nodes/start_custom/connections     nodes/process_custom/0/position !   nodes/process_custom/connections    nodes/sky/0/position    nodes/sky/connections    nodes/fog/0/position    nodes/fog/connections        $   local://VisualShaderNodeInput_u0xs4 Y      /   local://VisualShaderNodeGlobalExpression_qwgqo �      )   local://VisualShaderNodeExpression_w4yg5 F      $   local://VisualShaderNodeInput_2m0hx �      /   local://VisualShaderNodeBooleanParameter_i1it1 �      %   local://VisualShaderNodeSwitch_tgvoq       (   local://VisualShaderNodeBillboard_83xwo �      $   local://VisualShaderNodeInput_umloy       &   local://VisualShaderNodeTexture_x2lay Z      1   local://VisualShaderNodeTexture2DParameter_s5gkx �         local://Gradient_g3ge4 �          local://GradientTexture2D_14lej       &   local://VisualShaderNodeTexture_chbha 3      ,   local://VisualShaderNodeVectorCompose_3qjko w      1   local://VisualShaderNodeTexture2DParameter_a0b44 �      -   local://VisualShaderNodeFloatParameter_82wcn �      '   local://VisualShaderNodeVectorOp_48qnu _      $   local://VisualShaderNodeInput_sxg0i �      %   local://VisualShaderNodeUVFunc_3k7fl �      ,   local://VisualShaderNodeVectorCompose_qhpb8 �      -   local://VisualShaderNodeFloatParameter_ge4y4 f      $   local://VisualShaderNodeInput_sk2yv �      &   local://VisualShaderNodeFloatOp_t2xlm       )   local://VisualShaderNodeSmoothStep_px1uv M      &   local://VisualShaderNodeFloatOp_1cy68 x      -   local://VisualShaderNodeFloatParameter_d1mpp �      &   local://VisualShaderNodeFloatOp_74u8e       &   local://VisualShaderNodeFloatOp_qvwpg a      -   local://VisualShaderNodeFloatParameter_q470p �         local://VisualShader_pkimc �         VisualShaderNodeInput                             instance_custom       !   VisualShaderNodeGlobalExpression       
   w~�CVC      J   uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;          VisualShaderNodeExpression       
   �YDq=�C      �  	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM_Z * float(particle_total_frames));
	particle_frame = mod(particle_frame, particle_total_frames);
	
	OutputUV = CurUV;
	OutputUV /= vec2(h_frames, v_frames);
	OutputUV += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames) / v_frames);          VisualShaderNodeInput             uv       !   VisualShaderNodeBooleanParameter    	         UsebillboardParticle          VisualShaderNodeSwitch                                      �?              �?              �?                       �?              �?              �?                              VisualShaderNodeBillboard                               VisualShaderNodeInput             modelview_matrix          VisualShaderNodeTexture                                   #   VisualShaderNodeTexture2DParameter    	         Albedo       	   Gradient             GradientTexture2D             
            VisualShaderNodeTexture                                  VisualShaderNodeVectorCompose                    #   VisualShaderNodeTexture2DParameter    	         ColorGradient          VisualShaderNodeFloatParameter    	         EmissionPower #         %         @         VisualShaderNodeVectorOp    '                  VisualShaderNodeInput             uv          VisualShaderNodeUVFunc             VisualShaderNodeVectorCompose                         �?                                             VisualShaderNodeFloatParameter    	         EdgeYUV #                          �?         VisualShaderNodeInput                             color          VisualShaderNodeFloatOp    '                  VisualShaderNodeSmoothStep             VisualShaderNodeFloatOp    '                  VisualShaderNodeFloatParameter    	         EdgeSharpness #                  VisualShaderNodeFloatOp                                       @'                  VisualShaderNodeFloatOp             VisualShaderNodeFloatParameter    	         AlphaCutoff #                  VisualShader E   )      �  shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform bool UsebillboardParticle;
uniform float EdgeYUV : hint_range(0, 1) = 1;
uniform sampler2D Albedo;
uniform sampler2D ColorGradient;
uniform float EmissionPower : hint_range(0, 2);


// GlobalExpression:0
	uniform int particles_anim_h_frames;
	uniform int particles_anim_v_frames;

void vertex() {
// Input:2
	vec4 n_out2p0 = INSTANCE_CUSTOM;
	float n_out2p3 = n_out2p0.b;


// Input:5
	vec2 n_out5p0 = UV;


	vec2 n_out4p0;
// Expression:4
	n_out4p0 = vec2(0.0, 0.0);
	{
			float h_frames = float(particles_anim_h_frames);
			float v_frames = float(particles_anim_v_frames);
			float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
			float particle_frame = floor(n_out2p3 * float(particle_total_frames));
			particle_frame = mod(particle_frame, particle_total_frames);
			
			n_out4p0 = n_out5p0;
			n_out4p0 /= vec2(h_frames, v_frames);
			n_out4p0 += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames) / v_frames);
	}


// BooleanParameter:7
	bool n_out7p0 = UsebillboardParticle;


	mat4 n_out9p0;
// GetBillboardMatrix:9
	{
		mat4 __wm = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
		__wm = __wm * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		__wm = __wm * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		n_out9p0 = VIEW_MATRIX * __wm;
	}


// Input:10
	mat4 n_out10p0 = MODELVIEW_MATRIX;


	mat4 n_out8p0;
// Switch:8
	if (n_out7p0) {
		n_out8p0 = n_out9p0;
	} else {
		n_out8p0 = n_out10p0;
	}


// Output:0
	UV = n_out4p0;
	MODELVIEW_MATRIX = n_out8p0;


}

void fragment() {
// Input:10
	vec2 n_out10p0 = UV;


// FloatParameter:13
	float n_out13p0 = EdgeYUV;


// VectorCompose:12
	float n_in12p0 = 1.00000;
	vec2 n_out12p0 = vec2(n_in12p0, n_out13p0);


// UVFunc:11
	vec2 n_in11p2 = vec2(0.00000, 0.00000);
	vec2 n_out11p0 = n_in11p2 * n_out12p0 + n_out10p0;


	vec4 n_out2p0;
// Texture2D:2
	n_out2p0 = texture(Albedo, n_out11p0);
	float n_out2p4 = n_out2p0.a;


// VectorCompose:5
	float n_in5p1 = 0.00000;
	vec2 n_out5p0 = vec2(n_out2p4, n_in5p1);


	vec4 n_out4p0;
// Texture2D:4
	n_out4p0 = texture(ColorGradient, n_out5p0);


// Input:14
	vec4 n_out14p0 = COLOR;
	float n_out14p4 = n_out14p0.a;


// FloatOp:15
	float n_out15p0 = n_out14p4 * n_out2p4;


// FloatParameter:8
	float n_out8p0 = EmissionPower;


// VectorOp:9
	vec3 n_out9p0 = vec3(n_out4p0.xyz) * vec3(n_out8p0);


// Output:0
	ALBEDO = vec3(n_out4p0.xyz);
	ALPHA = n_out15p0;
	EMISSION = n_out9p0;
	BACKLIGHT = vec3(n_out4p0.xyz);


}
 .         A   
    ��D  �CB             C   
     ��  �BD            E   
     p�  ��F   
   w~�CVCG          H          I      J   uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames; J            K   
     ��  4CL   
   �YDq=�CM      !   0,0,INSTANCE_CUSTOM_Z;1,3,CurUV; N         0,3,OutputUV; O      �  	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM_Z * float(particle_total_frames));
	particle_frame = mod(particle_frame, particle_total_frames);
	
	OutputUV = CurUV;
	OutputUV /= vec2(h_frames, v_frames);
	OutputUV += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames) / v_frames); P            Q   
     ��  �CR            S   
     D  �CT            U   
    ��D  �CV            W   
     zD  DX            Y   
     �D  >DZ                                                                	             
                        
   [   
    ��D  4C\            ]   
      �  4C^         	   _   
    ���  �C`            a   
     �B    b            c   
   /������d            e   
     ��  \Cf            g   
     p�  Dh            i   
     �C  �Cj            k   
    ���   Bl            m   
     z�  pBn            o   
     ��  4Cp            q   
    ���  �Cr            s   
     D  ��t            u   
   ;GWD/��Bv            w   
     �D  ��x            y   
     uD  �z            {   
     �C  �|            }   
     4D  �~               
     uD  �À            �   
     D  �Â       `                                                               	              	      	                            
                                                                                                                                                                                                                              RSRC