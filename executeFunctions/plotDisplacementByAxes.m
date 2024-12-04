%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]

[procedure]
pre: triangulateByDLT.m
post: plotTotalDisplacement.m

[事前準備]
> DLT_3D_reconst.mを先に実行してください(reconst_3d_coordination.csvが必要)

[改善点]
横軸がフレーム数なので、秒に直す(撮影の際のfpsを知ることが必要)
線形保管するときに、開始のindexにおける座標値がNaNだと保管できないので、対策を考える
legendがついていない.

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Nibali';
do_offset = true; % Whether to offset the initial phase to 0 or not
do_filter = false;
stim_location = 'radial'; %ulnar or radial
pre_frame = 100; 
post_frame = 900; 
plot_type = 'each';  % 'all' / 'each'
TT_surgery_day = '220530';

%% code section

base_dir = fileparts(pwd);
save_folder_path = fullfile(base_dir, 'saveFold'); 

% 日付の選択(GUI)
DLT_data_fold_path = fullfile(base_dir, 'saveFold', monkey_name, 'data', 'DLT_result');
disp('処理を行いたいデータの日付をすべて選択してください')
date_list = uiselect(dirdir(DLT_data_fold_path),1,'Please select all folders you want to operate');

if isempty(date_list)
    disp('cancelボタンが押されたので処理を終了します')
    return;
end

% 座標データの取得
date_num = length(date_list);
coordinate_list = cell(date_num ,1);
for date_id = 1:date_num
    ref_date = date_list{date_id};
    coordinate_list{date_id,1} = readmatrix(fullfile(DLT_data_fold_path, ref_date, stim_location, 'reconst_3d_coordination.csv'));
    if date_id == 1
        % ヘッダーの取得
        ref_tbl = readtable(fullfile(DLT_data_fold_path, ref_date, stim_location, 'reconst_3d_coordination.csv'), 'VariableNamingRule', 'preserve');
        point_header = ref_tbl.Properties.VariableNames;
        point_num = length(point_header) / 3;
    end
end

%% trimming 'coordinate_list'
all_start_frame = zeros(1,date_num);
for date_id = 1:date_num 
    ref_date = date_list{date_id};

    %対象日のpoint1のz軸の座標を抽出する(これを基に刺激の始まり位置を決定する)
    reference_matrix = coordinate_list{date_id,1}(:,3);
    
    % GUIによってstimulation開始の経過フレーム数を取得する
    while true
        disp(['Please select the position of stimulation start(' stim_location ': ' ref_date ')'])
        plot(reference_matrix)

        % gui操作(data点をGUI操作で選べるように設定 & ダイアログの表示(ok押すまでuiwaitする))
        datacursormode on
        dlg = warndlg("Please push 'OK' after export 'cursor_info'");
        uiwait(dlg)
        close all;

        % 得られたstartframeを格納
        try
            stim_start_frame = cursor_info.Position(1);
        catch
            disp("'cursor_info' is not output. Please try again")
            continue
        end
        all_start_frame(1,date_id) = stim_start_frame; 
        clear cursor_info
        break
    end

    % trimming coordinate_list by refering to start_frame
    if stim_start_frame-pre_frame < 0
        initial_frame = 0;
    else
        initial_frame = (stim_start_frame-pre_frame)+1;
    end
    % calc last frame
    if stim_start_frame + post_frame > length(coordinate_list{date_id}) 
        last_frame = length(coordinate_list{date_id});
    else
        last_frame = stim_start_frame + post_frame;
    end
    coordinate_list{date_id} = coordinate_list{date_id}(initial_frame:last_frame, :);
end

