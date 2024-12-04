%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
原点からの変位をプロットするための関数

[procedure]
pre: plotDisplacementByAxes.m
post: plotAverageDisplacementByStimTrial.m

事前準備:
> CompairUsdataを先に実行してください

% 注意点
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
stim_location = 'radial';
monkey_name = 'Nibali';
TT_surgery_day = '220530';

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
stim_start_timing_data_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, date_combination_folder_name, 'stim_start_frame.mat');

 % body_parts名の取得(図のtitleで使う)
try
    load(stim_start_timing_data_path,'coordinate_list', 'point_header');
catch
    warning([date_combination_folder_name 'が存在しません。先に"plotDisplacementByAxes.m”において、同じ日付の組み合わせで処理を実行してください'])
    disp('------------------------------------------処理を終了します------------------------------------------');
    return;
end
temp = cellfun(@(x) split(x, ' ') , point_header, 'UniformOutput',false);
body_parts_name = unique(cellfun(@(x) x{1}, temp, 'UniformOutput', false));
body_parts_num = length(body_parts_name);

%% 各フレーム間のユークリッド距離を求める(ベクトルは加味しない)

% 格納する配列を作成する
body_parts_displacement_list = cell(date_num,1);
for date_id = 1:date_num
    frame_num = length(coordinate_list{date_id,1});
    body_parts_displacement_list{date_id,1} = zeros(frame_num, body_parts_num);
end

%原点からの変位の大きさを求めてbody_parts_displacement_listに代入していく.
origin_coordinate = [0 0 0];
for date_id = 1:date_num
    ref_date_coordinate_values = coordinate_list{date_id};
    for body_parts_id =1:body_parts_num
        ref_col_index = 3 * (body_parts_id - 1) + 1;
        ref_parts_coordinate_list = ref_date_coordinate_values(:, (ref_col_index) : (ref_col_index+2));
        frame_num = size(ref_parts_coordinate_list, 1);
        for frame_id = 1:frame_num
            ref_coordinate = ref_parts_coordinate_list(frame_id, :);

            % NaN値があった場合の処理
            if any(isnan(ref_coordinate))
                body_parts_displacement_list{date_id,1}(frame_id,body_parts_id) = NaN;
                continue;
            end

            displacement_value = norm(ref_coordinate); %変位(ユークリッドノルム)
            body_parts_displacement_list{date_id,1}(frame_id,body_parts_id) = displacement_value;
        end
    end
end

%% 得られたノルムをプロットしていく
h = figure;
set(h,'Position',[0 0 1920 1080]) %figureの大きさ設定
% TT surgeryよりも前の日付かどうかのflag
pre_flags = cellfun(@str2double, date_list) < str2double(TT_surgery_day);

% 刺激に対する日毎の変位の大きさをplotしていく
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

        % 図の装飾
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

%% 図とデータの保存

%保存するpathの設定
save_figure_folder_path = fullfile(save_folder_path, monkey_name, 'figure', 'coordination_plot', stim_location, date_combination_folder_name);
save_data_folder_path = fullfile(save_folder_path, monkey_name, 'data', 'coordination_plot', stim_location, date_combination_folder_name);

% 保存するファイル名の設定
save_figure_file_name = 'body_parts_dispclacement';
save_data_file_name = 'body_parts_dispclacement_list';

% 保存
saveas(gcf, fullfile(save_figure_folder_path, [save_figure_file_name '.fig']))
saveas(gcf, fullfile(save_figure_folder_path, [save_figure_file_name '.png']))
save(fullfile(save_data_folder_path, [save_data_file_name '.mat']), 'body_parts_displacement_list', 'body_parts_name');

disp(['画像は次のフォルダに保存されました: ' save_figure_folder_path]);
disp(['データは次のフォルダに保存されました: ' save_data_folder_path]);

disp('適切に処理が完了しました')
close all;