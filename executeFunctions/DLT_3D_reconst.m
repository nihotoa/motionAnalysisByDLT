%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
DLT法を用いて、３次元座標を導出するプログラム

[procedure]
pre: getCalibrationFrameCoords.m
post: ComapairUsdata.m

[pre preparation]
Save the csv file of the actual coordinates and image coordinates of the calibration frame in 'calibration' folder
(P_image_US~.csv & P_world_US.csv)


事前準備:
> getCalibrationFrameCoords.mを先に実行する。(キャリブレーションのcsvファイルの生成をする)
> UltraSound_VideoAnalyze/useDataFold/<monkeyname>/DLC_csv_file/<日付>/<刺激箇所> というフォルダを作ってその中に
    'camera1_motion_data.csv'といった要領で、deeplabcutで得られたcsvファイルを保存しておく
    (例) サル名が'Nibali', 日付が220525, 刺激部位がulnarの場合, camera2に対するdeeplabcutの学習結果のcsvファイルは以下のように格納
        UltraSound_VideoAnalyze/useDataFold/Nibali/DLC_csv_file/220000/ulnar/camera2_motion_data.csv

    ※ camera1がどのアングルに対応するかは全日付のデータ間で一貫性を持たせてください。(例camera1は右から撮影したアングル, 見たいな感じ)

    > Get_WorldPosのカメラパラメータaと参照しているimagePosからの座標データが対応しているかどうか確認する
    確認方法:キャリブレーションのcsvファイルのカメラ1のアングルと,datalistで最初に参照されるファイルのカメラアングルが等しければOK


[注意点]
> 220000は腱付け替え前の刺激に対する動作解析結果

[改善点]
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
%% set param
monkey_name = 'Nibali'; % 'Nibali', 'Hugo'
likelyhood_threshold = 0.9; 
stim_location = 'ulnar'; %刺激部位(ulnar,radial)


%% code section
base_dir = fileparts(pwd);
save_folder = fullfile(base_dir, 'saveFold'); 

% 日付の選択(GUI)
calibration_fold_path = fullfile(base_dir, 'useDataFold', monkey_name, 'calibration');
disp('処理を行いたいデータの日付をすべて選択してください')
date_list = uiselect(dirdir(calibration_fold_path),1,'Please select all folders you want to operate');

if isempty(date_list)
    disp('cancelボタンが押されたので処理を終了します')
    return;
end