%% filtering 'coordinate_list'
for date_id = 1:date_num
    ref_date_coordinate_list = coordinate_list{date_id};
    plot_num = size(ref_date_coordinate_list ,2);
    for plot_id = 1:plot_num
        ref_point_coordinate_values = ref_date_coordinate_list(:, plot_id);
        if any(isnan(ref_point_coordinate_values))
            % perform linear completion
            x = 1:length(ref_point_coordinate_values);
            nanIndex = isnan(ref_point_coordinate_values);
            x_known = x(~nanIndex);
            ref_axis_known = ref_point_coordinate_values(~nanIndex);
            ref_point_coordinate_values = interp1(x_known, ref_axis_known, x, "linear");
            if isnan(ref_point_coordinate_values(end))
                ref_point_coordinate_values(end) = ref_point_coordinate_values(end-1);
            end
        end
        % perform high-pass-filter
        if do_filter == true
            filter_h = 0.1; % cut off frequency[Hz] of high-pass filter
            [B,A] = butter(6, (filter_h .* 2) ./ 100, 'high');
            ref_point_coordinate_values = filtfilt(B,A, ref_point_coordinate_values);
        end
        % perform offset by refering to inital phase
        if do_offset == true
            initial_frame_value = ref_point_coordinate_values(1);
            ref_point_coordinate_values = ref_point_coordinate_values - initial_frame_value;
        end
        coordinate_list{date_id}(:, plot_id) = ref_point_coordinate_values;
    end
end

%% plot & save figure
save_figure_folder_path = fullfile(save_folder_path, monkey_name, 'figure', 'coordination_plot', stim_location, [date_list{1} '_to_' date_list{end} '_' num2str(date_num)]);
save_data_folder_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, [date_list{1} '_to_' date_list{end} '_' num2str(date_num)]);

if strcmp(plot_type, 'all')
    h = figure;
    set(h,'Position',[0 0 1920 1080]) %figureの大きさ設定
end

pre_flags = cellfun(@str2double, date_list) < str2double(TT_surgery_day);
for row_id = 1:point_num 
    for col_id = 1:3 %x, y, z 
        plot_id = 3*(row_id-1)+col_id;
        plot_title = point_header{plot_id};

        % setting for subplot
        if strcmp(plot_type, 'all')
            subplot(point_num,3, plot_id)
            hold on;
        end
        
        plot_stimulation(coordinate_list, pre_flags, plot_id, plot_title, plot_type, save_figure_folder_path)
    end
end

save_data_file_name = 'stim_start_frame';
makefold(save_data_folder_path)
save(fullfile(save_data_folder_path, [save_data_file_name '.mat']), 'all_start_frame','coordinate_list', 'point_header');
disp(['データは次のフォルダに保存されました: ' save_data_folder_path]);

%data_typeに応じて画像を保存するフォルダと画像名を変更する
if strcmp(plot_type, 'all')
    save_figure_file_name = 'displacement_to_stimulus';
    makefold(save_figure_folder_path);
    saveas(gcf, fullfile(save_figure_folder_path, [save_figure_file_name '.fig']));
    saveas(gcf, fullfile(save_figure_folder_path, [save_figure_file_name '.png']));
    disp(['画像は次のフォルダに保存されました: ' save_figure_folder_path]);
    close all;
end

%% define function
function [] = plot_stimulation(coordinate_list, pre_flags, plot_id, plot_title, plot_type, save_figure_folder_path)
if strcmp(plot_type, 'each')
    figure("position", [100, 100, 800, 400]);
    hold on;
end

date_num = length(coordinate_list);
for date_id = 1:date_num 
    ref_plot_coordination = coordinate_list{date_id,1}(:, plot_id);
    ref_pre_flag = pre_flags(date_id);
    if ref_pre_flag == 1
         plot(ref_plot_coordination,'color','b','LineWidth',2);
    else
        p_color = ((255*(date_id-1))/(date_num-1))-0.0001;
        color_element = p_color/255 ; 
        plot(ref_plot_coordination,'color',[color_element,0,0],'LineWidth', 2);
    end
end

% decoration(need legend & )
plot_title = strrep(plot_title, '_', '-');
title(plot_title, 'fontsize',22)
grid on;

% save figure (if plot_type == 'each')
if strcmp(plot_type, 'each')
    % decoration
    ylabel('displacement[mm]')
    set(gca, 'FontSize', 20);
    legend();
    save_figure_folder_path = fullfile(save_figure_folder_path, 'eachPlot');
    makefold(save_figure_folder_path);
    saveas(gcf, fullfile(save_figure_folder_path, [plot_title '.fig']));
    saveas(gcf, fullfile(save_figure_folder_path, [plot_title '.png']));
    if plot_id == 1
        disp(['画像は次のフォルダに保存されました: ' save_figure_folder_path]);
    end
    close all;
end
end