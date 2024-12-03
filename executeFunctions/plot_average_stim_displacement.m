%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
read the displacement data for stimulation,  calculate the average value of
the displacement for each day,  and over lay and plot.
[procedure]
pre: US_3D_traject.m
post: nothing

[改善点]
> 今はGUIでスパイク検出モドキをしているが,もっと信号処理に基づいて行った方がいい.
> 今のやり方だと, (日付数) * point数分だけGUI操作しなきゃいけないので大変すぎる.

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Nibali';
stim_location = 'radial'; %  'ulnar' / 'radial'
trim_range = [-60 60];  % [frame] how long range you want to plot?
shooting_frame_rate = 120; %
spike_ratio_threshold = 0.7;
plot_type = 'each'; % 'each' / 'all' 
cmapFunc = @turbo;

%% code section
% 日付の選択(GUI)
base_dir = fileparts(pwd);
DLT_data_fold_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'DLT_result');
disp('処理を行いたいデータの日付をすべて選択してください')
date_list = uiselect(dirdir(DLT_data_fold_path),1,'Please select all folders you want to operate');
date_num = length(date_list);

if isempty(date_list)
    disp('cancelボタンが押されたので処理を終了します')
    return;
end

% 必要なデータのロード
save_folder_path = fullfile(base_dir, 'saveFold');
date_combination_folder_name = [date_list{1} '_to_' date_list{end} '_' num2str(date_num)];
displacement_data_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, date_combination_folder_name, 'body_parts_dispclacement_list.mat');
load(displacement_data_path, 'body_parts_name');
body_parts_num = length(body_parts_name);

%% Assign data for plot to matrix
save_data_folder_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, date_combination_folder_name);
trimmed_stim_coordinate_file_name = 'trimmed_stim_coodinate_data.mat';
if not(exist(fullfile(save_data_folder_path, trimmed_stim_coordinate_file_name), "file"))
    % load data
    load(displacement_data_path, 'body_parts_displacement_list');
    matrix_for_stim_plot_average = cell(body_parts_num, 1);
    matrix_for_stim_plot_std = cell(body_parts_num, 1);
    
    for body_parts_id = 1:body_parts_num
        % 空の配列を作成
        matrix_for_stim_plot_average{body_parts_id} = zeros(date_num, trim_range(2) - trim_range(1));
        matrix_for_stim_plot_std{body_parts_id} = zeros(date_num, trim_range(2) - trim_range(1));
    
        for date_id = 1:date_num
            ref_date = date_list{date_id};
            ref_body_parts_displacements = body_parts_displacement_list{date_id}(:, body_parts_id);
    
            % GUI操作で最大値を取得(trueのループを関数にする)
            max_amplitude = getMaxAmplitudeGUI(ref_body_parts_displacements);
    
            % 各spikeにおける、変位が最大になるタイミングのindexを取得
            displacement_threshold = max_amplitude * spike_ratio_threshold;
            peak_displacement_indices = getPeakDisplacementIndices(ref_body_parts_displacements, displacement_threshold);

            % peak_displacement_indicesを中心とした、その周りの変位データを切り出し
            stim_num = length(peak_displacement_indices);
            matrix_for_average = zeros(stim_num, trim_range(2) - trim_range(1));
            for stim_id = 1:stim_num % trial of stimulations
                ref_peak_displacement_index = peak_displacement_indices(stim_id);
                cutout_start_idx = ref_peak_displacement_index + trim_range(1) + 1;
                cutout_end_idx = ref_peak_displacement_index + trim_range(2);
                if (isnan(ref_peak_displacement_index)) || (cutout_start_idx < 0) || (cutout_end_idx > length(ref_body_parts_displacements))
                    continue
                end
               matrix_for_average(stim_id, :) = ref_body_parts_displacements(cutout_start_idx:cutout_end_idx);
            end
    
            % calc mean displacement around spike timing
            matrix_for_average = matrix_for_average(any(matrix_for_average, 2), :);
            spike_average = mean(matrix_for_average);

            % store these data
            matrix_for_stim_plot_average{body_parts_id}(date_id, :) = spike_average;
        end
    end
    %%  save data
    stim_average_data = matrix_for_stim_plot_average;
    makefold(save_data_folder_path)
    save(fullfile(save_data_folder_path, trimmed_stim_coordinate_file_name), 'stim_average_data', "date_list");
end

%% plot figure
save_figure_folder_path = fullfile(save_folder_path, monkey_name, 'figure', 'coordination_plot', stim_location, date_combination_folder_name);

load(fullfile(save_data_folder_path, trimmed_stim_coordinate_file_name), 'stim_average_data', 'stim_std_data');
x = [trim_range(1)+1 : trim_range(2)];
% transrate [frame] to [sec]
x = x / shooting_frame_rate;
cmap = cmapFunc(date_num);

% give the whole title(to use for filenames)
switch stim_location
    case 'radial'
        stimulated_muscle = 'EDC';
    case 'ulnar'
        stimulated_muscle = 'FDS';
end

if strcmp(plot_type, 'all')
    figure("position", [100, 100, 600, 800]);
end
for body_parts_id = 1:body_parts_num
    ref_body_parts_data = stim_average_data{body_parts_id};
    ref_body_parts_name = strrep(body_parts_name{body_parts_id}, '_', '-');
    switch plot_type
        case 'each'
            figure("position", [100, 100, 800, 400]);
            hold on
            plotDisplacementAroundStimulus(ref_body_parts_data, date_list, x, cmap, ref_body_parts_name, stimulated_muscle)

            % decoration
            legend()
            xlabel('elapsed time from stimulus[sec]', 'FontSize', 15);
            ylabel('displacement[mm]', 'FontSize', 15);

            % save figure
            makefold(fullfile(save_figure_folder_path, 'eachPlot'))
            saveas(gcf, fullfile(save_figure_folder_path, 'eachPlot', [ref_body_parts_name '_average_stim_displacement.fig']))
            saveas(gcf, fullfile(save_figure_folder_path, 'eachPlot', [ref_body_parts_name '_average_stim_displacement.png']))
            close all;
        case 'all'
            subplot(body_parts_num, 1, body_parts_id)
            hold on;
            plotDisplacementAroundStimulus(ref_body_parts_data, date_list, x, cmap, ref_body_parts_name)

            % decoration
            if body_parts_id == 1
                legend()
            elseif body_parts_id == body_parts_num
                xlabel('elapsed time from stimulus[sec]', 'FontSize', 15);
                ylabel('displacement[mm]', 'FontSize', 15);
                sgtitle([' Finger displacement (' stimulated_muscle ' stimulation)'], 'FontSize', 20)
            end
    end
end

if strcmp(plot_type, 'all')
    % save figure
    saveas(gcf, fullfile(save_figure_folder_path, 'average_stim_displacement.png'));
    saveas(gcf, fullfile(save_figure_folder_path, 'average_stim_displacement.fig'));
    close all;
end
