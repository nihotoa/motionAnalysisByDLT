%{
DLT_3D_reconstで推定した、3次元座標推定値をまとめてtableを作成する。
%}

function [reconst_table, header] = makeReconstTable(worldPos, body_parts_name)
body_parts_num = length(body_parts_name);
% 結果を元に出力する表を作成
[frame_num, col_num] = size(worldPos);
cell_for_reconst_table = cell(frame_num + 1, col_num);

% ヘッダーの挿入
header = strcat(repelem(body_parts_name, 1, body_parts_num), repmat({' X', ' Y', ' Z'}, 1, numel(body_parts_name)));
cell_for_reconst_table(1, :) = header;

% データの挿入
cell_for_reconst_table(2 : frame_num + 1, :) = num2cell(worldPos(1 : frame_num, :));
reconst_table = cell2table(cell_for_reconst_table);
end

