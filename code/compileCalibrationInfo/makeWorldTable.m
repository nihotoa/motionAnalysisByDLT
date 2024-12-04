%{
実座標を格納するテーブルの外枠を作成するための関数
%}
function [cell_for_world_table] = makeWorldTable(key_point_world_coordination_list)
    coordinate_list = {'x[mm]', 'y[mm]', 'z[mm]'};
    key_point_num = size(key_point_world_coordination_list, 1);
    row_num = 1 + key_point_num;
    col_num = 4;
    cell_for_world_table = cell(row_num, col_num);

    % 列方向のフレームワークの作成
    for coordinate_id = 1:3
        col_id = 1 + coordinate_id;
        cell_for_world_table{1, col_id} = coordinate_list{coordinate_id};
    end

    % 列方向のフレームワークの作成
    for key_point_id = 1:key_point_num
        row_id = 1 + key_point_id;
        cell_for_world_table{row_id, 1} = ['P' num2str(key_point_id)];
    end

    % 実座標値の代入
    cell_for_world_table(2:end, 2:end) = num2cell(cell2mat(key_point_world_coordination_list));
end