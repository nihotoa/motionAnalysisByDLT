function X = triangulate(body_parts_num, motion_image_coordinates, CamParam)
a = CamParam;
frame_num = length(motion_image_coordinates);
X = zeros([frame_num 3 * body_parts_num]);  

for body_parts_id = 1:body_parts_num
    for frame_id = 1:frame_num
        u1 = motion_image_coordinates(frame_id,((2*body_parts_id)-1));
        v1 = motion_image_coordinates(frame_id,(2*body_parts_id));
        u2 = motion_image_coordinates(frame_id,((2*body_parts_id)-1) + (2 * body_parts_num));
        v2 = motion_image_coordinates(frame_id,(2*body_parts_id) + (2 * body_parts_num));
        a1 = a(:, 1);
        a2 = a(:, 2);
      
        y = [u1-a1(4,1); v1-a1(8,1); u2-a2(4,1); v2-a2(8,1)];
        A = [a1(1,1)-a1(9,1)*u1, a1(2,1)-a1(10,1)*u1, a1(3,1)-a1(11,1)*u1;
             a1(5,1)-a1(9,1)*v1, a1(6,1)-a1(10,1)*v1, a1(7,1)-a1(11,1)*v1;
             a2(1,1)-a2(9,1)*u2, a2(2,1)-a2(10,1)*u2, a2(3,1)-a2(11,1)*u2;
             a2(5,1)-a2(9,1)*v2, a2(6,1)-a2(10,1)*v2, a2(7,1)-a2(11,1)*v2];
        temp = inv(transpose(A)*A)*transpose(A)*y;
        X(frame_id,1+3*(body_parts_id-1)) = temp(1,1);
        X(frame_id,2+3*(body_parts_id-1)) = temp(2,1);
        X(frame_id,3+3*(body_parts_id-1)) = temp(3,1);
    end
end
end

