%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
GUI操作によって、キャリブレーションフレームの画像から各ポイントの画像座標を取得して、csvファイルとして出力する

[procedure]
pre: nothing
post: DLT_3D_reconst.m

[pre preparation]
Save the csv file of the actual coordinates and image coordinates of the calibration frame in 'calibration' folder
(P_image_US~.csv & P_world_US.csv)


事前準備:
> UltraSound_VideoAnalyze/useDataFold/<monkey_name>/calibration/<日付フォルダ>を作成し、このフォルダに各カメラから撮影したキャリブレーション用の画像を'camera1.jpg',
'camera2.jpg'といった名前で保存しておく。(画像の拡張子はなんでもいいですが、パラメータのimage_file_extentionでその拡張子を指定してください)
(例) monkey_name = 'Hugo', 日付 = 20241120, カメラ番号 = 1の場合,
            UltraSound_VideoAnalyze/useDataFold/Hugo/calibration/20241120/camera1.jpg
      みたいな感じで画像を格納してください


[改善点]
UIがクソ. (主に呼び出している関数annotateImagePointsのUI)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Nibali'; % 'Nibali' / 'Hugo'
image_file_extention = '.jpg';
key_point_num = 12; %キャリブレーションフレーム上のキーポイントの総数
key_point_world_coordination_list = {[0, 0, 20];
                                                          [0, 60, 20]; 
                                                          [40, 0, 20]; 
                                                          [40, 60, 20]; 
                                                          [0, 0, 100]; 
                                                          [0, 60, 100]; 
                                                          [40, 0, 100]; 
                                                          [40, 60, 100]; 
                                                          [0, 0, 180]; 
                                                          [0, 60, 180]; 
                                                          [40, 0, 180]; 
                                                          [40, 60, 180]};

%% code section
base_dir = fileparts(pwd);
% 日付の選択UI
calibration_fold_path = fullfile(base_dir, 'useDataFold', monkey_name, 'calibration');
date_list = uiselect(dirdir(calibration_fold_path),1,'Please select all folders you want to operate');

if isempty(date_list)
    disp('cancelボタンが押されたので処理を終了します')
    return;
end

% 実座標の表を作る
cell_for_world_table = makeWorldTable(key_point_world_coordination_list);
world_coordinates = cell2mat(key_point_world_coordination_list);
cell_for_world_table(2:end, 2:end) = num2cell(world_coordinates);

% 列名を指定してテーブルを作成
column_names = {'keypoint', 'x', 'y', 'z'};
world_table = cell2table(cell_for_world_table(2:end, :), 'VariableNames', column_names);

% 日毎に画像座標をGUI操作によって取得
for date_id = 1:length(date_list)
    ref_date = date_list{date_id};
    disp('-----------------------------------------------------------------')
    disp([ref_date 'の処理を開始します'])
    disp('-----------------------------------------------------------------')

    ref_date_fold_path = fullfile(calibration_fold_path, num2str(ref_date));
    calibration_image_num = length(dirEx(fullfile(ref_date_fold_path, ['camera*' image_file_extention])));
    if calibration_image_num == 0
        warning(['calibration用の画像を見つけることができませんでした。'  ref_date_fold_path '　内に画像があるかどうか、その画像のファイル名が正しいかどうかを確かめてください']);
        continue;
    end
    
    % 使用するキャリブレーション画像のfull pathをリストにまとめる
    calibration_image_file_path_list = cell(calibration_image_num,1);
    for camera_id = 1:calibration_image_num
        ref_calibration_image_file_path = fullfile(ref_date_fold_path, ['camera' num2str(camera_id) image_file_extention]);
        calibration_image_file_path_list{camera_id} = ref_calibration_image_file_path;
    end
    
   % 出力するテーブルの外枠の作成
   cell_for_image_table = makeImageTable(calibration_image_num, key_point_num);

   % GUI操作によって各キーポイントの画像座標を得る
    image_coordinates_list = annotateImagePoints(key_point_num, calibration_image_file_path_list);

   % テーブルに得られた画像座標を代入
   cell_for_image_table(3:end, 2:end) = num2cell(image_coordinates_list);
   image_table = cell2table(cell_for_image_table);

   % 結果をcsvファイルで出力
   save_fold_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'calibrationFrameData', ref_date);
   makefold(save_fold_path)
   writetable(world_table, fullfile(save_fold_path, 'world_coordinates.csv'), 'WriteVariableNames', true);
   writetable(image_table, fullfile(save_fold_path, 'image_coordinates.csv'), 'WriteVariableNames', false);
   disp('-----------------------------------------------------------------')
   disp('以下のように結果が保存されました。')
   disp(['実座標データ: ' fullfile(save_fold_path, 'world_coordinates.csv')]);
   disp(['画像座標データ: ' fullfile(save_fold_path, 'image_coordinates.csv')]);
   disp([ref_date 'の処理が適切に終了しました'])
   disp('-----------------------------------------------------------------')
end
disp('全体の処理が適切に終了しました')

%% define local function
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

%-------------------------------------------------------------------------------
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