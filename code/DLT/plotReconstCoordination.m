function plotReconstCoordination(worldPos,save_folder_path, coorination_name_list)
h = figure();
h.WindowState = 'maximized';

[frame_num, plot_coordinate_num] = size(worldPos);
body_parts_num = plot_coordinate_num / 3;

for plot_id = 1 : plot_coordinate_num
    subplot(body_parts_num, 3, plot_id)
    xlim([1 frame_num])
    grid on
    hold on
    axis_title = strrep(coorination_name_list{plot_id}, '_', '-');
    plot(1:frame_num, worldPos(1 : frame_num, plot_id), 'b', 'LineWidth', 1.2);
    title(axis_title, 'FontSize', 14, 'FontWeight', 'bold');
end

% セーブ設定
figure_name = 'reconst_3d_coordination';
makefold(save_folder_path);
saveas(gcf, fullfile(save_folder_path, [figure_name '.png']));
saveas(gcf, fullfile(save_folder_path, [figure_name '.fig']));
disp(['figureは次のディレクトリにセーブされました:' save_folder_path])
close all;
end