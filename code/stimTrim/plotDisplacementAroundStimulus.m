function [] = plotDisplacementAroundStimulus(ref_body_parts_data, date_list, x, cmap, ref_body_parts_name, stimulated_muscle)
for date_id = 1:length(date_list)
    ref_date = date_list{date_id};
    plot(x, ref_body_parts_data(date_id, :), 'color', cmap(date_id, :), DisplayName=ref_date, LineWidth=1.2)
end
% decoration
grid on;
h_axes = gca;
h_axes.XAxis.FontSize = 12;
h_axes.YAxis.FontSize = 12;

if exist("stimulated_muscle", "var")
    title([ref_body_parts_name ' displacement(' stimulated_muscle ' stimulated)'], FontSize=15);
else
    title([ref_body_parts_name ' displacement'], FontSize=15);
end
xline(0, Color='red', LineWidth=1.2, HandleVisibility='off')
end
