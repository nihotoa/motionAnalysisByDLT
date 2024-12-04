%{
画像座標を格納するテーブルの外枠を作成するための関数
%}
function [cell_for_image_table] = makeImageTable(cam_num, key_point_num)
    row_num = 2 + key_point_num;
    col_num = cam_num * 2 + 1;
    cell_for_image_table = cell(row_num, col_num);

    % 列方向のフレームワークの作成
    for camera_id = 1:cam_num
        start_col_id = 2 * camera_id;
        cell_for_image_table{1, start_col_id} = ['camera' num2str(camera_id)];

        cell_for_image_table{2, start_col_id} = 'u';
        cell_for_image_table{2, start_col_id + 1} = 'v';
    end
    
    % 行方向のフレームワークの作成
    for key_point_id = 1:key_point_num
        col_id = 2 + key_point_id;
        cell_for_image_table{col_id, 1} = ['P' num2str(key_point_id)];
    end
end