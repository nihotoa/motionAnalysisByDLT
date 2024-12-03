%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
DLT�@��p���āA�R�������W�𓱏o����v���O����

[procedure]
pre: getCalibrationFrameCoords.m
post: ComapairUsdata.m

[pre preparation]
Save the csv file of the actual coordinates and image coordinates of the calibration frame in 'calibration' folder
(P_image_US~.csv & P_world_US.csv)


���O����:
> getCalibrationFrameCoords.m���Ɏ��s����B(�L�����u���[�V������csv�t�@�C���̐���������)
> UltraSound_VideoAnalyze/useDataFold/<monkeyname>/DLC_csv_file/<���t>/<�h���ӏ�> �Ƃ����t�H���_������Ă��̒���
    'camera1_motion_data.csv'�Ƃ������v�̂ŁAdeeplabcut�œ���ꂽcsv�t�@�C����ۑ����Ă���
    (��) �T������'Nibali', ���t��220525, �h�����ʂ�ulnar�̏ꍇ, camera2�ɑ΂���deeplabcut�̊w�K���ʂ�csv�t�@�C���͈ȉ��̂悤�Ɋi�[
        UltraSound_VideoAnalyze/useDataFold/Nibali/DLC_csv_file/220000/ulnar/camera2_motion_data.csv

    �� camera1���ǂ̃A���O���ɑΉ����邩�͑S���t�̃f�[�^�Ԃň�ѐ����������Ă��������B(��camera1�͉E����B�e�����A���O��, �������Ȋ���)

    > Get_WorldPos�̃J�����p�����[�^a�ƎQ�Ƃ��Ă���imagePos����̍��W�f�[�^���Ή����Ă��邩�ǂ����m�F����
    �m�F���@:�L�����u���[�V������csv�t�@�C���̃J����1�̃A���O����,datalist�ōŏ��ɎQ�Ƃ����t�@�C���̃J�����A���O�������������OK


[���ӓ_]
> 220000���F�t���ւ��O�̎h���ɑ΂��铮���͌���

[���P�_]
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
%% set param
monkey_name = 'Nibali'; % 'Nibali', 'Hugo'
likelyhood_threshold = 0.9; 
stim_location = 'ulnar'; %�h������(ulnar,radial)


%% code section
base_dir = fileparts(pwd);
save_folder = fullfile(base_dir, 'saveFold'); 

% ���t�̑I��(GUI)
calibration_fold_path = fullfile(base_dir, 'useDataFold', monkey_name, 'calibration');
disp('�������s�������f�[�^�̓��t�����ׂđI�����Ă�������')
date_list = uiselect(dirdir(calibration_fold_path),1,'Please select all folders you want to operate');

if isempty(date_list)
    disp('cancel�{�^���������ꂽ�̂ŏ������I�����܂�')
    return;
end

% �����ɏ���
for date_id =  1: length(date_list)
    ref_date = date_list{date_id};
    disp([ref_date '�̏������J�n���܂�']);

    % Get calibration information
    calibration_result_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'calibrationFrameData', ref_date);
    calibration_file_list = dirEx(calibration_result_path);
    image_coordination_struct = calibration_file_list(contains({calibration_file_list.name}, 'image'));
    world_coordination_struct = calibration_file_list(contains({calibration_file_list.name}, 'world'));
    if or(isempty(image_coordination_struct), isempty(world_coordination_struct))
        warning('calibration�t�@�C���̖��O���������Ȃ��A�܂��̓t�@�C�������݂��܂���B���"getCalibrationFrameCoords.m"�����s���Ă�������');
        disp([ref_date '�̏����𒆒f���܂�']);
        disp('------------------------------------------------------------------------------------------------------------------------------------------------------');
        continue;
    end
    image_coordination_file_name = image_coordination_struct.name;
    world_coordination_file_name = world_coordination_struct.name;
    
    %calibration�t�H���_����2��csv�t�@�C���̒��g��ǂݍ���
    P_image = csvread(fullfile(calibration_result_path, image_coordination_file_name), 2, 1);%(3,2)��(1,1)�ɂȂ�悤�ɃI�t�Z�b�g
    P_world = csvread(fullfile(calibration_result_path, world_coordination_file_name), 1, 1);
    
    [~, col_num] = size(P_image);
    camera_num = col_num / 2;
    
    % Estimation camera parameter
    camera_parameter_list = Get_CamParam(P_world, P_image); %function which generate CamereaParameter
     
    DLC_csv_fold_path = fullfile(base_dir, 'useDataFold', monkey_name, 'DLC_csv_file', ref_date, stim_location);
    motion_data_files = dirEx(fullfile(DLC_csv_fold_path, '*.csv'));
    motion_data_files = {motion_data_files.name};
    if not(length(motion_data_files) == camera_num)
        warning(['DLC�ɂ���ďo�͂��ꂽcsv�t�@�C���������邱�Ƃ��ł��܂���ł����B���̃t�H���_�����m�F���Ă�������:  ' DLC_csv_fold_path]);
        disp([ref_date '�̏����𒆒f���܂�']);
        disp('------------------------------------------------------------------------------------------------------------------------------------------------------');
        continue;
    end
         
    % Read csv file of 2D coordinates position on image(._�t�@�C��������������ăG���[�f�����Ƃ����邩�璍�ӂ���)
    for camera_id = 1 : camera_num
        continue_flag = false;
        ref_motion_data_file_idx = find(contains(motion_data_files, ['camera' num2str(camera_id)]));
        if isempty(ref_motion_data_file_idx)
            warning(['camera' num2str(camera_id) '��csv�t�@�C����������܂���ł����Bcsv�t�@�C���̖��O���K�؂��ǂ����m�F���Ă�������'])
            disp([ref_date '�̏����𒆒f���܂�']);
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
            motion_image_coordinates = zeros(frame_num, (body_parts_num * 2 *camera_num)); %2��(u, v)
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
    
    % likelyhood�̒Ⴂ3�������W��NaN�Œu��������
    for body_parts_id = 1:body_parts_num
        for frame_id = 1:frame_num
            if (likelyhood(frame_id, body_parts_id) < likelyhood_threshold) || (likelyhood(frame_id, body_parts_id+body_parts_num) < likelyhood_threshold)
                worldPos(frame_id,(body_parts_id*3)-2) = nan; 
                worldPos(frame_id,(body_parts_id*3)-1) = nan; 
                worldPos(frame_id,(body_parts_id*3)) = nan; 
            end
        end
    end
    
    %���ʂ�table�ɂ܂Ƃ߂�
    [reconst_table, coorination_name_list] = makeReconstTable(worldPos, body_parts_name);
    
    % �Z�[�u�ݒ�
    save_data_folder_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'DLT_result', ref_date, stim_location);
    makefold(save_data_folder_path)
    save_data_file_name = 'reconst_3d_coordination.csv';
    writetable(reconst_table, fullfile(save_data_folder_path, save_data_file_name),'WriteVariableNames', false);
    disp(['data�͎��̃f�B���N�g���ɃZ�[�u����܂���:' save_data_folder_path])

    % ���ʂ̃v���b�g
    save_file_folder_path = fullfile(base_dir, 'saveFold', monkey_name, 'figure', 'DLT_result', ref_date, stim_location);
    plotReconstCoordination(worldPos,save_file_folder_path, coorination_name_list); 

    disp([ref_date '�̏������I�����܂�']);
    disp('------------------------------------------------------------------------------------------------------------------------------------------------------');
end
