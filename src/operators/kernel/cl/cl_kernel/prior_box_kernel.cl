/* Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

__kernel void prior_box(__private const int global_size_dim0,
                        __private const int global_size_dim1,
                        __private const int global_size_dim2,
                        __global float *box_width,
                        __global float *box_height,
                        __write_only image2d_t output_image,
                        __private const float step_width,
                        __private const float step_height,
                        __private const float offset,
                        __private const int img_width,
                        __private const int img_height,
                        __private const int num_priors,
                        __private const int C){


                        const int out_c = get_global_id(0);
                        const int out_nh = get_global_id(1);
                        const int out_n = out_nh/num_priors;
                        const int out_h = out_nh%num_priors;

                        if (out_c >= global_size_dim0 ||out_nh >= global_size_dim2) {
                             return;
                         }
                        const sampler_t sampler = CLK_NORMALIZED_COORDS_TRUE |
                                                  CLK_ADDRESS_CLAMP          |
                                                  CLK_FILTER_NEAREST;
                        int2 output_pos;
                        output_pos.x = out_c * 4;
                        output_pos.y = out_nh;
                        float center_x0 = (offset + out_c * 4) * step_width;
                        float center_x1 = (offset + out_c * 4 + 1) * step_width;
                        float center_x2 = (offset + out_c * 4 + 2) * step_width;
                        float center_x3 = (offset + out_c * 4 + 3) * step_width;
                        float center_y = (out_n + offset) * step_height;

                        half4 output[4];
                        output[0].x = convert_half((center_x0 - box_width[out_h]) / img_width);
                        output[1].x = convert_half((center_y - box_height[out_h]) / img_height);
                        output[2].x = convert_half((center_x0 + box_width[out_h]) / img_width);
                        output[3].x = convert_half((center_y + box_height[out_h]) / img_height);

                        if(C - 4 * out_c>=2){
                        output[0].y = convert_half((center_x1 - box_width[out_h]) / img_width);
                        output[1].y = convert_half((center_y - box_height[out_h]) / img_height);
                        output[2].y = convert_half((center_x1 + box_width[out_h]) / img_width);
                        output[3].y = convert_half((center_y + box_height[out_h]) / img_height);
                        }else{
                         output[0].y = 0.0f;
                         output[1].y = 0.0f;
                         output[2].y = 0.0f;
                         output[3].y = 0.0f;
                        }
                        if(C - 4 * out_c>=3){
                        output[0].z = convert_half((center_x2 - box_width[out_h]) / img_width);
                        output[1].z = convert_half((center_y - box_height[out_h]) / img_height);
                        output[2].z = convert_half((center_x2 + box_width[out_h]) / img_width);
                        output[3].z = convert_half((center_y + box_height[out_h]) / img_height);
                        }else{
                        output[0].z = 0.0f;
                        output[1].z = 0.0f;
                        output[2].z = 0.0f;
                        output[3].z = 0.0f;
                        }
                        if(C - 4 * out_c>=4){
                        output[0].w = convert_half((center_x3 - box_width[out_h]) / img_width);
                        output[1].w = convert_half((center_y - box_height[out_h]) / img_height);
                        output[2].w = convert_half((center_x3 + box_width[out_h]) / img_width);
                        output[3].w = convert_half((center_y + box_height[out_h]) / img_height);
                        }else{
                        output[0].z = 0.0f;
                        output[1].z = 0.0f;
                        output[2].z = 0.0f;
                        output[3].z = 0.0f;
                        }
                        output[0] = min(max((half4)(0.0f, 0.0f, 0.0f, 0.0f), output[0]),(half4)(1.0f, 1.0f, 1.0f, 1.0f));
                        output[1] = min(max((half4)(0.0f, 0.0f, 0.0f, 0.0f), output[1]),(half4)(1.0f, 1.0f, 1.0f, 1.0f));
                        output[2] = min(max((half4)(0.0f, 0.0f, 0.0f, 0.0f), output[2]),(half4)(1.0f, 1.0f, 1.0f, 1.0f));
                        output[3] = min(max((half4)(0.0f, 0.0f, 0.0f, 0.0f), output[3]),(half4)(1.0f, 1.0f, 1.0f, 1.0f));
                        write_imageh(output_image, (int2)(output_pos.x + 1, output_pos.y), output[0]);
                        write_imageh(output_image, (int2)(output_pos.x + 2, output_pos.y), output[1]);
                        write_imageh(output_image, (int2)(output_pos.x + 3, output_pos.y), output[2]);
                        write_imageh(output_image, (int2)(output_pos.x + 4, output_pos.y), output[3]);

}