% 日毎に処理
for date_id =  1: length(date_list)
    ref_date = date_list{date_id};
    disp([ref_date 'の処理を開始します']);

    % Get calibration information
    calibration_result_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'calibrationFrameData', ref_date);
    calibration_file_list = dirEx(calibration_result_path);
    image_coordination_struct = calibration_file_list(contains({calibration_file_list.name}, 'image'));
    world_coordination_struct = calibration_file_list(contains({calibration_file_list.name}, 'world'));
    if or(isempty(image_coordination_struct), isempty(world_coordination_struct))
        warning('calibrationファイルの名前が正しくない、またはファイルが存在しません。先に"getCalibrationFrameCoords.m"を実行してください');
        disp([ref_date 'の処理を中断します']);
        disp('------------------------------------------------------------------------------------------------------------------------------------------------------');
        continue;
    end
    image_coordination_file_name = image_coordination_struct.name;
    world_coordination_file_name = world_coordination_struct.name;
    
    %calibrationフォルダ内の2つのcsvファイルの中身を読み込み
    P_image = csvread(fullfile(calibration_result_path, image_coordination_file_name), 2, 1);%(3,2)が(1,1)になるようにオフセット
    P_world = csvread(fullfile(calibration_result_path, world_coordination_file_name), 1, 1);
    
    [~, col_num] = size(P_image);
    camera_num = col_num / 2;
    
    % Estimation camera parameter
    camera_parameter_list = Get_CamParam(P_world, P_image); %function which generate CamereaParameter
     
    DLC_csv_fold_path = fullfile(base_dir, 'useDataFold', monkey_name, 'DLC_csv_file', ref_date, stim_location);
    motion_data_files = dirEx(fullfile(DLC_csv_fold_path, '*.csv'));
    motion_data_files = {motion_data_files.name};
    if not(length(motion_data_files) == camera_num)
        warning(['DLCによって出力されたcsvファイルを見つけることができませんでした。次のフォルダ内を確認してください:  ' DLC_csv_fold_path]);
        disp([ref_date 'の処理を中断します']);
        disp('------------------------------------------------------------------------------------------------------------------------------------------------------');
        continue;
    end
         
    % Read csv file of 2D coordinates position on image(._ファイル等が生成されてエラー吐くことがあるから注意する)
    for camera_id = 1 : camera_num
        continue_flag = false;
        ref_motion_data_file_idx = find(contains(motion_data_files, ['camera' num2str(camera_id)]));
        if isempty(ref_motion_data_file_idx)
            warning(['camera' num2str(camera_id) 'のcsvファイルが見つかりませんでした。csvファイルの名前が適切かどうか確認してください'])
            disp([ref_date 'の処理を中断します']);
            continue_flag = true;
            break;
        end
        ref_motion_data = readmatrix(fullfile(DLC_csv_fold_path, motion_data_files{ref_motion_data_file_idx}));
        ref_motion_data = ref_motion_data(:, 2:end);
        frame_num = size(ref_motion_data, 1);
    
        if camera_id == 1
            body_parts_name = readcell(fullfile(DLC_csv_fold_path, motion_data_files{ref_motion_data_file_idx}));
            body_parts_name = unique(body_parts_name(2, 2:end));
            body_parts_num = length(body_parts_name);
            motion_image_coordinates = zeros(frame_num, (body_parts_num * 2 *camera_num)); %2は(u, v)
            likelyhood = zeros(frame_num, (body_parts_num * camera_num));
        end
        
        if not(camera_id == 1)
            if frame_num <length(motion_image_coordinates) 
                motion_image_coordinates = motion_image_coordinates(1:frame_num,:);
                likelyhood = likelyhood(1:frame_num,:); 
            else
                frame_num = length(motion_image_coordinates);
            end
        end
    
        %motion_image_coordinates
        for body_parts_id = 1 : body_parts_num
            motion_image_coordinates(:, 2 * body_parts_num * (camera_id - 1) + 2 * body_parts_id - 1)  = ref_motion_data(1 : frame_num , 3 * body_parts_id - 2); % x position
            motion_image_coordinates(:, 2 * body_parts_num * (camera_id - 1) + 2 * body_parts_id)      = ref_motion_data(1 : frame_num , 3 * body_parts_id - 1); % y position
            likelyhood(:, body_parts_num * (camera_id - 1) + body_parts_id)            = ref_motion_data(1 : frame_num , 3 * body_parts_id);
        end
    end
    
    if continue_flag == true
        continue;
    end

    worldPos = Get_worldPos(body_parts_num, motion_image_coordinates, camera_parameter_list);
    
    % likelyhoodの低い3次元座標をNaNで置き換える
    for body_parts_id = 1:body_parts_num
        for frame_id = 1:frame_num
            if (likelyhood(frame_id, body_parts_id) < likelyhood_threshold) || (likelyhood(frame_id, body_parts_id+body_parts_num) < likelyhood_threshold)
                worldPos(frame_id,(body_parts_id*3)-2) = nan; 
                worldPos(frame_id,(body_parts_id*3)-1) = nan; 
                worldPos(frame_id,(body_parts_id*3)) = nan; 
            end
        end
    end
    
    %結果をtableにまとめる
    [reconst_table, coorination_name_list] = makeReconstTable(worldPos, body_parts_name);
    
    % セーブ設定
    save_data_folder_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'DLT_result', ref_date, stim_location);
    makefold(save_data_folder_path)
    save_data_file_name = 'reconst_3d_coordination.csv';
    writetable(reconst_table, fullfile(save_data_folder_path, save_data_file_name),'WriteVariableNames', false);
    disp(['dataは次のディレクトリにセーブされました:' save_data_folder_path])

    % 結果のプロット
    save_file_folder_path = fullfile(base_dir, 'saveFold', monkey_name, 'figure', 'DLT_result', ref_date, stim_location);
    plotReconstCoordination(worldPos,save_file_folder_path, coorination_name_list); 

    disp([ref_date 'の処理を終了します']);
    disp('------------------------------------------------------------------------------------------------------------------------------------------------------');
end
