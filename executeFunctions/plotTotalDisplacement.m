%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
���_����̕ψʂ��v���b�g���邽�߂̊֐�

[procedure]
pre: plotDisplacementByAxes.m
post: plotAverageDisplacementByStimTrial.m

���O����:
> CompairUsdata���Ɏ��s���Ă�������

% ���ӓ_
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
stim_location = 'radial';
monkey_name = 'Nibali';
TT_surgery_day = '220530';

%% code section
% ���t�̑I��(GUI)
base_dir = fileparts(pwd);
DLT_data_fold_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'DLT_result');
disp('�������s�������f�[�^�̓��t�����ׂđI�����Ă�������')
date_list = uiselect(dirdir(DLT_data_fold_path),1,'Please select all folders you want to operate');
date_num = length(date_list);

if isempty(date_list)
    disp('cancel�{�^���������ꂽ�̂ŏ������I�����܂�')
    return;
end

% �K�v�ȃf�[�^�̃��[�h
save_folder_path = fullfile(base_dir, 'saveFold');
date_combination_folder_name = [date_list{1} '_to_' date_list{end} '_' num2str(date_num)];
stim_start_timing_data_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, date_combination_folder_name, 'stim_start_frame.mat');

 % body_parts���̎擾(�}��title�Ŏg��)
try
    load(stim_start_timing_data_path,'coordinate_list', 'point_header');
catch
    warning([date_combination_folder_name '�����݂��܂���B���"plotDisplacementByAxes.m�h�ɂ����āA�������t�̑g�ݍ��킹�ŏ��������s���Ă�������'])
    disp('------------------------------------------�������I�����܂�------------------------------------------');
    return;
end
temp = cellfun(@(x) split(x, ' ') , point_header, 'UniformOutput',false);
body_parts_name = unique(cellfun(@(x) x{1}, temp, 'UniformOutput', false));
body_parts_num = length(body_parts_name);

%% �e�t���[���Ԃ̃��[�N���b�h���������߂�(�x�N�g���͉������Ȃ�)

% �i�[����z����쐬����
body_parts_displacement_list = cell(date_num,1);
for date_id = 1:date_num
    frame_num = length(coordinate_list{date_id,1});
    body_parts_displacement_list{date_id,1} = zeros(frame_num, body_parts_num);
end

%���_����̕ψʂ̑傫�������߂�body_parts_displacement_list�ɑ�����Ă���.
origin_coordinate = [0 0 0];
for date_id = 1:date_num
    ref_date_coordinate_values = coordinate_list{date_id};
    for body_parts_id =1:body_parts_num
        ref_col_index = 3 * (body_parts_id - 1) + 1;
        ref_parts_coordinate_list = ref_date_coordinate_values(:, (ref_col_index) : (ref_col_index+2));
        frame_num = size(ref_parts_coordinate_list, 1);
        for frame_id = 1:frame_num
            ref_coordinate = ref_parts_coordinate_list(frame_id, :);

            % NaN�l���������ꍇ�̏���
            if any(isnan(ref_coordinate))
                body_parts_displacement_list{date_id,1}(frame_id,body_parts_id) = NaN;
                continue;
            end

            displacement_value = norm(ref_coordinate); %�ψ�(���[�N���b�h�m����)
            body_parts_displacement_list{date_id,1}(frame_id,body_parts_id) = displacement_value;
        end
    end
end

%% ����ꂽ�m�������v���b�g���Ă���
h = figure;
set(h,'Position',[0 0 1920 1080]) %figure�̑傫���ݒ�
% TT surgery�����O�̓��t���ǂ�����flag
pre_flags = cellfun(@str2double, date_list) < str2double(TT_surgery_day);

% �h���ɑ΂�������̕ψʂ̑傫����plot���Ă���
for date_id = 1:date_num
    ref_date_body_displacement_list = body_parts_displacement_list{date_id};
    for body_parts_id = 1:body_parts_num
        subplot(body_parts_num,1,body_parts_id)
        hold on
        ref_body_parts_displacement = ref_date_body_displacement_list(:, body_parts_id);
        if pre_flags(date_id) ==  true
             plot(ref_body_parts_displacement,'color','b','LineWidth',2);
        else
            p_color = ((255*(date_id-1))/(date_num-1))-0.0001;
            color_ele = p_color/255 ; 
            plot(ref_body_parts_displacement,'color',[color_ele,0,0],'LineWidth',2);
        end

        % �}�̑���
        xlabel('elapsed frame [frame]')
        ylabel('displacement [mm]');
        set(gca, 'FontSize', 14);
        title_string = strrep(body_parts_name(body_parts_id), '_', '-');
        title(title_string, 'fontsize',22)
        grid on;
        yline(0,'k','LineWidth',1);
        hold off
    end
end

%% �}�ƃf�[�^�̕ۑ�

%�ۑ�����path�̐ݒ�
save_figure_folder_path = fullfile(save_folder_path, monkey_name, 'figure', 'coordination_plot', stim_location, date_combination_folder_name);
save_data_folder_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, date_combination_folder_name);

% �ۑ�����t�@�C�����̐ݒ�
save_figure_file_name = 'body_parts_dispclacement';
save_data_file_name = 'body_parts_dispclacement_list';

% �ۑ�
saveas(gcf, fullfile(save_figure_folder_path, [save_figure_file_name '.fig']))
saveas(gcf, fullfile(save_figure_folder_path, [save_figure_file_name '.png']))
save(fullfile(save_data_folder_path, [save_data_file_name '.mat']), 'body_parts_displacement_list', 'body_parts_name');

disp(['�摜�͎��̃t�H���_�ɕۑ�����܂���: ' save_figure_folder_path]);
disp(['�f�[�^�͎��̃t�H���_�ɕۑ�����܂���: ' save_data_folder_path]);

disp('�K�؂ɏ������������܂���')
close all;